import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/level_model.dart';
import 'material_screen.dart'; // Pastikan file ini sudah ada dari langkah sebelumnya

class StoryScreen extends StatelessWidget {
  final UserModel user; // Menerima data user untuk cek level

  const StoryScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        
        // --- BAGIAN 1: KARTU TUGAS HARIAN ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // Kartu 1: Ulangan Harian (Review)
              Expanded(
                child: _buildTaskCard(
                  title: "Ulangan Harian",
                  subtitle: "Review 'Simple Tense'",
                  progress: 0.75,
                  colorStart: Colors.blueAccent,
                  colorEnd: Colors.blue[900]!,
                  btnText: "MULAI REVIEW",
                  icon: Icons.shield_outlined,
                ),
              ),
              const SizedBox(width: 15),
              // Kartu 2: Kosa Kata Baru
              Expanded(
                child: _buildTaskCard(
                  title: "Kosa Kata",
                  subtitle: "5/10 Kata Baru",
                  progress: 0.5,
                  colorStart: const Color(0xFFBD00FF), // Ungu Neon
                  colorEnd: const Color(0xFF4A0080),
                  btnText: "PELAJARI",
                  icon: Icons.menu_book_rounded,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        // Judul Bagian
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: const [
              Icon(Icons.emoji_events_outlined, color: Colors.white70),
              SizedBox(width: 10),
              Text("Jalur Pembelajaran", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // --- BAGIAN 2: JALUR LEVEL (Horizontal Scroll) ---
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal, // Scroll ke samping
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: gameLevels.length, // Mengambil data dari level_model.dart
            itemBuilder: (context, index) {
              final level = gameLevels[index];
              // PERBAIKAN UTAMA: Mengirim 'context' ke dalam fungsi helper
              return _buildLevelNode(context, level, index);
            },
          ),
        ),
      ],
    );
  }

  // --- WIDGET HELPER: CARD TUGAS ---
  Widget _buildTaskCard({
    required String title,
    required String subtitle,
    required double progress,
    required Color colorStart,
    required Color colorEnd,
    required String btnText,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorStart, colorEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: colorStart.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 10),
          // Progress Bar Kecil
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.black26,
              color: Colors.white,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 12),
          // Tombol Kecil
          SizedBox(
            width: double.infinity,
            height: 30,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: EdgeInsets.zero,
                textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
              child: Text(btnText),
            ),
          )
        ],
      ),
    );
  }

  // --- WIDGET HELPER: LINGKARAN LEVEL (NODE) ---
  // PERBAIKAN: Menambahkan parameter 'BuildContext context' agar bisa navigasi
  Widget _buildLevelNode(BuildContext context, LevelModel level, int index) {
    
    // LOGIKA SYSTEM UNLOCK
    // Level 1 ada di index 0. Jika lastCompletedLevel = 0, maka index 0 (Level 1) aktif.
    bool isCompleted = index < user.lastCompletedLevel;
    bool isActive = index == user.lastCompletedLevel;
    bool isLocked = index > user.lastCompletedLevel;

    return Container(
      width: 140, // Lebar per item
      margin: const EdgeInsets.only(right: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. Lingkaran Neon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.cyanAccent.withOpacity(0.1) : Colors.transparent,
              border: Border.all(
                color: isCompleted ? Colors.green : (isActive ? Colors.cyanAccent : Colors.grey),
                width: 3,
              ),
              boxShadow: isActive ? [
                const BoxShadow(color: Colors.cyanAccent, blurRadius: 15, spreadRadius: 2)
              ] : [],
            ),
            child: Icon(
              isCompleted ? Icons.check : (isActive ? Icons.play_arrow_rounded : Icons.lock),
              color: isCompleted ? Colors.green : (isActive ? Colors.cyanAccent : Colors.grey),
              size: 40,
            ),
          ),
          
          const SizedBox(height: 15),
          
          // 2. Teks Judul
          Text(
            level.title,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            level.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.cyanAccent : Colors.grey[700],
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 10),

          // 3. Tombol Aksi (Hanya muncul jika Level Aktif)
          if (isActive)
            ElevatedButton(
              onPressed: () {
                // Navigasi ke MaterialScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MaterialScreen(level: level, user: user),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBD00FF),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              ),
              child: const Text("LANJUT", style: TextStyle(fontSize: 12)),
            ),
          
          // Indikator Syarat (Jika Terkunci)
          if (isLocked)
             const Padding(
               padding: EdgeInsets.only(top: 8.0),
               child: Text("Terkunci", style: TextStyle(color: Colors.grey, fontSize: 10)),
             ),
        ],
      ),
    );
  }
}