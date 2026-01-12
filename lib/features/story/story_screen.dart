import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../models/level_model.dart';
import '../../models/question_model.dart';
import '../quiz/quiz_screen.dart';
import 'vocabulary_screen.dart';
import 'material_screen.dart';

class StoryScreen extends StatefulWidget {
  final UserModel user;

  const StoryScreen({super.key, required this.user});

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  int _displayStageIndex = 0; 
  int _maxUnlockedStageIndex = 0;

  @override
  void initState() {
    super.initState();
    _calculateInitialStage();
  }

  void _calculateInitialStage() {
    int currentActiveLevel = widget.user.lastCompletedLevel + 1;
    if (currentActiveLevel > 20) currentActiveLevel = 20;

    _maxUnlockedStageIndex = (currentActiveLevel - 1) ~/ 5;
    _displayStageIndex = _maxUnlockedStageIndex;
  }

  // --- LOGIKA WARNA BERDASARKAN STAGE (PROFESIONAL) ---
  Color _getStageColor(int levelId) {
    // Jika Boss Level (Kelipatan 5), Warnanya Merah Bahaya
    if (levelId % 5 == 0) return const Color(0xFFFF5252); // Red Accent

    if (levelId <= 5) return const Color(0xFF64FFDA); // Cyan (Beginner)
    if (levelId <= 10) return const Color(0xFF69F0AE); // Green (Rookie)
    if (levelId <= 15) return const Color(0xFFFFAB40); // Orange (Intermediate)
    return const Color(0xFFE040FB); // Purple (Advanced)
  }

  String _getStageName(int stageIndex) {
    if (stageIndex == 0) return "BEGINNER (Lv 1-5)";
    if (stageIndex == 1) return "ROOKIE (Lv 6-10)";
    if (stageIndex == 2) return "INTERMEDIATE (Lv 11-15)";
    return "ADVANCED (Lv 16-20)";
  }

