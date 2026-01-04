import 'package:flutter/material.dart';
import '../../models/word_model.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  final List<WordModel> _words = dailyVocabList; // Ambil dari model

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0025), // Background Gelap
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Kosa Kata Harian", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Indikator Progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / _words.length,
              backgroundColor: Colors.white10,
              color: const Color(0xFFBD00FF), // Ungu Neon
              minHeight: 6,
            ),
          ),
          
          Text("${_currentIndex + 1} / ${_words.length}", style: const TextStyle(color: Colors.white54)),

          // Area Flashcard
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // User harus klik tombol, ga bisa swipe sembarangan
              itemCount: _words.length,
              itemBuilder: (context, index) {
                return _buildFlashCard(_words[index]);
              },
            ),
          ),

          // Tombol Navigasi Bawah
          Padding(
            padding: const EdgeInsets.all(30),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  if (_currentIndex < _words.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300), 
                      curve: Curves.easeInOut
                    );
                    setState(() => _currentIndex++);
                  } else {
                    // Selesai belajar
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Hebat! Kosa kata hari ini selesai."), backgroundColor: Colors.green),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 10,
                  shadowColor: Colors.cyanAccent.withOpacity(0.5),
                ),
                child: Text(
                  _currentIndex < _words.length - 1 ? "LANJUT" : "SELESAI", 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Desain Kartu Kata
  Widget _buildFlashCard(WordModel word) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2A0045),
            Colors.black.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(color: const Color(0xFFBD00FF).withOpacity(0.2), blurRadius: 30, spreadRadius: 5)
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Kategori (Badge Kecil)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(word.category.toUpperCase(), style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, letterSpacing: 1.5)),
          ),
          
          const SizedBox(height: 40),

          // Kata Utama (Inggris)
          Text(
            word.word,
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          
          // Cara Baca
          Text(
            word.pronunciation,
            style: const TextStyle(color: Colors.white54, fontSize: 16, fontStyle: FontStyle.italic),
          ),

          const Divider(color: Colors.white12, height: 60),

          // Arti (Indonesia)
          Text(
            word.meaning,
            style: const TextStyle(color: Color(0xFFBD00FF), fontSize: 24, fontWeight: FontWeight.bold), // Warna Ungu
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 30),

          // Contoh Kalimat
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white10)
            ),
            child: Text(
              "\"${word.exampleSentence}\"",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}