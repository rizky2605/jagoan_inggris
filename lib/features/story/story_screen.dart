import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/level_model.dart';
import 'material_screen.dart';
import 'vocabulary_screen.dart'; // Import layar kosa kata

class StoryScreen extends StatelessWidget {
  final UserModel user;

  const StoryScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        
        // --- BAGIAN 1: DAILY TASKS (Atas) ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // Kartu 1: Ulangan Harian (Review) -> Nanti kita buat Quiz Acak disini
              Expanded(
                child: _buildTaskCard(
                  context,
                  title: "Ulangan Harian",
                  subtitle: "Review Materi",
                  progress: 0.3, // Contoh progress
                  colorStart: Colors.blueAccent,
                  colorEnd: Colors.blue[900]!,
                  btnText: "MULAI",
                  icon: Icons.shield_outlined,
                  onTap: () {
                    // Nanti diarahkan ke Random Quiz
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur Review segera hadir!")));
                  },
                ),
              ),
              const SizedBox(width: 15),
              
              // Kartu 2: Kosa Kata Baru -> MENUJU VOCABULARY SCREEN
              Expanded(
                child: _buildTaskCard(
                  context,
                  title: "Kosa Kata",
                  subtitle: "5 Kata Baru",
                  progress: 0.0, // Belum mulai
                  colorStart: const Color(0xFFBD00FF),
                  colorEnd: const Color(0xFF4A0080),
                  btnText: "PELAJARI",
                  icon: Icons.menu_book_rounded,
                  onTap: () {
                    // Navigasi ke Vocabulary Screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const VocabularyScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        // Judul Bagian Peta
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: const [
              Icon(Icons.map, color: Colors.cyanAccent),
              SizedBox(width: 10),
              Text("Peta Perjalanan", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // --- BAGIAN 2: JALUR LEVEL (Peta Horizontal) ---
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              // Background gradient halus di area peta
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
              ),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: gameLevels.length,
              itemBuilder: (context, index) {
                final level = gameLevels[index];
                return _buildLevelNode(context, level, index);
              },
            ),
          ),
        ),
      ],
    );
  }

  // --- WIDGET CARD TUGAS ---
  Widget _buildTaskCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required double progress,
    required Color colorStart,
    required Color colorEnd,
    required String btnText,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colorStart, colorEnd], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: colorStart.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: progress, backgroundColor: Colors.black26, color: Colors.white, minHeight: 4),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 30,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: colorEnd,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(btnText, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  // --- WIDGET NODE LEVEL ---
  Widget _buildLevelNode(BuildContext context, LevelModel level, int index) {
    bool isCompleted = index < user.lastCompletedLevel;
    bool isActive = index == user.lastCompletedLevel;
    bool isLocked = index > user.lastCompletedLevel;

    return Container(
      width: 120, // Jarak antar node
      margin: const EdgeInsets.only(right: 15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // NODE BULATAN
          Stack(
            alignment: Alignment.center,
            children: [
              // Garis penghubung (Kecuali item terakhir)
              if (index < gameLevels.length - 1)
                Positioned(
                  right: -60, // Menjorok ke kanan untuk nyambung ke sebelah
                  child: Container(
                    width: 60,
                    height: 4,
                    color: isCompleted ? Colors.green : Colors.grey[800],
                  ),
                ),
                
              // Lingkaran Utama
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? Colors.cyanAccent.withOpacity(0.1) : const Color(0xFF1E1E2C),
                  border: Border.all(
                    color: isCompleted ? Colors.green : (isActive ? Colors.cyanAccent : Colors.grey[800]!),
                    width: isActive ? 3 : 2,
                  ),
                  boxShadow: isActive ? [const BoxShadow(color: Colors.cyanAccent, blurRadius: 20, spreadRadius: 2)] : [],
                ),
                child: Icon(
                  isCompleted ? Icons.check : (isActive ? Icons.play_arrow_rounded : Icons.lock),
                  color: isCompleted ? Colors.green : (isActive ? Colors.cyanAccent : Colors.grey),
                  size: 35,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 15),
          
          // Judul Level
          Text(
            "Level ${level.id}",
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 14
            ),
          ),
          Text(
            level.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.cyanAccent : Colors.grey[700],
              fontSize: 10,
            ),
          ),

          const SizedBox(height: 10),

          // Tombol Start (Hanya jika aktif)
          if (isActive)
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MaterialScreen(level: level, user: user)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBD00FF),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                elevation: 10,
                shadowColor: const Color(0xFFBD00FF),
              ),
              child: const Text("MULAI", style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
            )
          else if (isLocked)
             const Padding(
               padding: EdgeInsets.only(top: 8.0),
               child: Icon(Icons.lock_outline, color: Colors.grey, size: 16),
             ),
        ],
      ),
    );
  }
}