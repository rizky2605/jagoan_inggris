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
  final bool isVictory; 

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
    _goldReward = 0;
    _xpReward = 0;
    _isLevelUnlocked = false;

    if (widget.isVictory) {
      // Logic: Hadiah hanya untuk Level Baru (Level ID > Last Completed)
      bool isFirstTimeCompletion = widget.levelId > widget.user.lastCompletedLevel;

      if (isFirstTimeCompletion) {
        _goldReward = widget.score * 20;
        _xpReward = widget.score * 50;
        _isLevelUnlocked = true;

        await _firestoreService.updateUserProgress(
          uid: widget.user.uid,
          goldGained: _goldReward,
          xpGained: _xpReward,
          currentLevelId: widget.levelId,
        );
      } else {
        debugPrint("Replay level lama: Tidak ada reward.");
      }
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
            child: Image.asset("assets/images/jungle.jpg", fit: BoxFit.cover),
          ),
          
          // Blur Overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.black.withOpacity(0.6)),
            ),
          ),

          // Fireworks (Only Victory)
          if (widget.isVictory && !_isLoading)
            Align(
              alignment: Alignment.topCenter,
              child: Lottie.asset(
                'assets/effects/fireworks.json',
                repeat: true,
                fit: BoxFit.contain,
              ),
            ),

          // Main Content Area
          Center(
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.cyanAccent)
                : _buildLandscapeCard(statusColor),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeCard(Color statusColor) {
    // Ukuran Card disesuaikan agar pas di tengah layar landscape
    return Container(
      width: double.infinity,
      height: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 20), // Margin dari tepi layar
      padding: const EdgeInsets.all(20),
      constraints: const BoxConstraints(maxWidth: 750), // Batas lebar agar tidak terlalu stretch di tablet
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: statusColor.withOpacity(0.5), width: 2),
      ),
      child: Row(
        children: [
          // === KOLOM KIRI: Visual & Score ===
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeader(statusColor),
                
                // Animasi Lottie (Dikecilkan sedikit agar muat)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Lottie.asset(
                      widget.isVictory 
                        ? 'assets/effects/fireworks.json' 
                        : 'assets/effects/blood.json', 
                      repeat: widget.isVictory,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                _buildScoreInfo(),
              ],
            ),
          ),

          // === GARIS PEMISAH ===
          Container(
            width: 1,
            height: double.infinity,
            color: Colors.white10,
            margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
          ),

          // === KOLOM KANAN: Hadiah & Tombol ===
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                _buildRewardSection(),
                const Spacer(),
                _buildButtons(statusColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildHeader(Color statusColor) {
    return Text(
      widget.isVictory ? "VICTORY!" : "DEFEAT",
      style: TextStyle(
        fontSize: 36, // Font besar untuk judul
        fontWeight: FontWeight.w900,
        letterSpacing: 3,
        color: statusColor,
        shadows: [Shadow(color: statusColor, blurRadius: 20)],
      ),
    );
  }

  Widget _buildScoreInfo() {
    return Column(
      children: [
        Text(
          "Final Score",
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
        ),
        Text(
          "${widget.score}",
          style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildRewardSection() {
    if (!widget.isVictory) {
      return const Column(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.white54, size: 40),
          SizedBox(height: 10),
          Text(
            "Boss masih bertahan!",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            "Gunakan Critical Hit (Jawab Cepat)\nuntuk mengalahkan boss.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      );
    }

    // Jika Menang tapi Replay (Hadiah 0)
    if (_goldReward == 0 && _xpReward == 0) {
      return Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.amber.withOpacity(0.3)),
        ),
        child: const Column(
          children: [
            Icon(Icons.history_edu, color: Colors.amber, size: 30),
            SizedBox(height: 10),
            Text(
              "Latihan Selesai!",
              style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 5),
            Text(
              "Tidak ada hadiah XP/Gold\nuntuk pengulangan level.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Jika Menang Level Baru
    return Column(
      children: [
        const Text("REWARDS GAINED", style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1)),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildRewardTile(Icons.monetization_on, "$_goldReward", Colors.amber),
            const SizedBox(width: 30),
            _buildRewardTile(Icons.bolt, "$_xpReward", Colors.purpleAccent),
          ],
        ),
        if (_isLevelUnlocked) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.greenAccent),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_open_rounded, color: Colors.greenAccent, size: 16),
                SizedBox(width: 8),
                Text("LEVEL BARU TERBUKA!", style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildButtons(Color statusColor) {
    return SizedBox(
      width: double.infinity, // Full width di kolom kanan
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: statusColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 5,
              ),
              child: Text(
                widget.isVictory ? "NEXT MISSION" : "TRY AGAIN",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Back to Map", style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardTile(IconData icon, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.5))
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20)),
      ],
    );
  }
}