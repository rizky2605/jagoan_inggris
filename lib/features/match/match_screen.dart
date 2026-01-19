import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../models/match_model.dart';
import '../../models/user_model.dart';
import '../../core/services/firestore_service.dart';
import 'match_service.dart';
import 'leaderboard_screen.dart'; 
import 'history_screen.dart';     

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> with TickerProviderStateMixin {
  late AnimationController _radarController;
  late AnimationController _shakeController;
  late AnimationController _feedbackController;
  late Animation<double> _feedbackScale;

  final MatchService _matchService = MatchService();
  final FirestoreService _firestoreService = FirestoreService();
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  // --- STATE ---
  String? _activeMatchId;
  bool _isSearching = false;
  Map<String, dynamic>? _foundOpponentData;
  int _startCount = 3;
  StreamSubscription? _matchSubscription;

  // --- GAME STATE ---
  int _timeLeft = 10;
  Timer? _gameTimer;
  Timer? _heartbeatTimer;
  bool _hasAnswered = false;
  
  // Feedback Visual
  bool _showFeedback = false;
  String _feedbackText = "";
  Color _feedbackColor = Colors.white;
  bool _isHostProcessing = false;

  int _startTime = 0;
  int _lastProcessedRound = 0; 

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _feedbackController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _feedbackScale = CurvedAnimation(parent: _feedbackController, curve: Curves.elasticOut);

    // [FIX] SINKRONISASI STATS SAAT MASUK LOBBY
    // Jalankan di background agar UI tidak macet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _matchService.syncUserStats(uid);
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
    _shakeController.dispose();
    _feedbackController.dispose();
    _gameTimer?.cancel();
    _heartbeatTimer?.cancel();
    _matchSubscription?.cancel();
    if (_isSearching && _activeMatchId == null) {
      _matchService.cancelSearch(uid);
    }
    super.dispose();
  }

  void _cleanupMatch() {
    if (mounted) {
      setState(() {
        _activeMatchId = null;
        _foundOpponentData = null;
        _isSearching = false;
        _lastProcessedRound = 0;
        _startCount = 3;
        _hasAnswered = false;
        _showFeedback = false;
        _isHostProcessing = false;
        _timeLeft = 10;
      });
      // [FIX] Sinkronisasi ulang stats setelah match selesai
      _matchService.syncUserStats(uid);
    }
    _gameTimer?.cancel();
    _heartbeatTimer?.cancel();
    _matchSubscription?.cancel(); 
  }

  // ===========================================================================
  // LOGIKA MATCHMAKING
  // ===========================================================================

  void _startMatchmaking() async {
    _cleanupMatch();
    setState(() => _isSearching = true);
    _radarController.repeat();
    
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || !_isSearching || _foundOpponentData != null) {
        timer.cancel();
        return;
      }
      _matchService.updateHeartbeat(uid);
    });

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!userDoc.exists) throw Exception("User missing");
      UserModel user = UserModel.fromMap(userDoc.data() as Map<String, dynamic>, uid);
      
      String result = await _matchService.findMatch(user);

      if (!mounted || !_isSearching) return; 

      if (result == "WAITING") {
        _listenForQueueMatch(uid);
      } else if (result.isNotEmpty) {
        _handleMatchFound(result, user.uid);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal mencari."), backgroundColor: Colors.red));
      }
    } catch (e) {
      debugPrint("UI Error: $e");
    }
  }

  void _listenForQueueMatch(String myUid) {
    _matchSubscription?.cancel();
    _matchSubscription = FirebaseFirestore.instance.collection('matches')
        .where('player1Uid', isEqualTo: myUid).where('status', isEqualTo: 'playing')
        .snapshots().listen((snapshot) {
      if (snapshot.docs.isNotEmpty && mounted && _isSearching && _activeMatchId == null) {
        _matchSubscription?.cancel();
        _handleMatchFound(snapshot.docs.first.id, myUid);
      }
    });
  }

  void _handleMatchFound(String matchId, String myUid) async {
    _radarController.stop();
    _heartbeatTimer?.cancel();
    HapticFeedback.vibrate();

    var matchDoc = await FirebaseFirestore.instance.collection('matches').doc(matchId).get();
    if (!matchDoc.exists) return;
    var matchData = MatchModel.fromMap(matchDoc.data()!);
    bool isP1 = matchData.player1Uid == myUid;

    if (mounted) {
      setState(() {
        _foundOpponentData = {
          'name': isP1 ? matchData.player2Name : matchData.player1Name,
          'photoUrl': isP1 ? matchData.p2PhotoUrl : matchData.p1PhotoUrl,
          'avatarPath': isP1 ? matchData.p2Avatar : matchData.p1Avatar,
        };
      });
      
      _shakeController.forward(from: 0);

      for (int i = 3; i >= 1; i--) {
        if (!mounted || !_isSearching) return; 
        setState(() => _startCount = i);
        HapticFeedback.lightImpact();
        await Future.delayed(const Duration(seconds: 1));
      }
      if (mounted && _isSearching) {
        setState(() { _isSearching = false; _activeMatchId = matchId; });
      }
    }
  }

  // ===========================================================================
  // GAMEPLAY LOGIC & FEEDBACK
  // ===========================================================================

  void _calculateLocalFeedback(MatchModel match, bool amIP1) {
    if (match.currentQuestion == null) return;
    
    String correctAnswer = match.currentQuestion!['correctAnswer'];
    String? myAns = amIP1 ? match.p1Answer : match.p2Answer;
    String? oppAns = amIP1 ? match.p2Answer : match.p1Answer;
    
    int tMy = (amIP1 ? match.p1Time : match.p2Time) ?? 99999999;
    int tOpp = (amIP1 ? match.p2Time : match.p1Time) ?? 99999999;

    String text = "";
    Color color = Colors.white;

    bool iCorrect = myAns == correctAnswer;
    bool oppCorrect = oppAns == correctAnswer;

    if (!iCorrect) {
      text = "JAWABAN SALAH!";
      color = Colors.redAccent;
    } else if (!oppCorrect) {
      text = "MUSUH SALAH!\nKAMU MENANG!";
      color = Colors.greenAccent;
    } else {
      if (tMy < tOpp) {
        text = "KAMU LEBIH CEPAT!";
        color = Colors.cyanAccent;
      } else if (tMy > tOpp) {
        text = "MUSUH LEBIH CEPAT!";
        color = Colors.orangeAccent;
      } else {
        text = "SERI!";
        color = Colors.white;
      }
    }

    setState(() {
      _feedbackText = text;
      _feedbackColor = color;
      _showFeedback = true;
    });
    _feedbackController.forward(from: 0.0);
    HapticFeedback.mediumImpact();
  }

  // ===========================================================================
  // BUILD METHOD (MAIN SWITCHER)
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    if (_activeMatchId != null) return _buildActiveMatchUI();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg_stars.jpg'), 
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF050010).withOpacity(0.8), const Color(0xFF1A0038).withOpacity(0.9)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter
            )
          ),
          child: StreamBuilder<UserModel>(
            stream: _firestoreService.getUserStream(uid),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              UserModel myUser = snapshot.data!;

              String myAvatarPath = 'assets/models/avatar_default.glb';
              if (myUser.equippedLoadout['body'] == 'monster') myAvatarPath = 'assets/models/monster.glb';
              if (myUser.equippedLoadout['body'] == 'teacher') myAvatarPath = 'assets/models/teacher.glb';

              return AnimatedBuilder(
                animation: _shakeController,
                builder: (context, child) {
                  final double offset = sin(_shakeController.value * pi * 10.0) * 5.0;
                  return Transform.translate(offset: Offset(offset, 0), child: child);
                },
                child: SafeArea(
                  child: Column(
                    children: [
                      _buildLobbyHeader(myUser),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: _buildLobbyAvatarCard(
                              "KAMU", 
                              myUser.username, 
                              myAvatarPath, 
                              myUser.photoUrl,
                              isPlayer: true
                            )
                          ),
                          _buildLobbyCenterStatus(),
                          Expanded(
                            child: _buildLobbyAvatarCard(
                              "LAWAN", 
                              _foundOpponentData?['name'] ?? "???", 
                              _foundOpponentData?['avatarPath'] ?? 'assets/models/avatar_default.glb', 
                              _foundOpponentData?['photoUrl'] ?? '', 
                              isPlayer: false,
                              isFound: _foundOpponentData != null
                            )
                          ),
                        ],
                      ),
                      const Spacer(),
                      _buildBottomNavBar(context),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // WIDGETS LOBBY
  // ===========================================================================

  Widget _buildLobbyHeader(UserModel user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("RANK MMR", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
                  Text("${user.mmr}", style: GoogleFonts.orbitron(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          Container(height: 30, width: 1, color: Colors.white10),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("BATTLE STATS", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
                  Text("${user.winCount}W - ${user.lossCount}L", style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 14)),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.bar_chart, color: Colors.cyanAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLobbyAvatarCard(String label, String name, String avatar3d, String photoUrl, {bool isPlayer = false, bool isFound = true}) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.orbitron(color: isPlayer ? Colors.cyanAccent : (isFound ? Colors.redAccent : Colors.grey), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 10),
        Container(
          height: 240, 
          width: 160,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPlayer ? Colors.cyanAccent.withOpacity(0.5) : (isFound ? Colors.redAccent.withOpacity(0.5) : Colors.white10),
              width: 2
            ),
            boxShadow: [
              if (isPlayer || isFound) 
                BoxShadow(color: (isPlayer ? Colors.cyanAccent : Colors.redAccent).withOpacity(0.2), blurRadius: 20)
            ]
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              if (isPlayer || isFound)
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: ModelViewer(
                    src: avatar3d,
                    autoRotate: isPlayer, 
                    cameraControls: false,
                    backgroundColor: Colors.transparent,
                    disableZoom: true,
                  ),
                )
              else
                Center(child: Icon(Icons.person_off_rounded, size: 50, color: Colors.white.withOpacity(0.1))),

              if (isPlayer || isFound)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18)),
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1)))
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.grey,
                        backgroundImage: (photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                        child: (photoUrl.isEmpty) ? const Icon(Icons.person, size: 14, color: Colors.white) : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name, 
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLobbyCenterStatus() {
    if (_foundOpponentData != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("VS", style: GoogleFonts.blackOpsOne(fontSize: 40, color: Colors.white, shadows: [const BoxShadow(color: Colors.red, blurRadius: 20)])),
          const SizedBox(height: 10),
          Text("$_startCount", style: GoogleFonts.orbitron(color: Colors.amber, fontSize: 30, fontWeight: FontWeight.bold)),
        ],
      );
    }
    
    if (_isSearching) {
      return RotationTransition(
        turns: _radarController,
        child: Container(
          width: 70, height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 2),
            gradient: SweepGradient(colors: [Colors.transparent, Colors.cyanAccent.withOpacity(0.8)])
          ),
          child: const Center(child: Icon(Icons.search, color: Colors.white)),
        ),
      );
    }

    return const Text("VS", style: TextStyle(color: Colors.white12, fontSize: 30, fontWeight: FontWeight.bold));
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _smallBtn(Icons.leaderboard, "RANK", () {
          HapticFeedback.lightImpact();
          Navigator.push(context, MaterialPageRoute(builder: (context) => const LeaderboardScreen()));
        }),
        const SizedBox(width: 25),
        if (!_isSearching)
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              _startMatchmaking();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.cyan, Colors.blueAccent]),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.cyan.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))]
              ),
              child: Row(
                children: [
                  const Icon(Icons.flash_on, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text("BATTLE", style: GoogleFonts.blackOpsOne(color: Colors.white, fontSize: 18, letterSpacing: 2)),
                ],
              ),
            ),
          )
        else if (_foundOpponentData == null)
          _smallBtn(Icons.close, "BATAL", () { 
            HapticFeedback.mediumImpact();
            _matchService.cancelSearch(uid); 
            _cleanupMatch(); 
          }),
        const SizedBox(width: 25),
        _smallBtn(Icons.history, "HISTORY", () {
           HapticFeedback.lightImpact();
           Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
        }),
      ]),
    );
  }

  Widget _smallBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap, 
      behavior: HitTestBehavior.opaque,
      child: Column(children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white10, shape: BoxShape.circle, border: Border.all(color: Colors.white10)), child: Icon(icon, color: Colors.white70, size: 22)), 
        const SizedBox(height: 8), 
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold))
      ])
    );
  }

  // ===========================================================================
  // UI ARENA (GAMEPLAY) - SAMA SEPERTI SEBELUMNYA
  // ===========================================================================

  Widget _buildActiveMatchUI() {
    return StreamBuilder<MatchModel>(
      stream: _matchService.getMatchStream(_activeMatchId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
        MatchModel match = snapshot.data!;
        
        bool amIP1 = match.player1Uid == uid;
        String myName = amIP1 ? match.player1Name : match.player2Name;
        int myHp = amIP1 ? match.p1Health : match.p2Health;
        String myAvatar = amIP1 ? match.p1Avatar : match.p2Avatar; 
        String oppName = amIP1 ? match.player2Name : match.player1Name;
        int oppHp = amIP1 ? match.p2Health : match.p1Health;
        String oppAvatar = amIP1 ? match.p2Avatar : match.p1Avatar;

        if (match.status == 'finished') {
          if (amIP1) _matchService.finalizeMatchStats(match);
          return _buildGameOverScreen(match, amIP1);
        }

        if (match.currentRound > _lastProcessedRound) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _lastProcessedRound = match.currentRound;
                _hasAnswered = false;
                _showFeedback = false;
                _isHostProcessing = false;
                _timeLeft = 10;
                _startTime = DateTime.now().millisecondsSinceEpoch;
              });
              _startRoundTimer();
            }
          });
        }

        if (match.p1Answer != null && match.p2Answer != null) {
          if (!_showFeedback) {
             WidgetsBinding.instance.addPostFrameCallback((_) {
               if (mounted) _calculateLocalFeedback(match, amIP1);
             });
          }
          if (amIP1 && !_isHostProcessing) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _isHostProcessing = true);
              Future.delayed(const Duration(milliseconds: 300), () {
                 if (mounted) _matchService.processRoundResult(match);
              });
            });
          }
        }

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF050010), Color(0xFF1A0038)], begin: Alignment.topCenter, end: Alignment.bottomCenter)
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      _buildBattleHeader(myName, myHp, oppName, oppHp, amIP1, match.currentRound, match.matchId),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(flex: 2, child: _build3DModel(myAvatar, autoRotate: false)),
                            Expanded(flex: 5, child: _buildQuestionArena(match, amIP1)),
                            Expanded(flex: 2, child: _build3DModel(oppAvatar, autoRotate: false)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_showFeedback)
                    Center(
                      child: ScaleTransition(
                        scale: _feedbackScale,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: _feedbackColor, width: 3),
                            boxShadow: [BoxShadow(color: _feedbackColor.withOpacity(0.6), blurRadius: 30, spreadRadius: 5)]
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_feedbackText.contains("SALAH") ? Icons.cancel : Icons.check_circle, color: _feedbackColor, size: 60),
                              const SizedBox(height: 10),
                              Text(_feedbackText, textAlign: TextAlign.center, style: GoogleFonts.blackOpsOne(color: _feedbackColor, fontSize: 24, shadows: [Shadow(color: _feedbackColor, blurRadius: 10)])),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _startRoundTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_timeLeft > 0) _timeLeft--; else timer.cancel();
      });
    });
  }

  Widget _buildBattleHeader(String myName, int myHp, String oppName, int oppHp, bool amIP1, int round, String matchId) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _statHealth(myName, myHp, Colors.cyanAccent),
          Column(
            children: [
              Text("ROUND $round", style: GoogleFonts.orbitron(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
              Text("$_timeLeft s", style: GoogleFonts.orbitron(color: _timeLeft <= 3 ? Colors.red : Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              GestureDetector(
                onTap: () => _handleSurrender(matchId, amIP1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(border: Border.all(color: Colors.redAccent.withOpacity(0.5)), borderRadius: BorderRadius.circular(5)),
                  child: const Text("SURRENDER", style: TextStyle(color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
          _statHealth(oppName, oppHp, Colors.redAccent, isRight: true),
        ],
      ),
    );
  }

  void _handleSurrender(String matchId, bool isP1) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A0038),
        title: const Text("MENYERAH?", style: TextStyle(color: Colors.white)),
        content: const Text("Kamu akan kalah otomatis.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("BATAL")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("YA", style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await FirebaseFirestore.instance.collection('matches').doc(matchId).update({
        isP1 ? 'p1Health' : 'p2Health': 0,
        'status': 'finished',
      });
    }
  }

  Widget _statHealth(String name, int hp, Color color, {bool isRight = false}) {
    return Column(
      crossAxisAlignment: isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
        const SizedBox(height: 6),
        Container(
          width: 140, height: 12,
          decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white24, width: 1)),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                width: 138 * (max(0, hp) / 100),
                height: 12,
                decoration: BoxDecoration(color: hp < 30 ? Colors.red : color, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 5)]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text("$hp/100", style: const TextStyle(color: Colors.white54, fontSize: 8)),
      ],
    );
  }

  Widget _build3DModel(String assetPath, {bool autoRotate = true}) {
    return ModelViewer(
      src: assetPath,
      autoRotate: autoRotate,
      cameraControls: false,
      backgroundColor: Colors.transparent,
      disableZoom: true,
    );
  }

  Widget _buildQuestionArena(MatchModel match, bool isP1) {
    if (_showFeedback) return Container(); 

    if (_hasAnswered) {
      return Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(40), border: Border.all(color: Colors.cyanAccent.withOpacity(0.3))),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 2)),
              const SizedBox(height: 20),
              Text("MENUNGGU LAWAN...", textAlign: TextAlign.center, style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 14, letterSpacing: 2)),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(40), border: Border.all(color: Colors.white10)),
      child: Column(
        children: [
          Expanded(child: Center(child: Text(match.currentQuestion?['question'] ?? "...", textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)))),
          const SizedBox(height: 20),
          if (match.currentQuestion != null)
            GridView.builder(
              shrinkWrap: true,
              itemCount: 4,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 15, crossAxisSpacing: 15, childAspectRatio: 2.5),
              itemBuilder: (context, index) {
                String option = match.currentQuestion!['options'][index];
                return ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    int taken = DateTime.now().millisecondsSinceEpoch - _startTime;
                    _matchService.submitAnswer(match.matchId, uid, option, taken, isP1);
                    setState(() => _hasAnswered = true);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A0038), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white10))),
                  child: Text(option, style: const TextStyle(color: Colors.white, fontSize: 12)),
                );
              },
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
        ],
      ),
    );
  }

  Widget _buildGameOverScreen(MatchModel match, bool isP1) {
    bool iWin = false;
    if (isP1 && match.p1Health > match.p2Health) iWin = true;
    if (!isP1 && match.p2Health > match.p1Health) iWin = true;
    if (match.p1Health == match.p2Health) {
      if (isP1 && match.p1Score > match.p2Score) iWin = true;
      if (!isP1 && match.p2Score > match.p1Score) iWin = true;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iWin ? Icons.emoji_events : Icons.heart_broken, size: 100, color: iWin ? Colors.amber : Colors.redAccent),
            const SizedBox(height: 20),
            Text(iWin ? "VICTORY" : "DEFEAT", style: GoogleFonts.orbitron(color: Colors.white, fontSize: 50, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Text(iWin ? "+25 MMR" : "-15 MMR", style: TextStyle(color: iWin ? Colors.green : Colors.red, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: _cleanupMatch, 
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20)),
              child: const Text("KEMBALI KE LOBBY")
            )
          ],
        ),
      ),
    );
  }
}