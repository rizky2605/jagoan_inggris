import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../models/question_model.dart';
import '../../core/services/firestore_service.dart';

class ReviewScreen extends StatefulWidget {
  final UserModel user;
  final List<QuestionModel> questions;
  final String levelId;

  const ReviewScreen({
    super.key,
    required this.user,
    required this.questions,
    required this.levelId,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  int _currentIndex = 0;
  int _score = 0;
  bool _isAnswered = false;
  String? _selectedAnswer;

  void _answerQuestion(String answer) {
    if (_isAnswered) return;

    final currentQuestion = widget.questions[_currentIndex];
    String correctAnswerText = currentQuestion.options[currentQuestion.correctIndex];
    bool correct = answer == correctAnswerText;

    setState(() {
      _isAnswered = true;
      _selectedAnswer = answer;
      if (correct) _score++;
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        if (_currentIndex < widget.questions.length - 1) {
          setState(() {
            _currentIndex++;
            _isAnswered = false;
            _selectedAnswer = null;
          });
        } else {
          _showSRSFeedbackDialog(); 
        }
      }
    });
  }

  void _showSRSFeedbackDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Icon(Icons.psychology, color: Colors.cyanAccent, size: 40),
            const SizedBox(height: 10),
            Text(
              "Review Selesai!",
              style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          "Skor: $_score/${widget.questions.length}\n\nSeberapa ingat kamu dengan materi ini?",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          _srsButton("Lupa (1 Hari)", Colors.redAccent, 1),
          _srsButton("Ingat Dikit (3 Hari)", Colors.amber, 2),
          _srsButton("Mudah (7 Hari)", Colors.greenAccent, 3),
        ],
        actionsAlignment: MainAxisAlignment.spaceEvenly,
      ),
    );
  }

  Widget _srsButton(String label, Color color, int rating) {
    return TextButton(
      onPressed: () async {
        int currentInterval = 1;
        if (widget.user.levelsProgress.containsKey(widget.levelId)) {
          currentInterval = widget.user.levelsProgress[widget.levelId]['interval'] ?? 1;
        }

        await _firestoreService.submitLevelReview(
          widget.user.uid, 
          widget.levelId, 
          rating, 
          currentInterval
        );

        await _firestoreService.updateDailyStats(
          uid: widget.user.uid, 
          quizScore: widget.questions.isNotEmpty 
              ? ((_score / widget.questions.length) * 100).toInt() 
              : 0
        );

        if (mounted) {
          Navigator.pop(context);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Review tercatat!"), backgroundColor: Colors.green),
          );
        }
      },
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF1E1E2C),
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: Text("Tidak ada soal untuk direview.", style: TextStyle(color: Colors.white))),
      );
    }

    final question = widget.questions[_currentIndex];
    String correctAnswerText = question.options[question.correctIndex];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0025), Color(0xFF2A0045)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- APP BAR CUSTOM ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          "Review Mode",
                          style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ),
                    // Counter di pojok kanan
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                      child: Text("${_currentIndex + 1}/${widget.questions.length}", style: const TextStyle(color: Colors.white70)),
                    ),
                  ],
                ),
              ),

              // --- KONTEN UTAMA (FLEXIBLE) ---
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Skor Info Kecil
                      Align(
                        alignment: Alignment.center,
                        child: Text("Skor Saat Ini: $_score", style: TextStyle(color: Colors.cyanAccent.withOpacity(0.7))),
                      ),
                      
                      const SizedBox(height: 15),

                      // --- KARTU SOAL (FLEXIBLE - BIAR GAK MAKAN TEMPAT) ---
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                        ),
                        child: Text(
                          question.question,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ),
                      
                      const SizedBox(height: 20),

                      // --- PILIHAN JAWABAN (EXPANDED) ---
                      Expanded(
                        child: ListView.builder(
                          // Agar listview tidak memakan space berlebih jika sedikit item
                          shrinkWrap: true, 
                          itemCount: question.options.length,
                          itemBuilder: (context, index) {
                            final option = question.options[index];
                            
                            Color btnColor = Colors.white.withOpacity(0.1);
                            Color borderColor = Colors.transparent;
                            
                            if (_isAnswered) {
                              if (option == correctAnswerText) {
                                btnColor = Colors.green.withOpacity(0.2); 
                                borderColor = Colors.greenAccent;
                              } else if (option == _selectedAnswer) {
                                btnColor = Colors.red.withOpacity(0.2); 
                                borderColor = Colors.redAccent;
                              } else {
                                btnColor = Colors.white.withOpacity(0.05);
                              }
                            } 

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
                                onTap: () => _answerQuestion(option),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: btnColor,
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32, height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.black26,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white12),
                                        ),
                                        child: Center(
                                          child: Text(
                                            ["A","B","C","D"][index], 
                                            style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)
                                          )
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: Text(
                                          option, 
                                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 15)
                                        )
                                      ),
                                      if (_isAnswered && option == correctAnswerText)
                                         const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                                      if (_isAnswered && option == _selectedAnswer && option != correctAnswerText)
                                         const Icon(Icons.cancel, color: Colors.redAccent, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}