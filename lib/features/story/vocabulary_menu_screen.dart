import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'daily_learning_screen.dart'; // Import screen belajar harian
import 'vocabulary_screen.dart';    // Import screen flashcard (review)

class VocabularyMenuScreen extends StatelessWidget {
  const VocabularyMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background Gradient Konsisten
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        "Pusat Kosa Kata",
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 40), // Penyeimbang layout
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- PILIHAN MENU ---
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // MENU 1: BELAJAR HARIAN
                      _buildMenuCard(
                        context,
                        title: "Belajar Kata Baru",
                        subtitle: "5 Kata/Hari + Tips Menghafal",
                        icon: Icons.school_rounded,
                        color1: Colors.cyanAccent,
                        color2: Colors.blueAccent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const DailyLearningScreen()),
                          );
                        },
                      ),

                      const SizedBox(height: 30),

                      // MENU 2: REVIEW FLASHCARD
                      _buildMenuCard(
                        context,
                        title: "Review Flashcard",
                        subtitle: "Ulangi kata yang sudah disimpan",
                        icon: Icons.style_rounded, // Ikon tumpukan kartu
                        color1: const Color(0xFFBD00FF), // Ungu Neon
                        color2: const Color(0xFFD500F9),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const VocabularyScreen()),
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

  // WIDGET KARTU MENU CANTIK
  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color1,
    required Color color2,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color1.withOpacity(0.9), color2.withOpacity(0.9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color1.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Stack(
          children: [
            // Hiasan Background (Lingkaran transparan)
            Positioned(
              right: -20,
              top: -20,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white.withOpacity(0.1),
              ),
            ),

            // Konten Utama
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}