  @override
  Widget build(BuildContext context) {
    int startId = (_displayStageIndex * 5) + 1;
    int endId = startId + 4;

    List<LevelModel> visibleLevels = gameLevels
        .where((lvl) => lvl.id >= startId && lvl.id <= endId)
        .toList();

    // Ambil warna tema stage saat ini untuk mewarnai Judul & Navigasi
    Color currentStageThemeColor = _getStageColor(startId); 

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1E1E2C),
              const Color(0xFF0F0025).withOpacity(0.95),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // --- 1. KARTU AKTIVITAS ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTaskCard(
                        context,
                        title: "Review",
                        subtitle: "Grammar",
                        infoText: "5 mnt",
                        progress: 0.75,
                        colors: [const Color(0xFF448AFF), const Color(0xFF2962FF)],
                        btnText: "MULAI",
                        btnColor: const Color(0xFFFFC107),
                        onTap: () => _startDailyReview(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTaskCard(
                        context,
                        title: "Kosa Kata",
                        subtitle: "Hafalan Baru",
                        infoText: "10 Kata",
                        progress: 0.5,
                        colors: [const Color(0xFFE040FB), const Color(0xFFAA00FF)],
                        btnText: "HAFALKAN",
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

              const SizedBox(height: 40),

              // --- 2. JUDUL STAGE & NAVIGASI ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Peta Pembelajaran",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: currentStageThemeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: currentStageThemeColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(Icons.chevron_left_rounded, color: _displayStageIndex > 0 ? currentStageThemeColor : Colors.white10, size: 20),
                            onPressed: _displayStageIndex > 0 ? () => setState(() => _displayStageIndex--) : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getStageName(_displayStageIndex),
                            style: GoogleFonts.poppins(color: currentStageThemeColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(Icons.chevron_right_rounded, color: _displayStageIndex < _maxUnlockedStageIndex ? currentStageThemeColor : Colors.white10, size: 20),
                            onPressed: _displayStageIndex < _maxUnlockedStageIndex ? () => setState(() => _displayStageIndex++) : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- 3. GRID LEVEL ---
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 0,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.55,
                    ),
                    itemCount: visibleLevels.length,
                    itemBuilder: (context, index) {
                      final level = visibleLevels[index];
                      return _buildLevelItem(context, level);
                    },
                  ),
                ),
              ),
              
              // INDICATOR DOTS
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      bool isUnlocked = index <= _maxUnlockedStageIndex;
                      // Tentukan warna dot berdasarkan stage index-nya
                      // Agar dot 1 warnanya Cyan, Dot 2 Hijau, dst.
                      Color dotColor = _getStageColor((index * 5) + 1);
                      if (index > 0 && index % 1 == 0 && index * 5 + 1 % 5 == 0) {
                         // Logic adjustment for boss coloring fix in helper function
                         // Just force standard colors for dots:
                         if (index == 0) dotColor = const Color(0xFF64FFDA);
                         if (index == 1) dotColor = const Color(0xFF69F0AE);
                         if (index == 2) dotColor = const Color(0xFFFFAB40);
                         if (index == 3) dotColor = const Color(0xFFE040FB);
                      }

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == _displayStageIndex 
                              ? dotColor 
                              : (isUnlocked ? dotColor.withOpacity(0.3) : Colors.white10),
                        ),
                      );
                    }),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET ITEM LEVEL (TOMBOL PLAY PROFESIONAL) ---
  Widget _buildLevelItem(BuildContext context, LevelModel level) {
    bool isLocked = level.id > (widget.user.lastCompletedLevel + 1);
    bool isCurrent = level.id == widget.user.lastCompletedLevel + 1;
    bool isBoss = level.id % 5 == 0;

    // AMBIL WARNA DINAMIS SESUAI STAGE
    Color stageColor = _getStageColor(level.id);
    Color displayColor = isLocked ? Colors.white10 : stageColor;
    
    double circleSize = 45.0;

    return GestureDetector(
      onTap: () {
        if (isLocked) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selesaikan level sebelumnya dulu!")));
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MaterialScreen(level: level, user: widget.user)),
          );
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // LINGKARAN PEMBUNGKUS
          Container(
            width: circleSize, 
            height: circleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrent ? displayColor : Colors.transparent, // Jika aktif, isi penuh
              border: Border.all(
                color: displayColor,
                width: isCurrent ? 0 : 2,
              ),
              boxShadow: isCurrent 
                  ? [BoxShadow(color: displayColor.withOpacity(0.6), blurRadius: 15, spreadRadius: 2)] 
                  : [],
            ),
            child: Center(
              child: isLocked
                  ? const Icon(Icons.lock, color: Colors.white24, size: 20)
                  : (isBoss 
                      ? const Icon(Icons.star_rounded, color: Colors.white, size: 24) // Boss pakai Bintang
                      : Icon(
                          Icons.play_arrow_rounded, // Level Biasa pakai Play
                          // Jika aktif (background berwarna), ikon hitam. Jika belum (outline), ikon berwarna.
                          color: isCurrent ? Colors.black : displayColor, 
                          size: 26,
                        )
                    ),
            ),
          ),
          
          const SizedBox(height: 10),
          
          Text(
            "Level ${level.id}", 
            style: GoogleFonts.poppins(
              color: isCurrent ? stageColor : Colors.white38, // Teks menyala jika level saat ini
              fontSize: 10, 
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 4),
          Text(
            level.subtitle,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: isLocked ? Colors.white12 : (isBoss ? Colors.redAccent : Colors.white70),
              fontSize: 9,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: colors.last.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              if (infoText.isNotEmpty) Text(infoText, style: const TextStyle(color: Colors.white70, fontSize: 9)),
            ],
          ),
          Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 9)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(value: progress, backgroundColor: Colors.black.withOpacity(0.2), color: Colors.white, minHeight: 4),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 28,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: btnColor, foregroundColor: Colors.black87, elevation: 0, padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(btnText, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  void _startDailyReview(BuildContext context) {
    List<QuestionModel> dailyQuestions = List.from(grammarQuestionBank);
    dailyQuestions.shuffle();
    if (dailyQuestions.length > 5) dailyQuestions = dailyQuestions.take(5).toList();
    Navigator.push(context, MaterialPageRoute(builder: (context) => QuizScreen(level: LevelModel(id: 0, title: "DAILY REVIEW", subtitle: "Latihan Harian", type: 'review'), user: widget.user, customQuestions: dailyQuestions)));
  }
}