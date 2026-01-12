import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Pastikan package ini ada di pubspec.yaml
import '../../models/user_model.dart';
import '../../models/level_model.dart';
import 'material_screen.dart';
import 'vocabulary_screen.dart';
import '../quiz/quiz_screen.dart';
import '../../models/question_model.dart';

class StoryScreen extends StatelessWidget {
  final UserModel user;

  const StoryScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Menggabungkan level game dengan item tambahan untuk "Trophy/Test" di akhir
    final int totalItems = gameLevels.length + 1;

    return Container(
      width: double.infinity,
      // Background gradient halaman Story (sedikit transparan agar bg MainScreen terlihat)
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent, 
            const Color(0xFF0F0025).withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          
          // --- BAGIAN 1: KARTU AKTIVITAS (Atas) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // KARTU 1: Ulangan Harian (Blue Theme)
                Expanded(
                  child: _buildTaskCard(
                    context,
                    title: "Ulangan Harian",
                    subtitle: "Review 'Simple Tense'",
                    infoText: "5 mnt", // Durasi
                    progress: 0.75,
                    // Gradient Biru Neon
                    colors: [const Color(0xFF448AFF), const Color(0xFF2962FF)], 
                    btnText: "MULAI REVIEW",
                    btnColor: const Color(0xFFFFC107), // Warna Kuning Emas
                    onTap: () {
                      _startDailyReview(context);
                    },
                  ),
                ),
                const SizedBox(width: 15),
                
                // KARTU 2: Kosa Kata (Pink/Purple Theme)
                Expanded(
                  child: _buildTaskCard(
                    context,
                    title: "Kosa Kata Hari Ini",
                    subtitle: "5/10 kata",
                    infoText: "", 
                    progress: 0.5,
                    // Gradient Pink-Ungu Neon
                    colors: [const Color(0xFFE040FB), const Color(0xFFAA00FF)],
                    btnText: "PELAJARI KATA",
                    btnColor: const Color(0xFFFFC107),
                    onTap: () {
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

          // JUDUL BAGIAN PETA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              "Jalur Pembelajaran",
              style: GoogleFonts.poppins(
                color: Colors.white, 
                fontSize: 18, 
                fontWeight: FontWeight.w600
              ),
            ),
          ),

          const SizedBox(height: 10),

          // --- BAGIAN 2: JALUR LEVEL (Horizontal Scroll) ---
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: totalItems,
              itemBuilder: (context, index) {
                // Jika index terakhir, render Trophy Node
                if (index == gameLevels.length) {
                  return _buildTrophyNode();
                }

                // Render Level Node biasa
                final level = gameLevels[index];
                return _buildLevelNode(context, level, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- LOGIC: Memulai Daily Quiz ---
  void _startDailyReview(BuildContext context) {
    List<QuestionModel> dailyQuestions = List.from(grammarQuestionBank);
    dailyQuestions.shuffle();
    dailyQuestions = dailyQuestions.take(5).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          level: LevelModel(
            id: 0, 
            title: "DAILY REVIEW", 
            subtitle: "Latihan Harian", 
            type: 'review'
          ),
          user: user,
          customQuestions: dailyQuestions,
        ),
      ),
    );
  }

  // --- WIDGET: KARTU TUGAS (Task Card) ---
  Widget _buildTaskCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String infoText,
    required double progress,
    required List<Color> colors,
    required String btnText,
    required Color btnColor,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors, 
          begin: Alignment.topLeft, 
          end: Alignment.bottomRight
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Kartu (Judul & Info Waktu)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title, 
                  style: GoogleFonts.poppins(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 14
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (infoText.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.white70, size: 12),
                    const SizedBox(width: 4),
                    Text(infoText, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
            ],
          ),
          
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          
          const SizedBox(height: 12),
          
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress, 
              backgroundColor: Colors.black.withValues(alpha: 0.2), 
              color: Colors.white, 
              minHeight: 6
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Tombol Action (Kuning/Emas)
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: btnColor,
                foregroundColor: Colors.black87,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                btnText, 
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold)
              ),
            ),
          )
        ],
      ),
    );
  }

  // --- WIDGET: LEVEL NODE ---
  Widget _buildLevelNode(BuildContext context, LevelModel level, int index) {
    // Logika Status Level
    bool isCompleted = index < user.lastCompletedLevel;
    bool isActive = index == user.lastCompletedLevel;

    return Container(
      width: 140, // Lebar area per level agar tidak terlalu rapat
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // VISUAL LINGKARAN & GARIS
          SizedBox(
            height: 100,
            width: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Garis Penghubung (Dibelakang lingkaran)
                Positioned(
                  left: 70, // Mulai dari tengah lingkaran ke kanan
                  right: -70, // Sampai ke tengah lingkaran berikutnya
                  child: Container(
                    height: 4,
                    // Garis putus-putus atau solid
                    decoration: BoxDecoration(
                      color: isCompleted ? const Color(0xFF00E676) : Colors.grey[800],
                    ),
                  ),
                ),

                // Lingkaran Utama
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Warna isi lingkaran
                    color: isCompleted 
                        ? const Color(0xFF00C853) // Hijau jika selesai
                        : (isActive ? const Color(0xFFBD00FF) : const Color(0xFF1E1E2C)), // Ungu aktif / Abu mati
                    
                    // Border (Glow jika aktif)
                    border: isActive 
                        ? Border.all(color: Colors.cyanAccent, width: 3)
                        : Border.all(color: isCompleted ? Colors.transparent : Colors.grey[700]!, width: 2),
                    
                    // Efek Glow untuk yang aktif
                    boxShadow: isActive 
                        ? [BoxShadow(color: const Color(0xFFBD00FF).withValues(alpha: 0.6), blurRadius: 20, spreadRadius: 2)] 
                        : [],
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_rounded : (isActive ? Icons.play_arrow_rounded : Icons.lock_outline),
                    color: Colors.white,
                    size: 32,
                  ),
                ),

                // Tombol "LANJUT" (Hanya muncul jika Aktif) - Posisi menumpuk di bawah lingkaran
                if (isActive)
                  Positioned(
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                      ),
                      child: Text(
                        "LANJUT",
                        style: GoogleFonts.poppins(
                          color: Colors.black, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 10
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // TEKS KETERANGAN LEVEL
          Text(
            "Level ${level.id}",
            style: GoogleFonts.poppins(
              color: isActive ? Colors.white : Colors.white60,
              fontWeight: FontWeight.w600,
              fontSize: 12
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              level.title, // Menggunakan title (Topik)
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: isActive ? Colors.cyanAccent : Colors.grey,
                fontSize: 10,
              ),
            ),
          ),

          // Interaksi Klik
          if (isActive)
             // Area transparan untuk menangkap ketukan di sekitar level aktif
             GestureDetector(
               onTap: () {
                 Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MaterialScreen(level: level, user: user)),
                  );
               },
               child: Container(height: 40, width: 40, color: Colors.transparent),
             )
        ],
      ),
    );
  }

  // --- WIDGET: TROPHY NODE (Item Terakhir) ---
  Widget _buildTrophyNode() {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           SizedBox(
            height: 100,
            width: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Konektor Masuk (Kiri saja)
                Positioned(
                  left: -70,
                  right: 70,
                  child: Container(
                    height: 4,
                    color: Colors.grey[800],
                  ),
                ),
                // Lingkaran Trophy
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.5),
                    border: Border.all(color: Colors.grey[700]!, width: 2),
                  ),
                  child: const Icon(Icons.emoji_events_outlined, color: Colors.amber, size: 30),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Final Test",
            style: GoogleFonts.poppins(color: Colors.white60, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Text(
            "Selesaikan semua level",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 10),
          ),
        ],
      ),
    );
  }
}