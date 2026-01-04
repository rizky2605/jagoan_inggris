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
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _calculateAndSaveRewards();
  }

  Future<void> _calculateAndSaveRewards() async {
    // LOGIKA HADIAH:
    // 1 Soal Benar = 20 Gold & 50 XP
    _goldReward = widget.score * 20;
    _xpReward = widget.score * 50;

    // Syarat Lulus: Benar minimal 80% (misal 4 dari 5 soal)
    bool isPassed = (widget.score / widget.totalQuestions) >= 0.8;

    // Hanya simpan ke database jika lulus dan ada hadiah
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
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/bg_stars.jpg"), // Pastikan gambar ini ada
                fit: BoxFit.cover,
              ),
              color: Color(0xFF0F0025),
            ),
          ),
          
          Center(
            child: _isLoading 
            ? const CircularProgressIndicator(color: Colors.cyanAccent)
            : Container(
                margin: const EdgeInsets.all(30),
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A0045).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.cyanAccent, width: 3),
                  boxShadow: [
                    BoxShadow(color: Colors.cyanAccent.withOpacity(0.5), blurRadius: 30)
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events_rounded, size: 80, color: Colors.amber),
                    const SizedBox(height: 20),
                    
                    const Text(
                      "MISSION COMPLETE",
                      style: TextStyle(
                        fontFamily: 'Orbitron', // Pastikan font ada atau hapus baris ini
                        fontSize: 24, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.white
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Score Badge
                    Text(
                      "Skor: ${widget.score} / ${widget.totalQuestions}",
                      style: const TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                    const SizedBox(height: 30),

                    // Rewards Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildRewardItem(Icons.monetization_on, "+$_goldReward Gold", Colors.amber),
                        const SizedBox(width: 20),
                        _buildRewardItem(Icons.bolt, "+$_xpReward XP", Colors.purpleAccent),
                      ],
                    ),

                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          // Kembali ke Dashboard dan refresh
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text("KEMBALI KE MARKAS", style: TextStyle(fontWeight: FontWeight.bold)),
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white10,
            shape: BoxShape.circle,
            border: Border.all(color: color),
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        const SizedBox(height: 8),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold))
      ],
    );
  }
}