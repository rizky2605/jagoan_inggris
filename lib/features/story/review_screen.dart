import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk Haptic Feedback
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart'; 
import '../../models/user_model.dart';
import '../../models/question_model.dart';
import '../../core/services/firestore_service.dart';

class ReviewScreen extends StatefulWidget {
  final UserModel user;
  final List<QuestionModel> questions;
  
  const ReviewScreen({
    super.key,
    required this.user,
    required this.questions,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  int _currentIndex = 0;
  final Map<int, List<int>> _performanceTracker = {};
  
  bool _isAnswered = false;
  String? _selectedAnswer;

  void _answerQuestion(String answer) {
    if (_isAnswered) return;

    HapticFeedback.lightImpact(); // Getaran saat memilih

    final currentQuestion = widget.questions[_currentIndex];
    String correctAnswerText = currentQuestion.options[currentQuestion.correctIndex];
    bool correct = answer == correctAnswerText;
    int levelId = currentQuestion.levelId; 

    setState(() {
      _isAnswered = true;
      _selectedAnswer = answer;
    });

    // Tracking Logic
    if (!_performanceTracker.containsKey(levelId)) {
      _performanceTracker[levelId] = [0, 0]; 
    }
    _performanceTracker[levelId]![1]++; 
    if (correct) {
      _performanceTracker[levelId]![0]++; 
    }

    // Delay & Transisi
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        if (_currentIndex < widget.questions.length - 1) {
          setState(() {
            _currentIndex++;
            _isAnswered = false;
            _selectedAnswer = null;
          });
        } else {
          _finishReviewSession();
        }
      }
    });
  }

  Future<void> _finishReviewSession() async {
    // Hitung Akurasi
    Map<int, double> levelAccuracies = {};
    int totalCorrectAll = 0;
    
    _performanceTracker.forEach((lvlId, stats) {
      int correct = stats[0];
      int total = stats[1];
      totalCorrectAll += correct;
      if (total > 0) levelAccuracies[lvlId] = correct / total;
    });

    // Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
    );

    // Update DB
    await _firestoreService.batchUpdateLevelProgress(widget.user.uid, levelAccuracies, widget.user);
    
    double sessionAccuracy = widget.questions.isNotEmpty 
        ? totalCorrectAll / widget.questions.length 
        : 0.0;
        
    await _firestoreService.updateDailyStats(
      uid: widget.user.uid,
      quizScore: (sessionAccuracy * 100).toInt(),
    );

    if (mounted) {
      Navigator.pop(context); // Tutup loading
      _showSummaryDialog(sessionAccuracy);
    }
  }

  void _showSummaryDialog(double accuracy) {
    String title, message, lottieAsset;
    Color color;

    if (accuracy >= 0.85) {
      title = "FANTASTIC!";
      message = "Ingatanmu sangat tajam! Level ini aman untuk sementara waktu.";
      color = Colors.greenAccent;
      lottieAsset = 'assets/effects/fireworks.json'; 
    } else if (accuracy >= 0.5) {
      title = "GOOD JOB!";
      message = "Cukup baik. Kami akan jadwalkan review ulang segera.";
      color = Colors.amber;
      lottieAsset = 'assets/effects/fire.json';
    } else {
      title = "KEEP GOING!";
      message = "Masih banyak yang lupa. Besok kita hajar lagi!";
      color = Colors.redAccent;
      lottieAsset = 'assets/effects/lightning.json'; 
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2C).withOpacity(0.95),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: color, width: 2),
            boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 30)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                lottieAsset, 
                height: 120, 
                repeat: false,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.star, size: 80, color: color);
                },
              ),
              Text(title, style: GoogleFonts.blackOpsOne(color: color, fontSize: 28)),
              const SizedBox(height: 10),
              Text("${(accuracy * 100).toInt()}%", style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
              const Text("AKURASI", style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 2)),
              const SizedBox(height: 15),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color, 
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                  ),
                  onPressed: () {
                    Navigator.pop(context); 
                    Navigator.pop(context);
                  },
                  child: const Text("SELESAI", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) return const Scaffold(body: Center(child: Text("Error: No Questions")));

    final question = widget.questions[_currentIndex];
    String correctAnswerText = question.options[question.correctIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF0F0025),
      body: Container(
        // [FIX] Background star dihapus, hanya warna solid
        decoration: const BoxDecoration(
          color: Color(0xFF0F0025), 
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - 50),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    // --- HEADER (Progress & Level) ---
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Container(
                            height: 10,
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: (_currentIndex + 1) / widget.questions.length,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.cyanAccent,
                                  borderRadius: BorderRadius.circular(5),
                                  boxShadow: const [BoxShadow(color: Colors.cyanAccent, blurRadius: 10)],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.purpleAccent.withOpacity(0.5)),
                          ),
                          child: Text(
                            "LVL ${question.levelId}", 
                            style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 12)
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // --- KARTU SOAL (GLASSMORPHISM) ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05), // Glass effect
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            "REVIEW CHALLENGE",
                            style: GoogleFonts.orbitron(color: Colors.cyanAccent.withOpacity(0.7), fontSize: 12, letterSpacing: 2),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            question.question,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600, height: 1.4),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // --- PILIHAN JAWABAN ---
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: question.options.length,
                      itemBuilder: (context, index) {
                        final option = question.options[index];
                        final isCorrect = option == correctAnswerText;
                        final isSelected = option == _selectedAnswer;

                        // Tentukan Warna Button
                        Color bgColor = Colors.white.withOpacity(0.05);
                        Color borderColor = Colors.white.withOpacity(0.1);
                        Color textColor = Colors.white;
                        IconData? icon;

                        if (_isAnswered) {
                          if (isCorrect) {
                            bgColor = Colors.green.withOpacity(0.2);
                            borderColor = Colors.greenAccent;
                            textColor = Colors.greenAccent;
                            icon = Icons.check_circle;
                          } else if (isSelected) {
                            bgColor = Colors.red.withOpacity(0.2);
                            borderColor = Colors.redAccent;
                            textColor = Colors.redAccent;
                            icon = Icons.cancel;
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: GestureDetector(
                            onTap: () => _answerQuestion(option),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: borderColor, width: isSelected || (_isAnswered && isCorrect) ? 2 : 1),
                                boxShadow: (_isAnswered && (isCorrect || isSelected)) 
                                    ? [BoxShadow(color: borderColor.withOpacity(0.3), blurRadius: 15)] 
                                    : [],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 30, height: 30,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                    child: Text(
                                      ["A", "B", "C", "D"][index],
                                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: GoogleFonts.poppins(color: textColor, fontSize: 16, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  if (icon != null) Icon(icon, color: borderColor),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}