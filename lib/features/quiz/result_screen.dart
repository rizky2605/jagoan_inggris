import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../core/services/firestore_service.dart';

class ResultScreen extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final int levelId;
  final UserModel user;

  const ResultScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.levelId,
    required this.user,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isLoading = true;
  int _goldReward = 0;
  int _xpReward = 0;
  bool _isLevelUnlocked = false; // Status apakah level baru terbuka
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _calculateAndSaveRewards();
  }

  Future<void> _calculateAndSaveRewards() async {
    // 1. Hitung Hadiah
    _goldReward = widget.score * 20;
    _xpReward = widget.score * 50;

    // 2. Cek Kelulusan (Minimal 80% Benar)
    bool isPassed = (widget.score / widget.totalQuestions) >= 0.8;

    // 3. Cek apakah ini level baru yang diselesaikan?
    // Jika lulus DAN level yang dimainkan == level terakhir user, berarti dia membuka level baru.
    if (isPassed && widget.levelId == widget.user.lastCompletedLevel + 1) {
      _isLevelUnlocked = true;
    } 
    // Catatan: Jika user main ulang level 1 padahal sudah level 5, _isLevelUnlocked tetap false.

    // 4. Simpan ke Database
    if (isPassed && _goldReward > 0) {
      await _firestoreService.updateUserProgress(
        uid: widget.user.uid,
        goldGained: _goldReward,
        xpGained: _xpReward,
        currentLevelId: widget.levelId,
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isPassed = (widget.score / widget.totalQuestions) >= 0.8;

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/bg_stars.jpg"),
                fit: BoxFit.cover,
              ),
              color: Color(0xFF0F0025),
            ),
          ),
          
          Center(
            child: _isLoading 
            ? const CircularProgressIndicator(color: Colors.cyanAccent)
            : Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A0045).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: isPassed ? Colors.greenAccent : Colors.redAccent, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: (isPassed ? Colors.greenAccent : Colors.redAccent).withValues(alpha: 0.4), 
                      blurRadius: 30
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ikon Hasil
                    Icon(
                      isPassed ? Icons.emoji_events_rounded : Icons.cancel_outlined, 
                      size: 80, 
                      color: isPassed ? Colors.amber : Colors.red
                    ),
                    const SizedBox(height: 10),
                    
                    Text(
                      isPassed ? "MISSION COMPLETE" : "MISSION FAILED",
                      style: TextStyle(
                        fontFamily: 'Orbitron', 
                        fontSize: 22, 
                        fontWeight: FontWeight.bold, 
                        color: isPassed ? Colors.white : Colors.redAccent
                      ),
                    ),
                    
                    const SizedBox(height: 10),

                    // Score Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(15)
                      ),
                      child: Text(
                        "Skor: ${widget.score} / ${widget.totalQuestions}",
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- BAGIAN HADIAH & UNLOCK ---
                    if (isPassed) ...[
                      // Notifikasi Level Baru
                      if (_isLevelUnlocked || widget.levelId > widget.user.lastCompletedLevel)
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.cyanAccent)
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.lock_open, color: Colors.cyanAccent),
                              SizedBox(width: 8),
                              Text("LEVEL BARU TERBUKA!", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),

                      // Hadiah Gold & XP
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildRewardItem(Icons.monetization_on, "+$_goldReward", Colors.amber),
                          const SizedBox(width: 30),
                          _buildRewardItem(Icons.bolt, "+$_xpReward", Colors.purpleAccent),
                        ],
                      ),
                    ] else ...[
                      const Text(
                        "Skor minimal 80% untuk lulus.\nCoba lagi ya!",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      )
                    ],

                    const SizedBox(height: 30),

                    // TOMBOL KEMBALI / ULANG
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          // Kembali ke Dashboard (Refresh otomatis karena StreamBuilder)
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPassed ? Colors.cyanAccent : Colors.grey,
                          foregroundColor: Colors.black,
                          elevation: 10,
                        ),
                        child: Text(
                          isPassed ? "KEMBALI KE PETA" : "ULANGI MATERI", 
                          style: const TextStyle(fontWeight: FontWeight.bold)
                        ),
                      ),
                    )
                  ],
                ),
              ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardItem(IconData icon, String text, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white10,
            shape: BoxShape.circle,
            border: Border.all(color: color),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10)]
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16))
      ],
    );
  }
}