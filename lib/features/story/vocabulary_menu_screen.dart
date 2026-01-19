import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/vocabulary_service.dart';
import 'daily_learning_screen.dart';
import 'vocabulary_screen.dart';

class VocabularyMenuScreen extends StatelessWidget {
  const VocabularyMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final VocabularyService vocabService = VocabularyService();
    final String uid = FirebaseAuth.instance.currentUser!.uid;

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
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
                    Expanded(
                      child: Text("Pusat Kosa Kata",
                          style: GoogleFonts.orbitron(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Menu Options
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 1. MENU BELAJAR BARU (Dengan Counter Total)
                      StreamBuilder<int>(
                        stream: vocabService.getTotalLearnedStream(uid),
                        builder: (context, snapshot) {
                          int total = snapshot.data ?? 0;
                          return _buildMenuCard(
                            context,
                            title: "Belajar Kata Baru",
                            subtitle: "Total dipelajari: $total Kata", // Tampilkan Total
                            icon: Icons.school_rounded,
                            color1: Colors.cyanAccent,
                            color2: Colors.blueAccent,
                            badgeCount: 0, // Tidak butuh badge merah
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DailyLearningScreen())),
                          );
                        },
                      ),

                      const SizedBox(height: 30),

                      // 2. MENU REVIEW (Dengan Counter Due)
                      StreamBuilder<int>(
                        stream: vocabService.getDueCountStream(uid),
                        builder: (context, snapshot) {
                          int dueCount = snapshot.data ?? 0;
                          return _buildMenuCard(
                            context,
                            title: "Review Flashcard",
                            subtitle: dueCount > 0 ? "Ada $dueCount kata perlu direview!" : "Semua aman untuk saat ini.",
                            icon: Icons.style_rounded,
                            color1: const Color(0xFFBD00FF),
                            color2: const Color(0xFFD500F9),
                            badgeCount: dueCount, // Tampilkan Badge Merah
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VocabularyScreen())),
                          );
                        },
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

  Widget _buildMenuCard(
    BuildContext context, {
    required String title, required String subtitle, required IconData icon,
    required Color color1, required Color color2, required int badgeCount, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color1.withAlpha(230), color2.withAlpha(230)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: color1.withAlpha(102), blurRadius: 20, offset: const Offset(0, 8))],
          border: Border.all(color: const Color(0x33FFFFFF), width: 1),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(color: Color(0x33000000), shape: BoxShape.circle),
                    child: Icon(icon, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(subtitle, style: GoogleFonts.poppins(color: const Color(0xE6FFFFFF), fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 20),
                ],
              ),
            ),
            
            // BADGE NOTIFIKASI (Jika ada review)
            if (badgeCount > 0)
              Positioned(
                top: 15, right: 15,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                  child: Text("$badgeCount", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}