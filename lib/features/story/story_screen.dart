import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui'; // Diperlukan untuk CustomPainter
import 'dart:math'; // Diperlukan untuk animasi

import '../../models/user_model.dart';
import '../../models/level_model.dart';
import '../../models/question_model.dart';
import '../../core/services/firestore_service.dart';
import 'material_screen.dart';
import 'review_screen.dart';
import 'vocabulary_menu_screen.dart';

class StoryScreen extends StatefulWidget {
  final UserModel user;

  const StoryScreen({super.key, required this.user});

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  
  // Controller animasi
  late AnimationController _animationController;

  int _displayStageIndex = 0; 
  int _maxUnlockedStageIndex = 0;
  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    // Animasi looping terus menerus (0.0 -> 1.0)
    _animationController = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 1), // Kecepatan gerak garis (makin kecil makin cepat)
    )..repeat(); 
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getStageColor(int levelId) {
    if (levelId % 5 == 0) return const Color(0xFFFF5252); 
    if (levelId <= 5) return const Color(0xFF64FFDA); 
    if (levelId <= 10) return const Color(0xFF69F0AE); 
    if (levelId <= 15) return const Color(0xFFFFAB40); 
    return const Color(0xFFE040FB); 
  }

  String _getStageName(int stageIndex) {
    if (stageIndex == 0) return "BEGINNER (Lv 1-5)";
    if (stageIndex == 1) return "ROOKIE (Lv 6-10)";
    if (stageIndex == 2) return "INTERMEDIATE (Lv 11-15)";
    return "ADVANCED (Lv 16-20)";
  }

  @override
  Widget build(BuildContext context) {
    String uid = widget.user.uid; 

    return StreamBuilder<UserModel>(
      stream: _firestoreService.getUserStream(uid),
      initialData: widget.user, 
      builder: (context, snapshot) {
        UserModel currentUser = snapshot.data ?? widget.user;

        // Auto Switch Stage
        int currentActiveLevel = currentUser.lastCompletedLevel + 1;
        if (currentActiveLevel > 20) currentActiveLevel = 20;
        int calculatedMaxStage = (currentActiveLevel - 1) ~/ 5;

        if (calculatedMaxStage > _maxUnlockedStageIndex) {
          _maxUnlockedStageIndex = calculatedMaxStage;
          _displayStageIndex = calculatedMaxStage; 
        } else if (_isInit) {
          _maxUnlockedStageIndex = calculatedMaxStage;
          _displayStageIndex = calculatedMaxStage;
          _isInit = false;
        }

        // Filter Level
        int startId = (_displayStageIndex * 5) + 1;
        int endId = startId + 4;
        List<LevelModel> visibleLevels = gameLevels
            .where((lvl) => lvl.id >= startId && lvl.id <= endId)
            .toList();

        // Hitung level aktif di stage ini untuk jalur
        int activeLevelsInThisStage = 0;
        for (var lvl in visibleLevels) {
          if (lvl.id <= currentActiveLevel) {
            activeLevelsInThisStage++;
          }
        }

        Color currentStageColor = _getStageColor(startId); 
        double quizProgress = (currentUser.dailyQuizScore / 100).clamp(0.0, 1.0);
        double vocabProgress = (currentUser.dailyWordCount / currentUser.dailyWordTarget).clamp(0.0, 1.0);

        return Scaffold(
          backgroundColor: const Color(0xFF1E1E2C),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xFF1E1E2C), Color(0xF20F0025)],
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),

                  // --- 1. KARTU AKTIVITAS ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      height: 135, 
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTaskCard(
                              context,
                              title: "Review",
                              subtitle: "Materi Lalu",
                              infoText: "Skor: ${currentUser.dailyQuizScore}",
                              progress: quizProgress,
                              colors: [const Color(0xFF448AFF), const Color(0xFF2962FF)],
                              btnText: "MULAI",
                              btnColor: const Color(0xFFFFC107),
                              onTap: () => _startDailyReview(context, currentUser),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTaskCard(
                              context,
                              title: "Kosa Kata",
                              subtitle: "Hafalan Baru",
                              infoText: "${currentUser.dailyWordCount}/${currentUser.dailyWordTarget}",
                              progress: vocabProgress,
                              colors: [const Color(0xFFE040FB), const Color(0xFFAA00FF)],
                              btnText: "HAFALKAN",
                              btnColor: const Color(0xFFFFC107),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const VocabularyMenuScreen()));
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- 2. HEADER STAGE ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white24)
                              ),
                              child: const Icon(Icons.map_rounded, color: Colors.cyanAccent, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Peta Pembelajaran", style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                Text("Stage ${_displayStageIndex + 1}", style: const TextStyle(color: Colors.white54, fontSize: 10)),
                              ],
                            ),
                          ],
                        ),

                        Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: currentStageColor.withAlpha(26),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: currentStageColor.withAlpha(77)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: Icon(Icons.chevron_left_rounded, color: _displayStageIndex > 0 ? currentStageColor : Colors.white10, size: 20),
                                onPressed: _displayStageIndex > 0 ? () => setState(() => _displayStageIndex--) : null,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(_getStageName(_displayStageIndex), style: GoogleFonts.poppins(color: currentStageColor, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: Icon(Icons.chevron_right_rounded, color: _displayStageIndex < _maxUnlockedStageIndex ? currentStageColor : Colors.white10, size: 20),
                                onPressed: _displayStageIndex < _maxUnlockedStageIndex ? () => setState(() => _displayStageIndex++) : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 50), 

                  // --- 3. AREA GRID & JALUR (STACKED) ---
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Stack(
                        children: [
                          // LAYER 1: JALUR (Di Belakang Pin)
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                return CustomPaint(
                                  painter: SegmentedGridPathPainter(
                                    activeColor: currentStageColor,
                                    animationValue: _animationController.value,
                                    activeLevelsCount: activeLevelsInThisStage, 
                                  ),
                                );
                              }
                            ),
                          ),

                          // LAYER 2: PIN LEVEL (Di Depan Jalur)
                          GridView.builder(
                            clipBehavior: Clip.none, 
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5, 
                              mainAxisSpacing: 0,
                              crossAxisSpacing: 20, 
                              childAspectRatio: 0.65,
                            ),
                            itemCount: visibleLevels.length,
                            itemBuilder: (context, index) {
                              final level = visibleLevels[index];
                              return _buildLevelItem(context, level, currentUser);
                            },
                          ),
                        ],
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
                          Color dotColor = _getStageColor((index * 5) + 1);
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: index == _displayStageIndex ? dotColor : (isUnlocked ? dotColor.withAlpha(77) : Colors.white10),
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
    );
  }

  // --- WIDGET HELPER ---

  Widget _buildLevelItem(BuildContext context, LevelModel level, UserModel currentUser) {
    bool isLocked = level.id > (currentUser.lastCompletedLevel + 1);
    bool isCurrent = level.id == currentUser.lastCompletedLevel + 1;
    bool isBoss = level.id % 5 == 0;

    bool isReviewDue = false;
    if (currentUser.levelsProgress.containsKey(level.id.toString())) {
       var progress = currentUser.levelsProgress[level.id.toString()];
       if (progress != null && progress['nextReviewDate'] != null) {
         DateTime nextReview = DateTime.parse(progress['nextReviewDate']);
         if (DateTime.now().isAfter(nextReview)) isReviewDue = true;
       }
    }

    Color stageColor = _getStageColor(level.id);
    Color displayColor = isLocked ? Colors.white10 : (isReviewDue ? const Color(0xFFFF9100) : stageColor); 

    double circleSize = 60.0;

    // Animasi "Breathing" pada Pin
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        double breatheValue = sin(pi * _animationController.value); 
        double dynamicSpread = (isCurrent || isReviewDue) ? 3 + (breatheValue * 5) : 0; 
        double dynamicBlur = (isCurrent || isReviewDue) ? 15 + (breatheValue * 10) : 8; 

        return GestureDetector(
          onTap: () {
            if (isLocked) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selesaikan level sebelumnya dulu!")));
            } else if (isReviewDue) {
              List<QuestionModel> reviewQuestions = levelQuestions[level.id] ?? [];
              if (reviewQuestions.isEmpty) return;
              reviewQuestions.shuffle();
              Navigator.push(context, MaterialPageRoute(builder: (context) => ReviewScreen(user: currentUser, questions: reviewQuestions, levelId: level.id.toString())));
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (context) => MaterialScreen(level: level, user: currentUser)));
            }
          },
          child: Column(
            children: [
              Container(
                width: circleSize, 
                height: circleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrent || isReviewDue ? displayColor : const Color(0xFF2A2A3A),
                  border: Border.all(color: displayColor, width: (isCurrent || isReviewDue) ? 0 : 3),
                  boxShadow: (isCurrent || isReviewDue) 
                      ? [BoxShadow(color: displayColor.withAlpha(180), blurRadius: dynamicBlur, spreadRadius: dynamicSpread)] 
                      : [const BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                ),
                child: Center(
                  child: isLocked
                      ? const Icon(Icons.lock, color: Colors.white24, size: 24)
                      : (isReviewDue
                          ? const Icon(Icons.history_edu, color: Colors.white, size: 28) 
                          : (isBoss 
                              ? const Icon(Icons.star_rounded, color: Colors.white, size: 30) 
                              : Icon(
                                  Icons.play_arrow_rounded, 
                                  color: isCurrent ? Colors.black : displayColor, 
                                  size: 38
                                )
                            )
                        ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              if (isCurrent || isReviewDue)
                Text(isReviewDue ? "REVIEW!" : "PLAY", style: GoogleFonts.poppins(color: displayColor, fontSize: 12, fontWeight: FontWeight.bold))
              else if (!isLocked)
                Text(level.title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10))
            ],
          ),
        );
      }
    );
  }

  void _startDailyReview(BuildContext context, UserModel currentUser) {
    if (currentUser.lastCompletedLevel < 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selesaikan Level 1 dulu!")));
      return;
    }
    List<QuestionModel> allQuestions = [];
    for (int i = 1; i <= currentUser.lastCompletedLevel; i++) {
       if (levelQuestions.containsKey(i)) allQuestions.addAll(levelQuestions[i]!);
    }
    allQuestions.shuffle();
    Navigator.push(context, MaterialPageRoute(builder: (context) => ReviewScreen(user: currentUser, questions: allQuestions.take(10).toList(), levelId: "daily_review")));
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: colors.last.withAlpha(77), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              Text(infoText, style: const TextStyle(color: Colors.white70, fontSize: 10)),
            ],
          ),
          Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(value: progress, backgroundColor: const Color(0x33000000), color: Colors.white, minHeight: 6),
          ),
          
          SizedBox(
            width: double.infinity,
            height: 32, 
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: btnColor, foregroundColor: Colors.black87, elevation: 0, padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(btnText, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}

// ===========================================================================
// PAINTER JALUR SEGMENTED (Aktif/Mati per Level & Animasi Kanan)
// ===========================================================================
class SegmentedGridPathPainter extends CustomPainter {
  final Color activeColor;
  final double animationValue;
  final int activeLevelsCount; 

  SegmentedGridPathPainter({
    required this.activeColor,
    required this.animationValue,
    required this.activeLevelsCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final activePaint = Paint()
      ..color = activeColor.withOpacity(0.8)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final inactivePaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double centerY = 30.0; 
    double columnWidth = size.width / 5;
    
    for (int i = 0; i < 4; i++) {
      double startX = (columnWidth * i) + (columnWidth / 2);
      double endX = (columnWidth * (i + 1)) + (columnWidth / 2);
      double margin = 28.0; 
      double lineStart = startX + margin;
      double lineEnd = endX - margin;

      bool isActive = i < (activeLevelsCount - 1);

      if (isActive) {
        // GAMBAR JALUR AKTIF BERGERAK (KIRI KE KANAN)
        double dashWidth = 10;
        double dashSpace = 8;
        double totalDash = dashWidth + dashSpace;
        
        // [FIX] Offset positif agar bergerak ke KANAN
        double phase = animationValue * totalDash; 
        
        Path path = Path();
        path.moveTo(lineStart, centerY);
        path.lineTo(lineEnd, centerY);

        Path dashPath = Path();
        for (PathMetric measure in path.computeMetrics()) {
          // [FIX] Mulai dari phase positif, dikurangi totalDash agar looping mulus
          double distance = phase - totalDash; 
          while (distance < measure.length) {
            double drawStart = max(0, distance);
            if (drawStart < measure.length) {
               dashPath.addPath(
                 measure.extractPath(drawStart, distance + dashWidth),
                 Offset.zero
               );
            }
            distance += totalDash;
          }
        }
        canvas.drawPath(dashPath, activePaint);

      } else {
        // GAMBAR JALUR MATI (DIAM)
        double dashWidth = 6;
        double dashSpace = 10;
        double currentX = lineStart;
        
        while (currentX < lineEnd) {
          canvas.drawLine(
            Offset(currentX, centerY),
            Offset(min(currentX + dashWidth, lineEnd), centerY),
            inactivePaint,
          );
          currentX += dashWidth + dashSpace;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant SegmentedGridPathPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || 
           oldDelegate.activeLevelsCount != activeLevelsCount;
  }
}