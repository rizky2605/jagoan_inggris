import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math; // Untuk animasi flip

import '../../models/word_model.dart';
import '../../core/services/vocabulary_service.dart';

class VocabularyScreen extends StatefulWidget {
  // Tambahkan parameter ini agar bisa menerima list kata manual (misal dari Daily Learning)
  final List<WordModel>? overrideWords; 

  const VocabularyScreen({super.key, this.overrideWords});

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
      
      // LOGIKA UTAMA: Pilih Data Source
      // Jika overrideWords ada, pakai itu. Jika tidak, ambil dari Database (Stream).
      body: widget.overrideWords != null 
          ? _buildContent(widget.overrideWords!) 
          : StreamBuilder<List<WordModel>>(
              stream: _vocabService.getDueWords(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
                }

                if (snapshot.hasError) {
                   return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
                }

                List<WordModel> words = snapshot.data ?? [];
                return _buildContent(words);
              },
            ),
    );
  }

  // Widget Konten Utama (Dipisah agar bisa dipakai oleh Stream maupun Override)
  Widget _buildContent(List<WordModel> words) {
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
              "Tidak ada kartu untuk direview saat ini.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
              child: const Text("KEMBALI KE STORY", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
            
            // [DEBUG ONLY]
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
        // Progress Bar
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

        // TOMBOL AKSI
        if (_isFlipped)
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Tombol Lupa (Merah)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _processReview(currentWord, false),
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
                    onPressed: () => _processReview(currentWord, true),
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
          const Padding(
            padding: EdgeInsets.all(30.0),
            child: Text("Ketuk kartu untuk melihat arti", style: TextStyle(color: Colors.white54)),
          ),
      ],
    );
  }

  void _processReview(WordModel word, bool remembered) async {
    // Jika ini mode override (manual list), kita hapus dari list lokal saja (UI Only)
    if (widget.overrideWords != null) {
       setState(() {
         _isFlipped = false;
         widget.overrideWords!.remove(word); // Hapus kata yang sudah direview dari list sementara
       });
       if (widget.overrideWords!.isEmpty) {
          Navigator.pop(context); // Kembali jika habis
       }
       return;
    }

    // Jika mode normal (Database), update ke Firestore
    setState(() => _isFlipped = false);
    await _vocabService.processWordReview(uid, word, remembered);
    
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
  
  // Fungsi Debug (Sudah Diperbaiki)
  void _addDummyWord() {
     _vocabService.addWord(uid, WordModel(
        id: "", 
        word: "Ephemeral", 
        meaning: "Sementara / Singkat", 
        pronunciation: "/əˈfem.ər.əl/", 
        category: "Adjective", 
        exampleSentence: "Fashion trends are ephemeral.", 
        mnemonic: "Ingat 'FM' (Radio). Lagu di radio itu EPHEMERAL (sebentar/lewat saja).", // <--- SUDAH DITAMBAHKAN
        nextReview: DateTime.now().subtract(const Duration(days: 1)) 
     ));
  }

  // --- DESAIN KARTU DEPAN ---
  Widget _buildFrontCard(WordModel word) {
    return Container(
      key: const ValueKey(false),
      width: 300,
      height: 450,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.cyanAccent, width: 2),
        boxShadow: const [BoxShadow(color: Color(0x4D18FFFF), blurRadius: 20)],
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
            word.category,
            style: const TextStyle(color: Colors.cyanAccent, fontSize: 14, letterSpacing: 2),
          ),
          const SizedBox(height: 20),
          const Icon(Icons.volume_up_rounded, color: Colors.white54),
          Text(word.pronunciation, style: const TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }

  // --- DESAIN KARTU BELAKANG ---
  Widget _buildBackCard(WordModel word) {
    return Container(
      key: const ValueKey(true),
      width: 300,
      height: 450,
      decoration: BoxDecoration(
        color: const Color(0xFF2A0045),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFBD00FF), width: 2),
        boxShadow: const [BoxShadow(color: Color(0x4DBD00FF), blurRadius: 20)],
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
            
            Text(
              "\"${word.exampleSentence}\"",
              style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 20),
            
            // --- TAMPILAN MNEMONIC (Jembatan Keledai) ---
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x4DFFC107))
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
                    word.mnemonic, // <--- Data Mnemonic Ditampilkan Di Sini
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