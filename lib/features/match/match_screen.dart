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

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> with TickerProviderStateMixin {
  late AnimationController _radarController;
  late AnimationController _shakeController;

  final MatchService _matchService = MatchService();
  final FirestoreService _firestoreService = FirestoreService();
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  // --- STATE PERTANDINGAN ---
  String? _activeMatchId;
  bool _isSearching = false;
  Map<String, dynamic>? _foundOpponentData;
  int _startCount = 3;

  // --- STATE ARENA (REAL-TIME) ---
  int _timeLeft = 10;
  Timer? _gameTimer;
  Timer? _heartbeatTimer;
  bool _hasAnswered = false;
  int _startTime = 0;
  int _lastProcessedRound = 0; 

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _radarController.dispose();
    _shakeController.dispose();
    _gameTimer?.cancel();
    _heartbeatTimer?.cancel();
    if (_isSearching) _matchService.cancelSearch(uid);
    super.dispose();
  }

  // --- FUNGSI RESET & PEMBERSIHAN ---
  void _cleanupMatch() {
    if (mounted) {
      setState(() {
        _activeMatchId = null;
        _foundOpponentData = null;
        _isSearching = false;
        _lastProcessedRound = 0;
        _startCount = 3;
        _hasAnswered = false;
        _timeLeft = 10;
      });
      _gameTimer?.cancel();
      _heartbeatTimer?.cancel();
    }
  }

  // ===========================================================================
  // LOGIKA MATCHMAKING
  // ===========================================================================

  void _startMatchmaking() async {
    _cleanupMatch();
    setState(() => _isSearching = true);
    
    // Mulai Heartbeat agar sistem tahu kita aktif mencari
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_isSearching && _foundOpponentData == null) {
        _matchService.updateHeartbeat(uid);
      } else {
        timer.cancel();
      }
    });

    _radarController.repeat();

    var userStream = _firestoreService.getUserStream(uid);
    UserModel user = await userStream.first;
    
    String result = await _matchService.findMatch(user);

    if (result == "WAITING") {
      _listenForQueueMatch(uid);
    } else if (result.isNotEmpty) {
      _handleMatchFound(result, user.uid);
    }
  }

  void _listenForQueueMatch(String myUid) {
    FirebaseFirestore.instance
        .collection('matches')
        .where('player1Uid', isEqualTo: myUid)
        .where('status', isEqualTo: 'playing')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty && mounted && _isSearching && _activeMatchId == null) {
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
        _foundOpponentData = {'name': isP1 ? matchData.player2Name : matchData.player1Name};
      });
      
      _shakeController.forward(from: 0);

      // Countdown transisi VS
      for (int i = 3; i >= 1; i--) {
        if (!mounted) return;
        setState(() => _startCount = i);
        HapticFeedback.lightImpact();
        await Future.delayed(const Duration(seconds: 1));
      }

      if (mounted) {
        setState(() {
          _isSearching = false;
          _activeMatchId = matchId;
        });
      }
    }
  }

  // ===========================================================================
  // ARENA PERTANDINGAN (FULL SCREEN & SYNCED)
  // ===========================================================================

  Widget _buildActiveMatchUI() {
    return StreamBuilder<MatchModel>(
      stream: _matchService.getMatchStream(_activeMatchId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
        
        MatchModel match = snapshot.data!;
        bool isP1 = match.player1Uid == uid;

        // 1. DETEKSI GAME OVER (SINKRON)
        if (match.status == 'finished') {
          if (isP1) _matchService.finalizeMatchStats(match);
          return _buildGameOverScreen(match, isP1);
        }

        // 2. SINKRONISASI PERGANTIAN RONDE
        if (match.currentRound > _lastProcessedRound) {
          _lastProcessedRound = match.currentRound;
          _hasAnswered = false;
          _timeLeft = 10;
          _startTime = DateTime.now().millisecondsSinceEpoch;
          _startRoundTimer();
        }

        // 3. LOGIKA HOST: HITUNG DAMAGE JIKA KEDUANYA SUDAH MENJAWAB
        if (isP1 && match.p1Answer != null && match.p2Answer != null) {
          _matchService.processRoundResult(match);
        }

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF050010), Color(0xFF1A0038)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter
              )
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildBattleHeader(match, isP1),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: _build3DModel(true, autoRotate: false)),
                        Expanded(flex: 5, child: _buildQuestionArena(match, isP1)),
                        Expanded(flex: 2, child: Transform(alignment: Alignment.center, transform: Matrix4.rotationY(pi), child: _build3DModel(false, autoRotate: false))),
                      ],
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
        if (_timeLeft > 0) _timeLeft--;
        else timer.cancel();
      });
    });
  }

  Widget _buildBattleHeader(MatchModel match, bool isP1) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _statHealth(match.player1Name, match.p1Health, Colors.cyanAccent),
          Column(
            children: [
              Text("ROUND ${match.currentRound}", style: GoogleFonts.orbitron(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
              Text("${_timeLeft}s", style: GoogleFonts.orbitron(color: _timeLeft <= 3 ? Colors.red : Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              GestureDetector(
                onTap: () => _handleSurrender(match.matchId, isP1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(border: Border.all(color: Colors.redAccent.withOpacity(0.5)), borderRadius: BorderRadius.circular(5)),
                  child: const Text("SURRENDER", style: TextStyle(color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
          _statHealth(match.player2Name, match.p2Health, Colors.redAccent, isRight: true),
        ],
      ),
    );
  }

  void _handleSurrender(String matchId, bool isP1) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A0038),
        title: const Text("MENYERAH?"),
        content: const Text("Kamu akan kehilangan MMR dan lawan otomatis menang."),
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
          width: 140, height: 10,
          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: 140 * (max(0, hp) / 100),
            decoration: BoxDecoration(
              color: color, 
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 10)]
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionArena(MatchModel match, bool isP1) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(40), border: Border.all(color: Colors.white10)),
      child: Column(
        children: [
          Expanded(child: Center(child: Text(match.currentQuestion?['question'] ?? "...", textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)))),
          const SizedBox(height: 20),
          if (!_hasAnswered && match.currentQuestion != null)
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A0038),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white10)),
                  ),
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
    // Penentuan pemenang berdasarkan HP akhir di Firestore
    bool iWin = false;
    if (isP1 && match.p1Health > match.p2Health) iWin = true;
    if (!isP1 && match.p2Health > match.p1Health) iWin = true;
    
    // Jika Draw HP, bandingkan Score
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
            Text(iWin ? "+20 MMR" : "-10 MMR", style: TextStyle(color: iWin ? Colors.green : Colors.red)),
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

  // ===========================================================================
  // UI LOBBY
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    if (_activeMatchId != null) return _buildActiveMatchUI();

    return Scaffold(
      backgroundColor: const Color(0xFF050010),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          UserModel myUser = UserModel.fromMap(snapshot.data!.data() as Map<String, dynamic>, uid);

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF050010), Color(0xFF1A0038)], begin: Alignment.topLeft, end: Alignment.bottomRight)
            ),
            child: AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                final double offset = sin(_shakeController.value * pi * 10.0) * 5.0;
                return Transform.translate(offset: Offset(offset, 0), child: child);
              },
              child: SafeArea(
                child: Column(
                  children: [
                    _buildHUDHeader(myUser),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(flex: 3, child: _buildAvatarSlot("KAMU", true)),
                        Expanded(flex: 2, child: _buildMatchCenter()),
                        Expanded(flex: 3, child: _buildAvatarSlot(_foundOpponentData?['name'] ?? "MENCARI...", false, isFound: _foundOpponentData != null)),
                      ],
                    ),
                    const Spacer(),
                    _buildBottomNavBar(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHUDHeader(UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("ARENA", style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.w900)),
          Text("MMR: ${user.mmr}", style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildAvatarSlot(String label, bool isPlayer, {bool isFound = true}) {
    return Column(children: [
      Text(label.toUpperCase(), style: GoogleFonts.orbitron(color: isPlayer ? Colors.cyanAccent : Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      Container(
        height: 220, width: 160,
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(30), border: Border.all(color: isFound ? (isPlayer ? Colors.cyanAccent.withOpacity(0.3) : Colors.redAccent.withOpacity(0.3)) : Colors.white10)),
        child: (isPlayer || isFound) ? RepaintBoundary(child: _build3DModel(isPlayer)) : Center(child: Icon(Icons.help_outline_rounded, size: 50, color: Colors.white.withOpacity(0.05))),
      ),
    ]);
  }

  Widget _buildMatchCenter() {
    if (_foundOpponentData != null) {
      return Column(children: [
        Text("VS", style: GoogleFonts.orbitron(fontSize: 60, color: Colors.white, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
        Text("$_startCount", style: GoogleFonts.orbitron(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold)),
      ]);
    }
    if (_isSearching) {
      return RotationTransition(turns: _radarController, child: Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 2), gradient: SweepGradient(colors: [Colors.transparent, Colors.cyanAccent.withOpacity(0.6)]))));
    }
    return const SizedBox();
  }

  Widget _buildBottomNavBar() {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _smallBtn(Icons.leaderboard, "RANK", () {}),
        const SizedBox(width: 25),
        if (!_isSearching)
          GestureDetector(
            onTap: _startMatchmaking,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              decoration: BoxDecoration(color: Colors.cyanAccent, borderRadius: BorderRadius.circular(40), boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 10)]),
              child: Text("CARI LAWAN", style: GoogleFonts.orbitron(color: Colors.black, fontWeight: FontWeight.w900)),
            ),
          )
        else if (_foundOpponentData == null)
          _smallBtn(Icons.close, "BATAL", () { _matchService.cancelSearch(uid); _cleanupMatch(); }),
        const SizedBox(width: 25),
        _smallBtn(Icons.history, "HISTORY", () {}),
      ]),
    );
  }

  Widget _smallBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Column(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white10, shape: BoxShape.circle), child: Icon(icon, color: Colors.white70, size: 20)), const SizedBox(height: 5), Text(label, style: const TextStyle(color: Colors.white38, fontSize: 8))]));
  }

  Widget _build3DModel(bool isPlayer, {bool autoRotate = true}) {
    return ModelViewer(
      src: isPlayer ? 'assets/models/avatar_default.glb' : 'assets/models/monster.glb',
      autoRotate: autoRotate,
      cameraControls: false,
      backgroundColor: Colors.transparent,
      disableZoom: true,
    );
  }
}