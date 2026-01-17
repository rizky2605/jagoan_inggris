import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math; // Untuk animasi flip

import '../../models/word_model.dart';
import '../../core/services/vocabulary_service.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  final VocabularyService _vocabService = VocabularyService();
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  
  // State Kartu
  bool _isFlipped = false; // Apakah kartu sedang membalik (lihat arti)?
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0025),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Bank Kosa Kata", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<WordModel>>(
        stream: _vocabService.getDueWords(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
          }

          if (snapshot.hasError) {
             return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
          }

          List<WordModel> words = snapshot.data ?? [];

          // 1. Jika tidak ada kata yang perlu direview
          if (words.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 80, color: Colors.greenAccent),
                  const SizedBox(height: 20),
                  const Text(
                    "Semua kata aman!",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Kamu sudah mempelajari semua kata hari ini.\nKembali lagi besok ya!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
                    child: const Text("KEMBALI KE STORY", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                  
                  // [DEBUG ONLY] Tombol Tambah Kata Dummy (Biar bisa ngetes)
                  const SizedBox(height: 20),
                  TextButton(
                     onPressed: () => _addDummyWord(),
                     child: const Text("Debug: Tambah Kata Dummy", style: TextStyle(color: Colors.white24))
                  )
                ],
              ),
            );
          }

          // 2. Ambil kata paling atas (antrian pertama)
          WordModel currentWord = words.first;

          return Column(
            children: [
              // Progress Bar (Sisa kata hari ini)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Antrian: ${words.length}", style: const TextStyle(color: Colors.cyanAccent)),
                    Text("Level Ingatan: ${currentWord.box}/5", style: const TextStyle(color: Colors.amber)),
                  ],
                ),
              ),

              // AREA KARTU (Flashcard)
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isFlipped = !_isFlipped; // Balik kartu
                      });
                    },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        final rotateAnim = Tween(begin: math.pi, end: 0.0).animate(animation);
                        return AnimatedBuilder(
                          animation: rotateAnim,
                          child: child,
                          builder: (context, widget) {
                            final isUnder = (ValueKey(_isFlipped) != widget?.key);
                            var tilt = ((animation.value - 0.5).abs() - 0.5) * 0.003;
                            tilt *= isUnder ? -1.0 : 1.0;
                            final value = isUnder ? math.min(rotateAnim.value, math.pi / 2) : rotateAnim.value;
                            return Transform(
                              transform: Matrix4.rotationY(value)..setEntry(3, 0, tilt),
                              alignment: Alignment.center,
                              child: widget,
                            );
                          },
                        );
                      },
                      // TAMPILAN DEPAN vs BELAKANG
                      child: _isFlipped 
                        ? _buildBackCard(currentWord) // Jawaban (Arti)
                        : _buildFrontCard(currentWord), // Soal (Kata Inggris)
                    ),
                  ),
                ),
              ),

              // TOMBOL AKSI (Hanya muncul jika kartu sudah dibalik)
              if (_isFlipped)
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Tombol Lupa (Merah)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _processReview(currentWord, false);
                          },
                          icon: const Icon(Icons.close),
                          label: const Text("LUPA (Ulang)"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Tombol Ingat (Hijau)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _processReview(currentWord, true);
                          },
                          icon: const Icon(Icons.check),
                          label: const Text("INGAT (Lanjut)"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Petunjuk jika belum dibalik
                const Padding(
                  padding: EdgeInsets.all(30.0),
                  child: Text("Ketuk kartu untuk melihat arti", style: TextStyle(color: Colors.white54)),
                ),
            ],
          );
        },
      ),
    );
  }

  void _processReview(WordModel word, bool remembered) async {
    // Reset flip biar kartu berikutnya mulai dari depan
    setState(() => _isFlipped = false);
    
    // Simpan ke database
    await _vocabService.processWordReview(uid, word, remembered);
    
    // Feedback visual
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(remembered ? "Bagus! Kata disimpan." : "Tidak apa, kita ulang lagi besok."),
          backgroundColor: remembered ? Colors.green : Colors.orange,
          duration: const Duration(milliseconds: 800),
        )
      );
    }
  }
  
  // Fungsi Debug untuk nambah kata kalau database kosong
  void _addDummyWord() {
     _vocabService.addWord(uid, WordModel(
        id: "", 
        word: "Ephemeral", 
        meaning: "Sementara / Singkat", 
        pronunciation: "/əˈfem.ər.əl/", 
        category: "Adjective", 
        exampleSentence: "Fashion trends are ephemeral.", 
        // --- PERBAIKAN UTAMA DI SINI (Menambahkan parameter mnemonic) ---
        mnemonic: "Ingat 'FM' (Radio). Lagu di radio itu EPHEMERAL (sebentar/lewat saja).",
        nextReview: DateTime.now().subtract(const Duration(days: 1)) // Buat 'kemarin' biar langsung muncul
     ));
  }

  // --- DESAIN KARTU DEPAN (INGGRIS) ---
  Widget _buildFrontCard(WordModel word) {
    return Container(
      key: const ValueKey(false),
      width: 300,
      height: 450,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.cyanAccent, width: 2),
        boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 20)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.translate, size: 50, color: Colors.white24),
          const SizedBox(height: 30),
          Text(
            word.word,
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            word.category, // Noun, Verb, etc
            style: const TextStyle(color: Colors.cyanAccent, fontSize: 14, letterSpacing: 2),
          ),
          const SizedBox(height: 20),
          // Icon audio kecil (hiasan)
          const Icon(Icons.volume_up_rounded, color: Colors.white54),
          Text(word.pronunciation, style: const TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }

  // --- DESAIN KARTU BELAKANG (ARTI) ---
  Widget _buildBackCard(WordModel word) {
    return Container(
      key: const ValueKey(true),
      width: 300,
      height: 450,
      decoration: BoxDecoration(
        color: const Color(0xFF2A0045), // Warna beda biar kerasa dibalik
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFBD00FF), width: 2),
        boxShadow: [BoxShadow(color: const Color(0xFFBD00FF).withOpacity(0.3), blurRadius: 20)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Artinya:", style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 10),
            Text(
              word.meaning,
              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const Divider(color: Colors.white24, height: 30),
            
            // Contoh Kalimat
            Text(
              "\"${word.exampleSentence}\"",
              style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 20),
            
            // --- JEMBATAN KELEDAI (TIPS) ---
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.3))
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lightbulb, color: Colors.amber, size: 16),
                      SizedBox(width: 5),
                      Text("Tips Ingat:", style: TextStyle(color: Colors.amber, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    word.mnemonic,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}