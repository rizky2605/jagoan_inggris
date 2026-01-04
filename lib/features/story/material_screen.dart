import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../models/level_model.dart';
import '../../models/user_model.dart'; // 1. Tambahkan Import ini
import '../quiz/quiz_screen.dart';

class MaterialScreen extends StatelessWidget {
  final LevelModel level;
  final UserModel user; // 2. Tambahkan variabel User

  // 3. Wajibkan user di constructor
  const MaterialScreen({
    super.key, 
    required this.level, 
    required this.user 
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Materi: ${level.title}", style: const TextStyle(color: Colors.white)),
      ),
      body: Stack(
        children: [
          // BACKGROUND
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F0025), Color(0xFF200040)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          // KONTEN UTAMA
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Text(
                    level.subtitle,
                    style: const TextStyle(
                      color: Colors.cyanAccent, 
                      fontSize: 24, 
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.cyanAccent, blurRadius: 10)]
                    ),
                  ),
                  const SizedBox(height: 20),

                  Expanded(
                    child: Row(
                      children: [
                        // AVATAR GURU
                        Expanded(
                          flex: 1,
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            child: const ModelViewer(
                              src: 'assets/models/avatar_default.glb', 
                              autoRotate: true,
                              cameraControls: true,
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                        ),

                        // PAPAN TULIS NEON
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.black..withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFBD00FF), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFBD00FF)..withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  spreadRadius: 1
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Penjelasan Singkat:",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const Divider(color: Colors.white24),
                                const SizedBox(height: 10),
                                
                                const Expanded(
                                  child: SingleChildScrollView(
                                    child: Text(
                                      "• Subject 'I' (Saya) pasangannya 'am'.\n\n"
                                      "• Subject 'You/We/They' pasangannya 'are'.\n\n"
                                      "• Subject 'He/She/It' pasangannya 'is'.\n",
                                      style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 15),
                                
                                // TOMBOL UJI PEMAHAMAN
                                SizedBox(
                                  width: double.infinity,
                                  height: 45,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // 4. Perbaikan Utama: Kirim User ke QuizScreen
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => QuizScreen(
                                            level: level, 
                                            user: user // <<-- ERROR HILANG DISINI
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.cyanAccent,
                                      foregroundColor: Colors.black,
                                      elevation: 10,
                                      shadowColor: Colors.cyanAccent,
                                    ),
                                    child: const Text("UJI PEMAHAMAN", style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                )
                              ],
                            ),
                          ),
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
    );
  }
}