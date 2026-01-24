import 'dart:async';
import 'dart:math';
import 'dart:ui'; // Diperlukan untuk ImageFilter (Blur effect)
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:lottie/lottie.dart'; 

import '../../models/match_model.dart';
import 'match_service.dart';

class GameScreen extends StatefulWidget {
  final String matchId;

  const GameScreen({super.key, required this.matchId});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final MatchService _matchService = MatchService();
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  late AnimationController _feedbackController;
  late Animation<double> _feedbackScale;

  // Game State
  int _timeLeft = 10;
  Timer? _gameTimer;
  int _lastProcessedRound = 0;
  int _startTime = 0;
  bool _hasAnswered = false;
  bool _isHostProcessing = false;

  // Animation State
  String _myAnim = 'idle';
  String _oppAnim = 'idle';

  // Magic Effect State
  String _myMagicType = 'fire'; 
  final String _oppMagicType = 'lightning'; 
  bool _showMyHitEffect = false; 
  bool _showOppHitEffect = false; 

  // UI State
  bool _showFeedback = false;
  String _feedbackText = "";
  Color _feedbackColor = Colors.white;

  @override
  void initState() {
    super.initState();
    // Kunci orientasi landscape agar pengalaman bermain maksimal
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _feedbackController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _feedbackScale = CurvedAnimation(parent: _feedbackController, curve: Curves.elasticOut);

    _loadUserEffect();
  }

