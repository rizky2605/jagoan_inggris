import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/vocabulary_service.dart';
import '../../core/services/firestore_service.dart';
import '../../models/user_model.dart';
import 'daily_learning_screen.dart';
import 'vocabulary_screen.dart';

class VocabularyMenuScreen extends StatelessWidget {
  const VocabularyMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final VocabularyService vocabService = VocabularyService();
    final FirestoreService firestoreService = FirestoreService();
    final user = FirebaseAuth.instance.currentUser;
    final String uid = user?.uid ?? '';

    // Cek orientasi layar
    bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    if (uid.isEmpty) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

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
              // --- HEADER ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Padding vertikal dikurangi dikit
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white), 
                      onPressed: () => Navigator.pop(context)
                    ),
                    Expanded(
                      child: Text(
                        "Pusat Kosa Kata",
                        style: GoogleFonts.orbitron(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center
                      ),
                    ),
                    const SizedBox(width: 40), 
                  ],
                ),
              ),
              
              // --- MENU OPTIONS (SCROLLABLE) ---
              Expanded(
                // Gunakan SingleChildScrollView agar aman di Landscape
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: Column(
                    children: [
                      // 1. MENU BELAJAR BARU (DINAMIS)
                      StreamBuilder<UserModel>(
                        stream: firestoreService.getUserStream(uid),
                        builder: (context, userSnapshot) {
                          bool targetReached = false;
                          int dailyCount = 0;
                          int dailyTarget = 20;

                          if (userSnapshot.hasData) {
                            dailyCount = userSnapshot.data!.dailyWordCount;
                            dailyTarget = userSnapshot.data!.dailyWordTarget;
                            targetReached = dailyCount >= dailyTarget;
                          }

                          return StreamBuilder<int>(
                            stream: vocabService.getTotalLearnedStream(uid),
                            builder: (context, vocabSnapshot) {
                              int totalLearned = vocabSnapshot.data ?? 0;
                              
                              return _buildMenuCard(
                                context: context,
                                title: targetReached ? "Lanjut Hafalan (Bonus)" : "Belajar Kata Baru",
                                subtitle: targetReached 
                                    ? "Target harian tercapai! Tekan untuk tambah lagi."
                                    : "Target hari ini: $dailyCount/$dailyTarget ($totalLearned Total)",
                                icon: targetReached ? Icons.add_circle_outline : Icons.school_rounded,
                                color1: targetReached ? Colors.orangeAccent : Colors.cyanAccent,
                                color2: targetReached ? Colors.deepOrange : Colors.blueAccent,
                                badgeCount: 0, 
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DailyLearningScreen())),
                                isLandscape: isLandscape, // Pass orientasi
                              );
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // 2. MENU REVIEW (SRS)
                      StreamBuilder<int>(
                        stream: vocabService.getDueCountStream(uid),
                        builder: (context, snapshot) {
                          int dueCount = snapshot.data ?? 0;
                          return _buildMenuCard(
                            context: context,
                            title: "Review Harian (SRS)",
                            subtitle: dueCount > 0 
                                ? "Ada $dueCount kata perlu direview!" 
                                : "Semua aman untuk saat ini.",
                            icon: Icons.notifications_active,
                            color1: const Color(0xFFBD00FF),
                            color2: const Color(0xFFD500F9),
                            badgeCount: dueCount, 
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VocabularyScreen())),
                            isLandscape: isLandscape,
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // 3. MENU LATIHAN BEBAS
                      _buildMenuCard(
                        context: context,
                        title: "Latihan Bebas",
                        subtitle: "Review semua koleksi katamu kapan saja.",
                        icon: Icons.all_inclusive,
                        color1: const Color(0xFF00C853), 
                        color2: const Color(0xFF64DD17),
                        badgeCount: 0,
                        onTap: () => Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => const VocabularyScreen(isPracticeMode: true))
                        ),
                        isLandscape: isLandscape,
                      ),
                      
                      const SizedBox(height: 20), // Padding bawah tambahan agar tidak mentok
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

  Widget _buildMenuCard({
    required BuildContext context,
    required String title, 
    required String subtitle, 
    required IconData icon,
    required Color color1, 
    required Color color2, 
    required int badgeCount, 
    required VoidCallback onTap,
    required bool isLandscape, // Parameter baru
  }) {
    // Kurangi tinggi kartu saat landscape agar muat lebih banyak
    double cardHeight = isLandscape ? 100 : 130; 

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: cardHeight, 
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color1.withOpacity(0.9), color2.withOpacity(0.9)], 
            begin: Alignment.topLeft, 
            end: Alignment.bottomRight
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color1.withOpacity(0.3), 
              blurRadius: 15, 
              offset: const Offset(0, 6)
            )
          ],
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isLandscape ? 10 : 14), // Perkecil padding icon di landscape
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2), 
                      shape: BoxShape.circle
                    ),
                    child: Icon(icon, color: Colors.white, size: isLandscape ? 24 : 30),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title, 
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1, overflow: TextOverflow.ellipsis, // Cegah overflow teks
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle, 
                          style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 11),
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 18),
                ],
              ),
            ),
            
            if (badgeCount > 0)
              Positioned(
                top: 10, right: 10,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent, 
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)]
                  ),
                  child: Text(
                    "$badgeCount", 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}