import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:lottie/lottie.dart'; 

import '../../models/level_model.dart';
import '../../models/user_model.dart';
import '../../models/question_model.dart';
import 'result_screen.dart'; 

class QuizScreen extends StatefulWidget {
  final LevelModel level;
  final UserModel user;
  final List<QuestionModel>? customQuestions;
  final String? opponentName; 
  final bool isReview; // TAMBAHKAN INI

  const QuizScreen({
    super.key, 
    required this.level, 
    required this.user,
    this.customQuestions,
    this.opponentName,
    this.isReview = false, // DEFAULT FALSE
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  // --- STATE GAME ---
  int _currentIndex = 0;
  double _monsterHealth = 1.0;
  double _playerHealth = 1.0;
  int _score = 0;
  bool _isAnswered = false;
  bool _showEndText = false; 
  bool _isVictory = false; 
  List<int> _wrongIndices = [];

  String _playerAnim = 'idle';
  String _monsterAnim = 'idle';
  
  late AnimationController _effectController;
  bool _showMonsterHitEffect = false; 
  bool _showPlayerHitEffect = false;  

  Timer? _gameLoopTimer;
  Timer? _countdownTimer;
  int _timeLeft = 10;
  final int _maxTime = 10;

  int _startCountdown = 3;
  bool _isGameStarted = false;

  late List<QuestionModel> _questions;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _effectController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _initializeQuestions();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _gameLoopTimer?.cancel();
    _effectController.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _initializeQuestions() {
    if (widget.customQuestions != null && widget.customQuestions!.isNotEmpty) {
      _questions = widget.customQuestions!;
    } else {
      _questions = List.from(levelQuestions[widget.level.id] ?? levelQuestions[1]!);
    }

    if (_questions.isEmpty) {
      _questions = [
        QuestionModel(question: "Siap?", options: ["YA"], correctIndex: 0, buffType: 'none')
      ];
    }
  }

  // --- LOGIKA PERMAINAN ---

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_startCountdown > 1) {
          _startCountdown--;
        } else {
          timer.cancel();
          _startGame();
        }
      });
    });
  }

  void _startGame() {
    setState(() {
      _isGameStarted = true;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _startQuestionTimer();
    });
  }

  void _startQuestionTimer() {
    _timeLeft = _maxTime;
    _gameLoopTimer?.cancel();
    _gameLoopTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _processAnswer(-1); 
        }
      });
    });
  }

  void _processAnswer(int selectedIndex) async {
    if (_isAnswered) return;
    _gameLoopTimer?.cancel();

    setState(() {
      _isAnswered = true;
    });

    QuestionModel currentQ = _questions[_currentIndex];
    bool isCorrect = selectedIndex == currentQ.correctIndex;

    if (isCorrect) {
      double damage = 0.15;
      bool isCritical = _timeLeft >= 8; 
      if (isCritical) damage = 0.30;

      int speedBonus = _timeLeft * 2;
      
      setState(() {
        _score += (10 + speedBonus);
        _playerAnim = 'attack';
      });

      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        setState(() {
          _monsterHealth -= damage;
          if (_monsterHealth < 0) _monsterHealth = 0;
          _monsterAnim = 'hit';
          _showMonsterHitEffect = true;
        });
        _effectController.reset();
        _effectController.forward();
      }
    } else {
      setState(() {
        if (!_wrongIndices.contains(_currentIndex)) {
          _wrongIndices.add(_currentIndex);
        }
        _monsterAnim = 'attack';
      });

      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        setState(() {
          _playerHealth -= 0.15;
          if (_playerHealth < 0) _playerHealth = 0;
          _playerAnim = 'hit';
          _showPlayerHitEffect = true;
        });
        _effectController.reset();
        _effectController.forward();
      }
    }

    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;

    if (_playerHealth <= 0 || _monsterHealth <= 0) {
      _finishGame();
    } 
    else {
      _goToNextQuestion();
    }
  }

  void _goToNextQuestion() {
    setState(() {
      if (_currentIndex >= _questions.length - 1) {
        if (_wrongIndices.isNotEmpty) {
          _currentIndex = _wrongIndices.first;
          _wrongIndices.removeAt(0); 
        } else {
          _currentIndex = 0;
          _questions.shuffle(); 
        }
      } else {
        _currentIndex++;
      }

      _isAnswered = false;
      _timeLeft = _maxTime;
      _playerAnim = 'idle';
      _monsterAnim = 'idle';
      _showPlayerHitEffect = false;
      _showMonsterHitEffect = false;
    });
    _startQuestionTimer();
  }

  void _finishGame() async {
    if (!mounted) return;

    setState(() {
      _showEndText = true;

      if (_monsterHealth <= 0) {
        _isVictory = true;
        _monsterAnim = 'defeat'; 
        _playerAnim = 'idle';
      } else {
        _isVictory = false;
        _playerAnim = 'defeat';
        _monsterAnim = 'idle';
      }
    });

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // LOGIKA SKOR: Jika Review atau Kalah, skor jadi 0 untuk database
    int finalScore = (widget.isReview || !_isVictory) ? 0 : _score;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          score: finalScore,
          totalQuestions: _questions.length,
          levelId: widget.level.id,
          user: widget.user,
          isVictory: _isVictory,
        ),
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text("Keluar Permainan?", style: TextStyle(color: Colors.white)),
        content: const Text("Apakah Anda yakin ingin menyerah?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Lanjut", style: TextStyle(color: Colors.cyanAccent)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Keluar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isGameStarted) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/jungle.jpg"), 
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(Colors.black87, BlendMode.darken)
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.isReview ? "MODE REVIEW" : "GET READY!", style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 20),
                Text("$_startCountdown", style: const TextStyle(color: Colors.cyanAccent, fontSize: 100, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ),
      );
    }

    QuestionModel currentQ = _questions[_currentIndex];
    final loadout = widget.user.equippedLoadout;
    String playerPath = 'assets/models/${loadout['body'] ?? 'avatar'}_${loadout['head'] ?? 'none'}_${loadout['wings'] ?? 'none'}.glb';

    bool isBossLevel = widget.level.id % 5 == 0;
    String monsterPath = isBossLevel ? 'assets/models/boss1.glb' : 'assets/models/monster1.glb';

    String playerSkillEffect = loadout['effect'] ?? 'fire'; 
    String monsterSkillEffect = 'blood'; 

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/jungle.jpg"), 
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken) 
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _timeLeft < 4 ? Colors.red : Colors.blueAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2)
                        ),
                        child: Text("$_timeLeft", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                  ),

                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _buildHpBar("YOU", _playerHealth, Colors.cyan),
                              const SizedBox(height: 10),
                              Expanded(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    ModelViewer(
                                      key: ValueKey(playerPath + _playerAnim), 
                                      src: playerPath,
                                      animationName: _playerAnim,
                                      autoPlay: true,
                                      cameraOrbit: "270deg 80deg auto", 
                                      backgroundColor: Colors.transparent,
                                      exposure: 8.0, 
                                    ),
                                    if (_showPlayerHitEffect) _buildEffect(monsterSkillEffect),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                          flex: 4,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedOpacity(
                                opacity: _showEndText ? 0.0 : 1.0,
                                duration: const Duration(milliseconds: 600),
                                child: _buildQuestionCard(currentQ),
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                          flex: 3,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _buildHpBar(isBossLevel ? "BOSS" : "MONSTER", _monsterHealth, Colors.red),
                              const SizedBox(height: 10),
                              Expanded(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    ModelViewer(
                                      key: ValueKey(monsterPath + _monsterAnim),
                                      src: monsterPath,
                                      animationName: _monsterAnim,
                                      autoPlay: true,
                                      cameraOrbit: "90deg 80deg auto", 
                                      backgroundColor: Colors.transparent,
                                      exposure: 8.0, 
                                    ),
                                    if (_showMonsterHitEffect) _buildEffect(playerSkillEffect),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: 15, left: 15,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showExitConfirmation,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),

          if (_showEndText)
            Container(
              color: Colors.black45,
              child: Center(
                child: TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 600),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Text(
                        _isVictory ? "VICTORY" : "DEFEAT",
                        style: TextStyle(
                          fontSize: 90,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: _isVictory ? Colors.yellowAccent : Colors.red,
                          shadows: const [
                            Shadow(blurRadius: 40, color: Colors.black),
                            Shadow(blurRadius: 15, color: Colors.white30),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEffect(String name) {
    return Center(
      child: Lottie.asset(
        'assets/effects/$name.json',
        controller: _effectController,
        width: 200, height: 200, fit: BoxFit.cover, repeat: false,
        errorBuilder: (context, error, stackTrace) => const SizedBox(),
      ),
    );
  }

  Widget _buildHpBar(String label, double pct, Color color) {
    return Container(
      width: 120, padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: pct, minHeight: 8, backgroundColor: Colors.white10, color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuestionModel q) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C).withOpacity(0.85),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white10, width: 2),
        boxShadow: [const BoxShadow(color: Colors.black45, blurRadius: 15, offset: Offset(0, 8))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(q.question, textAlign: TextAlign.center, 
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
            children: List.generate(q.options.length, (index) {
              return SizedBox(
                width: 150,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A2A40),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    side: BorderSide(
                      color: _isAnswered ? (index == q.correctIndex ? Colors.green : Colors.red) : Colors.white24,
                      width: 2,
                    ),
                  ),
                  onPressed: () => _processAnswer(index),
                  child: Text(q.options[index], textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
                ),
              );
            }),
          )
        ],
      ),
    );
  }
}