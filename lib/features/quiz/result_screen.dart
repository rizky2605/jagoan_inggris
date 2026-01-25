import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../models/user_model.dart';
import '../../core/services/firestore_service.dart';

class ResultScreen extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final int levelId;
  final UserModel user;
  final bool isVictory; // Parameter wajib baru

  const ResultScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.levelId,
    required this.user,
    required this.isVictory, 
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isLoading = true;
  int _goldReward = 0;
  int _xpReward = 0;
  bool _isLevelUnlocked = false;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _calculateAndSaveRewards();
  }

  Future<void> _calculateAndSaveRewards() async {
    // 1. Hadiah HANYA jika Menang (isVictory)
    if (widget.isVictory) {
      _goldReward = widget.score * 20;
      _xpReward = widget.score * 50;

      // Cek apakah level selanjutnya perlu dibuka
      if (widget.levelId >= widget.user.lastCompletedLevel) {
        _isLevelUnlocked = true;
      }

      // Simpan ke Firestore
      await _firestoreService.updateUserProgress(
        uid: widget.user.uid,
        goldGained: _goldReward,
        xpGained: _xpReward,
        currentLevelId: widget.levelId,
      );
    } else {
      // Jika kalah, tidak dapat apa-apa
      _goldReward = 0;
      _xpReward = 0;
      _isLevelUnlocked = false;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.isVictory ? Colors.cyanAccent : Colors.redAccent;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0025),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              "assets/images/jungle.jpg", // Gunakan BG yang sama agar konsisten
              fit: BoxFit.cover,
            ),
          ),
          
          // Blur Overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.black.withOpacity(0.6)),
            ),
          ),

          // Fireworks jika Menang
          if (widget.isVictory && !_isLoading)
            Align(
              alignment: Alignment.topCenter,
              child: Lottie.asset(
                'assets/effects/fireworks.json',
                repeat: true,
                fit: BoxFit.contain,
              ),
            ),

          Center(
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.cyanAccent)
                : _buildResultCard(statusColor),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(Color statusColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: statusColor.withOpacity(0.5), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Text
          Text(
            widget.isVictory ? "VICTORY!" : "DEFEAT",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              color: statusColor,
              shadows: [Shadow(color: statusColor, blurRadius: 20)],
            ),
          ),
          const SizedBox(height: 20),

          // Lottie Icon (Events atau Crying/Failed)
          SizedBox(
            height: 150,
            child: Lottie.asset(
              widget.isVictory 
                ? 'assets/effects/fireworks.json' // Ganti ke trophy.json jika ada
                : 'assets/effects/blood.json', 
              repeat: widget.isVictory,
            ),
          ),

          // Score Info
          Text(
            "Final Score",
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
          ),
          Text(
            "${widget.score}",
            style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Rewards Section
          if (widget.isVictory) ...[
            const Text("REWARDS GAINED", style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildRewardTile(Icons.monetization_on, "$_goldReward", Colors.amber),
                const SizedBox(width: 20),
                _buildRewardTile(Icons.bolt, "$_xpReward", Colors.purpleAccent),
              ],
            ),
            if (_isLevelUnlocked) ...[
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.greenAccent),
                ),
                child: const Text("NEW LEVEL UNLOCKED!", style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ]
          ] else ...[
             const Text(
              "Boss masih bertahan!\nGunakan Critical Hit untuk menang.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],

          const SizedBox(height: 30),

          // Buttons
          Column(
            children: [
              _buildActionButton(
                label: widget.isVictory ? "NEXT MISSION" : "TRY AGAIN",
                color: statusColor,
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Back to Map", style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRewardTile(IconData icon, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 5),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }

  Widget _buildActionButton({required String label, required Color color, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
      ),
    );
  }
}