  Future<void> _loadUserEffect() async {
    try {
      var doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        if (mounted) {
          setState(() {
            _myMagicType = doc.data()!['equippedLoadout']?['effect'] ?? 'fire';
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading effect: $e");
    }
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _feedbackController.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _quitGame() {
    Navigator.pop(context);
  }

  // --- LOGIKA PERTARUNGAN (OPTIMIZED) ---
  void _calculateRoundResult(MatchModel match, bool amIP1) {
    if (match.currentQuestion == null) return;

    // Snapshot ID ronde saat ini untuk mencegah race condition animasi
    int roundContext = match.currentRound;

    String correctAnswer = match.currentQuestion!['correctAnswer'];
    String? myAns = amIP1 ? match.p1Answer : match.p2Answer;
    String? oppAns = amIP1 ? match.p2Answer : match.p1Answer;
    
    int tMy = (amIP1 ? match.p1Time : match.p2Time) ?? 99999999;
    int tOpp = (amIP1 ? match.p2Time : match.p1Time) ?? 99999999;

    bool iCorrect = myAns == correctAnswer;
    bool oppCorrect = oppAns == correctAnswer;

    String text = "";
    Color color = Colors.white;
    bool iWin = false;
    bool bothWrong = false;

    if (!iCorrect && !oppCorrect) {
      bothWrong = true;
      text = "KEDUANYA SALAH!";
      color = Colors.grey;
    } else if (!iCorrect) {
      iWin = false; 
      text = "JAWABAN SALAH!";
      color = Colors.redAccent;
    } else if (!oppCorrect) {
      iWin = true; 
      text = "MUSUH SALAH!\nKAMU MENANG!";
      color = Colors.greenAccent;
    } else {
      if (tMy <= tOpp) {
        iWin = true;
        text = "KAMU LEBIH CEPAT!";
        color = Colors.cyanAccent;
      } else {
        iWin = false;
        text = "MUSUH LEBIH CEPAT!";
        color = Colors.orangeAccent;
      }
    }

    // 1. PHASE ATTACK (Immediate)
    setState(() {
      _feedbackText = text;
      _feedbackColor = color;
      _showFeedback = true;

      if (!bothWrong) {
        if (iWin) {
          _myAnim = 'attack'; 
        } else {
          _oppAnim = 'attack'; 
        }
      }
    });
    _feedbackController.forward(from: 0.0);

    // 2. PHASE HIT & FIRE (Delay 0.8s)
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted || _lastProcessedRound != roundContext) return;

      setState(() {
        if (bothWrong) {
          _myAnim = 'hit';
          _oppAnim = 'hit';
          _showMyHitEffect = true;
          _showOppHitEffect = true;
        } else if (iWin) {
          _oppAnim = 'hit';
          _showOppHitEffect = true; 
        } else {
          _myAnim = 'hit';
          _showMyHitEffect = true; 
        }
        HapticFeedback.mediumImpact();
      });
    });

    // 3. PHASE RESET TO IDLE (Delay 2.5s) - Mencegah looping animasi
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted || _lastProcessedRound != roundContext) return;
      
      setState(() {
        _myAnim = 'idle';
        _oppAnim = 'idle';
      });
    });

    // 4. PHASE CLEANUP UI (Delay 4s)
    Future.delayed(const Duration(milliseconds: 4000), () {
      if (!mounted || _lastProcessedRound != roundContext) return;

      setState(() {
        _showFeedback = false;
        _showMyHitEffect = false;
        _showOppHitEffect = false;
      });
    });
  }

  void _startRoundTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  // --- BUILD UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // [OPTIMASI] Hapus FloatingActionButton debug
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF050010), Color(0xFF1A0038)], begin: Alignment.topCenter, end: Alignment.bottomCenter)
        ),
        child: StreamBuilder<MatchModel>(
          stream: _matchService.getMatchStream(widget.matchId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            MatchModel match = snapshot.data!;

            bool amIP1 = match.player1Uid == uid;
            String myName = amIP1 ? match.player1Name : match.player2Name;
            int myHp = amIP1 ? match.p1Health : match.p2Health;
            String myAvatar = amIP1 ? match.p1Avatar : match.p2Avatar;
            
            String oppName = amIP1 ? match.player2Name : match.player1Name;
            int oppHp = amIP1 ? match.p2Health : match.p1Health;
            String oppAvatar = amIP1 ? match.p2Avatar : match.p1Avatar;

            // --- GAME OVER CHECK ---
            if (match.status == 'finished') {
              if (amIP1) _matchService.finalizeMatchStats(match);
              // Langsung return Game Over Screen agar 3D Model di-dispose (Hemat Memori)
              return _buildGameOverScreen(match, amIP1);
            }

            // --- ROUND CHANGE DETECTION ---
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
                    
                    // Reset Paksa
                    _myAnim = 'idle';
                    _oppAnim = 'idle';
                    _showMyHitEffect = false;
                    _showOppHitEffect = false;
                  });
                  _startRoundTimer();
                }
              });
            }

            // --- ANSWER CHECK ---
            if (match.p1Answer != null && match.p2Answer != null) {
               if (!_showFeedback) {
                 WidgetsBinding.instance.addPostFrameCallback((_) {
                   if (mounted) _calculateRoundResult(match, amIP1);
                 });
               }

               if (amIP1 && !_isHostProcessing) {
                 WidgetsBinding.instance.addPostFrameCallback((_) {
                   if (mounted) setState(() => _isHostProcessing = true);
                   Future.delayed(const Duration(milliseconds: 4000), () {
                      if (mounted) _matchService.processRoundResult(match);
                   });
                 });
               }
            }

            return SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      _buildHeader(match.currentRound, myName, myHp, oppName, oppHp, amIP1),
                      Expanded(
                        child: Row(
                          children: [
                            // === PLAYER KITA (GLOW BIRU) ===
                            Expanded(
                              flex: 2, 
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  _buildGlowBackground(Colors.cyanAccent),
                                  _build3DModel(myAvatar, _myAnim, orbit: "270deg 80deg auto"),
                                  MagicEffectOverlay(effectType: _oppMagicType, isVisible: _showMyHitEffect),
                                ],
                              )
                            ),
                            
                            // === ARENA SOAL ===
                            Expanded(flex: 5, child: _buildQuestionArena(match, amIP1)),
                            
                            // === LAWAN (GLOW MERAH) ===
                            Expanded(
                              flex: 2, 
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  _buildGlowBackground(Colors.redAccent),
                                  _build3DModel(oppAvatar, _oppAnim, orbit: "90deg 80deg auto"),
                                  MagicEffectOverlay(effectType: _myMagicType, isVisible: _showOppHitEffect),
                                ],
                              )
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_showFeedback) _buildFeedbackOverlay(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- VISUAL COMPONENTS ---

  Widget _buildGlowBackground(Color color) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.65, 
            colors: [color.withOpacity(0.35), Colors.transparent],
            stops: const [0.2, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _build3DModel(String assetPath, String animation, {required String orbit}) {
    return ModelViewer(
      key: ValueKey('$assetPath-$animation'), 
      src: assetPath,
      animationName: animation,
      autoPlay: true, 
      autoRotate: false, 
      cameraOrbit: orbit, 
      cameraControls: false, 
      backgroundColor: Colors.transparent, 
      disableZoom: true,
      shadowIntensity: 1, 
      exposure: 8, 
      // [OPTIMASI] Memastikan tidak memakan resource berlebih
    );
  }

  Widget _buildQuestionArena(MatchModel match, bool isP1) {
    if (_showFeedback) return const SizedBox(); 
    if (_hasAnswered) {
      return Container(
        margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
        child: const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
      );
    }
    return Container(
      margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white10)),
      child: Column(
        children: [
          Expanded(child: Center(child: Text(match.currentQuestion?['question'] ?? "...", textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)))),
          const SizedBox(height: 20),
          if (match.currentQuestion != null)
            GridView.builder(
              shrinkWrap: true, itemCount: 4, 
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.5),
              itemBuilder: (context, index) {
                String option = match.currentQuestion!['options'][index];
                return ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _matchService.submitAnswer(widget.matchId, uid, option, DateTime.now().millisecondsSinceEpoch - _startTime, isP1);
                    setState(() => _hasAnswered = true);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A0038), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.white10))),
                  child: Text(option, style: const TextStyle(color: Colors.white, fontSize: 12)),
                );
              },
            )
        ],
      ),
    );
  }

  Widget _buildHeader(int round, String myName, int myHp, String oppName, int oppHp, bool isP1) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _hpBar(myName, myHp, Colors.cyan),
        Column(children: [
          Text("ROUND $round", style: GoogleFonts.orbitron(color: Colors.amber)),
          Text("$_timeLeft", style: GoogleFonts.blackOpsOne(fontSize: 24, color: _timeLeft < 4 ? Colors.red : Colors.white)),
          GestureDetector(onTap: () => _handleSurrender(isP1), child: Container(margin: const EdgeInsets.only(top: 5), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2), decoration: BoxDecoration(border: Border.all(color: Colors.red)), child: const Text("SURRENDER", style: TextStyle(color: Colors.red, fontSize: 10))))
        ]),
        _hpBar(oppName, oppHp, Colors.red, isRight: true),
      ]),
    );
  }

  Widget _hpBar(String name, int hp, Color color, {bool isRight = false}) {
    return Column(crossAxisAlignment: isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
      Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
      const SizedBox(height: 5),
      Container(width: 120, height: 10, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(5)), child: Align(alignment: Alignment.centerLeft, child: AnimatedContainer(duration: const Duration(milliseconds: 300), width: 120 * (max(0, hp)/100), height: 10, decoration: BoxDecoration(color: hp < 30 ? Colors.red : color, borderRadius: BorderRadius.circular(5))))),
      Text("$hp/100", style: const TextStyle(color: Colors.white54, fontSize: 8))
    ]);
  }

  Widget _buildFeedbackOverlay() {
    return Center(child: ScaleTransition(scale: _feedbackScale, child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.black87, border: Border.all(color: _feedbackColor, width: 3), borderRadius: BorderRadius.circular(15)), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.info, color: _feedbackColor, size: 50), const SizedBox(height: 10), Text(_feedbackText, textAlign: TextAlign.center, style: GoogleFonts.blackOpsOne(color: _feedbackColor, fontSize: 20))]))));
  }

  // --- NEW: ATTRACTIVE & OPTIMIZED GAME OVER SCREEN ---
  Widget _buildGameOverScreen(MatchModel match, bool isP1) {
    // Tentukan Pemenang
    bool iWin = (isP1 && match.p1Health > match.p2Health) || (!isP1 && match.p2Health > match.p1Health);
    if (match.p1Health == match.p2Health) iWin = (isP1 && match.p1Score > match.p2Score) || (!isP1 && match.p2Score > match.p1Score);
    
    // Tentukan Warna & Teks
    Color mainColor = iWin ? Colors.amber : const Color.fromARGB(255, 255, 53, 53);
    String title = iWin ? "VICTORY" : "DEFEAT";
    String mmrText = iWin ? "+25" : "-20";
    IconData rankIcon = iWin ? Icons.keyboard_double_arrow_up : Icons.keyboard_double_arrow_down;

    return Scaffold(
      backgroundColor: const Color(0xFF050010),
      body: Stack(
        children: [
          // 1. Background Image / Gradient (Ringan)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [mainColor.withOpacity(0.2), Colors.black],
                begin: Alignment.topCenter, end: Alignment.bottomCenter
              )
            ),
          ),

          // 2. Confetti Effect (Hanya jika Menang)
          if (iWin)
            Align(
              alignment: Alignment.topCenter,
              child: Lottie.asset('assets/effects/confetti.json', repeat: true),
            ),

          // 3. Main Content dengan Blur Card
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 400,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: mainColor.withOpacity(0.5), width: 1.5)
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Judul
                      Text(title, 
                        style: GoogleFonts.blackOpsOne(
                          fontSize: 48, 
                          color: mainColor,
                          shadows: [Shadow(color: mainColor, blurRadius: 20)]
                        )
                      ),
                      const SizedBox(height: 10),
                      Text(iWin ? "Outstanding Performance!" : "Don't Give Up!", style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const Divider(color: Colors.white10, height: 40),
                      
                      // MMR & Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem("SCORE", "${isP1 ? match.p1Score : match.p2Score}"),
                          // MMR Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                            decoration: BoxDecoration(
                              color: mainColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: mainColor)
                            ),
                            child: Row(
                              children: [
                                Icon(rankIcon, color: mainColor, size: 20),
                                const SizedBox(width: 5),
                                Text("MMR $mmrText", style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                          ),
                          _buildStatItem("HEALTH", "${isP1 ? match.p1Health : match.p2Health}%"),
                        ],
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Tombol Kembali
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _quitGame, 
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mainColor,
                            foregroundColor: Colors.black,
                            elevation: 10,
                            shadowColor: mainColor.withOpacity(0.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                          ), 
                          child: const Text("RETURN TO LOBBY", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5))
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      )
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
        const SizedBox(height: 5),
        Text(value, style: GoogleFonts.orbitron(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _handleSurrender(bool isP1) {
    FirebaseFirestore.instance.collection('matches').doc(widget.matchId).update({
      isP1 ? 'p1Health' : 'p2Health': 0, 'status': 'finished'
    });
  }
}

// Widget MagicEffectOverlay tetap sama...
class MagicEffectOverlay extends StatefulWidget {
  final String effectType; 
  final bool isVisible;

  const MagicEffectOverlay({super.key, required this.effectType, required this.isVisible});

  @override
  State<MagicEffectOverlay> createState() => _MagicEffectOverlayState();
}

class _MagicEffectOverlayState extends State<MagicEffectOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
  }

  @override
  void didUpdateWidget(covariant MagicEffectOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox();
    return Center(
      child: Lottie.asset(
        'assets/effects/fire.json',
        controller: _controller,
        width: 300,
        height: 300,
        fit: BoxFit.cover,
        repeat: false,
      ),
    );
  }
}