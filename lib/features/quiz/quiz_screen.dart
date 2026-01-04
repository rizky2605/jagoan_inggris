import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../models/question_model.dart';
import '../../models/level_model.dart';
import '../../models/user_model.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  final LevelModel level;
  final UserModel user;

  const QuizScreen({super.key, required this.level, required this.user});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  // --- STATE PERMAINAN ---
  int _currentIndex = 0;
  double _monsterHealth = 1.0;
  int _score = 0;
  bool _isAnswered = false;

  // Data Soal Dummy (Level 1)
  final List<QuestionModel> _questions = level1Questions;

  // --- LOGIKA MENJAWAB ---
  void _answerQuestion(int selectedIndex) {
    if (_isAnswered) return;

    setState(() {
      _isAnswered = true;
    });

    bool isCorrect = selectedIndex == _questions[_currentIndex].correctIndex;

    if (isCorrect) {
      setState(() {
        _score++;
        _monsterHealth -= (1.0 / _questions.length);
        if (_monsterHealth < 0) _monsterHealth = 0;
      });
    }

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (_currentIndex < _questions.length - 1) {
        setState(() {
          _currentIndex++;
          _isAnswered = false;
        });
      } else {
        _showVictoryDialog();
      }
    });
  }

  void _showVictoryDialog() {
    // Pindah ke layar hasil untuk memproses hadiah
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          score: _score,
          totalQuestions: _questions.length,
          levelId: widget.level.id,
          user: widget.user,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    QuestionModel currentQ = _questions[_currentIndex];
    final pinkNeon = const Color(0xFFFF66C4);
    final cyanNeon = Colors.cyanAccent;

    return Scaffold(
      body: Stack(
        children: [
          // 1. BACKGROUND
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/bg_stars.jpg"), // Pastikan file ini ada
                fit: BoxFit.cover,
              ),
              color: Color(0xFF0F0025), // Fallback warna
            ),
          ),

          // 2. KONTEN UTAMA
          SafeArea(
            child: Column(
              children: [
                _buildHeader(widget.user),
                const SizedBox(height: 10),

                // PROGRESS BAR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      Text("Soal ${_currentIndex + 1}/${_questions.length}", style: TextStyle(color: pinkNeon)),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: (_currentIndex + 1) / _questions.length,
                          backgroundColor: Colors.white10,
                          color: pinkNeon,
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),

                // --- AREA BATTLE (Tengah) ---
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10), // Kurangi padding vertikal
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center, // Ubah ke Center agar sejajar
                      children: [
                        // KIRI: AVATAR PEMAIN
                        Expanded(
                          flex: 2,
                          child: _buildAvatarWithGlow(
                            // PERBAIKAN: Gunakan file avatar default jika bow tidak ada
                            'assets/models/avatar_default.glb', 
                            cyanNeon,
                          ),
                        ),
                        
                        // TENGAH: KOTAK SOAL
                        Expanded(
                          flex: 3,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: pinkNeon, width: 2),
                                  boxShadow: [
                                    BoxShadow(color: pinkNeon.withOpacity(0.3), blurRadius: 15, spreadRadius: 2)
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    const Text("Pilih kata yang tepat:", style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    const SizedBox(height: 10),
                                    Text(
                                      currentQ.question,
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              // TOMBOL JAWABAN
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly, // SpaceEvenly agar rapi
                                children: List.generate(currentQ.options.length, (index) {
                                  Color borderColor = cyanNeon;
                                  Color shadowColor = cyanNeon.withOpacity(0.3);
                                  
                                  if (_isAnswered) {
                                    if (index == currentQ.correctIndex) {
                                      borderColor = Colors.greenAccent;
                                      shadowColor = Colors.greenAccent.withOpacity(0.5);
                                    } else {
                                      borderColor = Colors.redAccent;
                                      shadowColor = Colors.redAccent.withOpacity(0.5);
                                    }
                                  } 

                                  return _buildAnswerButton(
                                    currentQ.options[index],
                                    index,
                                    borderColor,
                                    shadowColor,
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),

                        // KANAN: MONSTER
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Column(
                                  children: [
                                    Text("HP: ${(_monsterHealth * 100).toInt()}%", style: TextStyle(color: pinkNeon, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(5),
                                      child: LinearProgressIndicator(
                                        value: _monsterHealth,
                                        backgroundColor: Colors.white10,
                                        color: pinkNeon,
                                        minHeight: 6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 5),
                              // Model Monster (Pastikan nama file benar, kalau monster.glb ga ada pake avatar_default.glb dulu buat tes)
                              _buildAvatarWithGlow(
                                'assets/models/monster.glb', 
                                cyanNeon,
                                isMonster: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // HEADER PROFIL
  Widget _buildHeader(UserModel user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black.withOpacity(0.4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white24),
            ),
            child: Text("Lv. ${user.level}", style: const TextStyle(color: Colors.white, fontSize: 11)),
          ),
          const SizedBox(width: 8),
          CircleAvatar(backgroundColor: Colors.purple, radius: 12, child: Text(user.username[0].toUpperCase(), style: const TextStyle(fontSize: 10))),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.username, style: const TextStyle(color: Colors.white, fontSize: 11)),
                const SizedBox(height: 2),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (user.currentXp / user.maxXp).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[800],
                    color: const Color(0xFFFF66C4),
                    minHeight: 3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Row(children: [const Icon(Icons.monetization_on, color: Colors.amber, size: 16), const SizedBox(width: 2), Text("${user.gold}", style: const TextStyle(color: Colors.white, fontSize: 11))]),
        ],
      ),
    );
  }

  // --- WIDGET HELPER: AVATAR (PERBAIKAN POSISI) ---
  Widget _buildAvatarWithGlow(String modelPath, Color glowColor, {bool isMonster = false}) {
    // Gunakan LayoutBuilder untuk memastikan model tau ukuran wadahnya
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.center, // Ubah ke Center agar di tengah vertikal
          clipBehavior: Clip.none, // Izinkan glow keluar sedikit dari batas
          children: [
            // Cincin Glow (Diposisikan di kaki model)
            Positioned(
              bottom: 20, // Naikkan sedikit dari dasar
              child: Container(
                width: 100, // Kecilkan sedikit agar proporsional
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: glowColor, width: 2),
                  boxShadow: [BoxShadow(color: glowColor.withOpacity(0.5), blurRadius: 15, spreadRadius: 2)],
                ),
              ),
            ),
            
            // Model 3D
            SizedBox(
              height: 200, // Tentukan tinggi pasti agar tidak 'floating' sembarangan
              width: 150,
              child: ModelViewer(
                src: modelPath,
                autoRotate: isMonster,
                cameraControls: false, // Matikan kontrol agar user tidak geser2 posisi
                backgroundColor: Colors.transparent,
                disableZoom: true, // Matikan zoom agar posisi tetap
              ),
            ),
          ],
        );
      }
    );
  }

  // TOMBOL JAWABAN
  Widget _buildAnswerButton(String text, int index, Color borderColor, Color shadowColor) {
    return GestureDetector(
      onTap: () => _answerQuestion(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 80, // Perkecil lebar tombol
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: shadowColor, blurRadius: 10, spreadRadius: 1)],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}