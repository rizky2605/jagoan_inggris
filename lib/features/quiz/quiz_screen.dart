import 'dart:async'; // Untuk Timer
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../models/question_model.dart';
import '../../models/level_model.dart';
import '../../models/user_model.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  final LevelModel level;
  final UserModel user;
  final List<QuestionModel>? customQuestions;
  final String? opponentName; // Nama lawan (opsional)

  const QuizScreen({
    super.key, 
    required this.level, 
    required this.user,
    this.customQuestions,
    this.opponentName,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  // Game State
  int _currentIndex = 0;
  double _monsterHealth = 1.0;
  double _playerHealth = 1.0; // HP Pemain (Baru)
  int _score = 0;
  bool _isAnswered = false;
  
  // Timer Logic
  Timer? _questionTimer;
  int _timeLeft = 10; // 10 detik per soal
  final int _maxTime = 10;

  // Countdown Awal (3..2..1)
  int _startCountdown = 3;
  bool _isGameStarted = false;

  late List<QuestionModel> _questions;

  @override
  void initState() {
    super.initState();
    _questions = widget.customQuestions ?? level1Questions;
    
    // Mulai hitung mundur sebelum game
    _startPreGameCountdown();
  }

  void _startPreGameCountdown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_startCountdown > 0) {
        setState(() => _startCountdown--);
      } else {
        timer.cancel();
        setState(() {
          _isGameStarted = true; // Game dimulai!
        });
        _startQuestionTimer(); // Mulai timer soal pertama
      }
    });
  }

  void _startQuestionTimer() {
    _timeLeft = _maxTime;
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        // Waktu habis = Salah
        _answerQuestion(-1); 
      }
    });
  }

  @override
  void dispose() {
    _questionTimer?.cancel();
    super.dispose();
  }

  void _answerQuestion(int selectedIndex) {
    if (_isAnswered) {
      return;
    }
    _questionTimer?.cancel(); // Stop waktu

    setState(() {
      _isAnswered = true;
    });

    QuestionModel currentQ = _questions[_currentIndex];
    bool isCorrect = selectedIndex == currentQ.correctIndex;

    if (isCorrect) {
      // --- LOGIKA SKOR BERBASIS KECEPATAN ---
      // Base score 10, bonus sisa waktu * 2
      int speedBonus = _timeLeft * 2;
      int damage = 15; // Damage dasar

      // Cek Buff
      if (currentQ.buffType == 'damage') {
        damage *= 2; // Critical Hit!
        _showBuffEffect("DAMAGE UP! CRITICAL HIT!");
      } else if (currentQ.buffType == 'heal') {
        _playerHealth = (_playerHealth + 0.2).clamp(0.0, 1.0);
        _showBuffEffect("HEALING ACTIVATED!");
      } else if (currentQ.buffType == 'defense') {
        _showBuffEffect("SHIELD UP!");
      }

      setState(() {
        _score += (10 + speedBonus);
        _monsterHealth -= (damage / 100); // Kurangi HP monster
        if (_monsterHealth < 0) {
          _monsterHealth = 0;
        }
      });
    } else {
      // Jika salah, kita kena damage
      setState(() {
        _playerHealth -= 0.15;
        if (_playerHealth < 0) {
          _playerHealth = 0;
        }
      });
    }

    // Pindah Soal
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (_currentIndex < _questions.length - 1 && _playerHealth > 0) {
        setState(() {
          _currentIndex++;
          _isAnswered = false;
        });
        _startQuestionTimer(); // Reset timer untuk soal berikutnya
      } else {
        _showVictoryDialog();
      }
    });
  }

  void _showBuffEffect(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.amber,
        duration: const Duration(milliseconds: 800),
      )
    );
  }

  void _showVictoryDialog() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          score: _score,
          totalQuestions: _questions.length,
          levelId: widget.level.id,
          user: widget.user,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isGameStarted) {
      return _buildCountdownOverlay();
    } // Tampilkan hitung mundur dulu

    QuestionModel currentQ = _questions[_currentIndex];
    final pinkNeon = const Color(0xFFFF66C4);
    final cyanNeon = Colors.cyanAccent;

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(image: AssetImage("assets/images/bg_stars.jpg"), fit: BoxFit.cover),
              color: Color(0xFF0F0025),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // HEADER (TIMER & BUFF INFO)
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTimerBadge(),
                      if (currentQ.buffType != 'none')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(20)),
                          child: Text("BONUS: ${currentQ.buffType.toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                    ],
                  ),
                ),

                // ARENA
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // KIRI: PLAYER
                      Expanded(
                        flex: 2,
                        child: _buildCharacterStats(widget.user.username, _playerHealth, 'assets/models/avatar_default.glb', cyanNeon),
                      ),

                      // TENGAH: SOAL
                      Expanded(
                        flex: 4,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: pinkNeon),
                                boxShadow: [BoxShadow(color: pinkNeon.withValues(alpha: 0.3), blurRadius: 20)],
                              ),
                              child: Text(
                                currentQ.question,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Pilihan Jawaban
                            ...List.generate(currentQ.options.length, (index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: _buildAnswerButton(currentQ.options[index], index, currentQ.correctIndex),
                              );
                            }),
                          ],
                        ),
                      ),

                      // KANAN: LAWAN (OPPONENT)
                      Expanded(
                        flex: 2,
                        child: _buildCharacterStats(
                          widget.opponentName ?? "MONSTER", 
                          _monsterHealth, 
                          widget.opponentName != null ? 'assets/models/avatar_default.glb' : 'assets/models/monster.glb', // Avatar beda kalau pvp
                          Colors.redAccent
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
    );
  }

  Widget _buildCountdownOverlay() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("BERSIP!", style: TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 5)),
            const SizedBox(height: 20),
            Text(
              "$_startCountdown",
              style: const TextStyle(color: Colors.cyanAccent, fontSize: 100, fontWeight: FontWeight.bold),
            ),
            if (widget.opponentName != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text("VS ${widget.opponentName}", style: const TextStyle(color: Colors.redAccent, fontSize: 18)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerBadge() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _timeLeft < 4 ? Colors.red : Colors.blueAccent,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: (_timeLeft < 4 ? Colors.red : Colors.blue).withValues(alpha: 0.5), blurRadius: 10)],
      ),
      child: Text("$_timeLeft", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildCharacterStats(String name, double hp, String model, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // HP Bar
        Container(
          width: 80, height: 8,
          margin: const EdgeInsets.only(bottom: 5),
          child: LinearProgressIndicator(value: hp, color: color, backgroundColor: Colors.grey[800]),
        ),
        Text(name, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        
        // Model
        SizedBox(
          height: 150,
          child: ModelViewer(src: model, autoRotate: false, cameraControls: false, backgroundColor: Colors.transparent),
        ),
      ],
    );
  }

  Widget _buildAnswerButton(String text, int index, int correctIndex) {
    Color borderColor = Colors.white24;
    Color bgColor = Colors.black54;

    if (_isAnswered) {
      if (index == correctIndex) {
        borderColor = Colors.green; bgColor = Colors.green.withValues(alpha: 0.3);
      } else {
        borderColor = Colors.red; bgColor = Colors.red.withValues(alpha: 0.3);
      }
    }

    return GestureDetector(
      onTap: () => _answerQuestion(index),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}