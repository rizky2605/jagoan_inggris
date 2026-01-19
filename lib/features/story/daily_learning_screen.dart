import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/word_model.dart';
import '../../core/services/vocabulary_service.dart';
import 'vocabulary_screen.dart'; // Untuk navigasi ke Review

class DailyLearningScreen extends StatefulWidget {
  const DailyLearningScreen({super.key});

  @override
  State<DailyLearningScreen> createState() => _DailyLearningScreenState();
}

class _DailyLearningScreenState extends State<DailyLearningScreen> {
  final VocabularyService _vocabService = VocabularyService();
  final PageController _pageController = PageController();
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  
  List<WordModel> _dailyWords = []; // Data dinamis
  bool _isLoading = true;
  int _currentIndex = 0;
  bool _isQuizMode = false;
  int _quizScore = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadNewWords();
  }

  // --- 1. LOAD KATA DINAMIS ---
  Future<void> _loadNewWords() async {
    setState(() => _isLoading = true);
    List<WordModel> newBatch = await _vocabService.fetchNewDailyBatch(uid);
    
    setState(() {
      _dailyWords = newBatch;
      _isLoading = false;
      // Reset state lainnya
      _currentIndex = 0;
      _isQuizMode = false;
      _quizScore = 0;
      _isSaving = false;
    });
  }

  void _nextStep() {
    if (_currentIndex < _dailyWords.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentIndex++);
    } else {
      setState(() {
        _isQuizMode = true;
        _currentIndex = 0;
      });
    }
  }

  void _answerQuiz(bool isCorrect) async {
    if (isCorrect) setState(() => _quizScore++);

    if (_currentIndex < _dailyWords.length - 1) {
      setState(() => _currentIndex++);
    } else {
      await _finishDailyLesson();
    }
  }

  // --- 2. DIALOG PENYELESAIAN (DUA OPSI) ---
  Future<void> _finishDailyLesson() async {
    setState(() => _isSaving = true);
    await _vocabService.saveDailyBatch(uid, _dailyWords); // Simpan ke DB
    setState(() => _isSaving = false);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2A2A3A),
          title: const Text("Hafalan Selesai!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(
            "Skor Kuis: $_quizScore/${_dailyWords.length}\nKata-kata ini sudah disimpan.", 
            style: const TextStyle(color: Colors.white70)
          ),
          actions: [
            // TOMBOL 1: REVIEW KATA INI SAJA (Flashcard Mode khusus kata ini)
            TextButton(
              child: const Text("REVIEW 5 KATA INI", style: TextStyle(color: Colors.amber)),
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
                // Kirim list kata spesifik ke VocabularyScreen (Perlu update VocabularyScreen dikit)
                Navigator.pushReplacement(
                  context, 
                  MaterialPageRoute(builder: (context) => VocabularyScreen(overrideWords: _dailyWords))
                );
              },
            ),
            
            // TOMBOL 2: BELAJAR LAGI (Load Batch Baru)
            TextButton(
              child: const Text("BELAJAR 5 LAGI", style: TextStyle(color: Colors.cyanAccent)),
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
                _loadNewWords(); // Reload halaman dengan kata baru
              },
            ),

            // TOMBOL 3: KELUAR
            TextButton(
              child: const Text("SELESAI", style: TextStyle(color: Colors.white54)),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0025),
        body: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
      );
    }

    if (_dailyWords.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0025),
        appBar: AppBar(backgroundColor: Colors.transparent, leading: const BackButton(color: Colors.white)),
        body: const Center(child: Text("Hore! Semua kata sudah dipelajari.", style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0025),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(_isQuizMode ? "Mini Quiz" : "Belajar Kata Baru", style: const TextStyle(color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: _isSaving 
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : (_isQuizMode ? _buildQuizUI() : _buildLearningUI()),
    );
  }

  // ... (Gunakan Fungsi _buildLearningUI dan _buildQuizUI dari kode sebelumnya, tidak ada perubahan UI di bagian ini) ...
  // --- TAMPILAN 1: BELAJAR (LEARNING PHASE) ---
  Widget _buildLearningUI() {
    return Column(
      children: [
        // Indikator Progress
        LinearProgressIndicator(
          value: (_currentIndex + 1) / _dailyWords.length,
          color: Colors.cyanAccent,
          backgroundColor: Colors.white10,
        ),
        
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), // User harus klik tombol
            itemCount: _dailyWords.length,
            itemBuilder: (context, index) {
              final word = _dailyWords[index];
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // KARTU KATA
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0x0DFFFFFF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0x8018FFFF)),
                      ),
                      child: Column(
                        children: [
                          Text(word.word, style: GoogleFonts.poppins(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                          Text(word.pronunciation, style: const TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)),
                          const SizedBox(height: 20),
                          Text(word.meaning, style: GoogleFonts.poppins(color: Colors.cyanAccent, fontSize: 24, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // KARTU JEMBATAN KELEDAI (MNEMONIC)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A3A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0x4DFFC107)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.lightbulb, color: Colors.amber),
                              SizedBox(width: 8),
                              Text("Cara Mengingat:", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            word.mnemonic,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // CONTOH KALIMAT
                    Text("\"${word.exampleSentence}\"", style: const TextStyle(color: Colors.white38, fontStyle: FontStyle.italic)),
                  ],
                ),
              );
            },
          ),
        ),

        // TOMBOL LANJUT
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("SAYA SUDAH PAHAM", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        )
      ],
    );
  }

  // --- TAMPILAN 2: KUIS (TESTING PHASE) ---
  Widget _buildQuizUI() {
    final word = _dailyWords[_currentIndex];
    
    // Buat opsi jawaban (1 Benar + 2 Salah dari kata lain)
    List<String> options = [word.meaning];
    List<WordModel> distractions = List.from(_dailyWords)..remove(word)..shuffle();
    if (distractions.isNotEmpty) options.add(distractions[0].meaning);
    if (distractions.length > 1) options.add(distractions[1].meaning);
    options.shuffle();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text("Soal ${_currentIndex + 1}/${_dailyWords.length}", style: const TextStyle(color: Colors.white54)),
          const Spacer(),
          const Text("Apa arti dari:", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          Text(word.word, style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const Spacer(),
          
          ...options.map((opt) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _answerQuiz(opt == word.meaning),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1E2C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.white12),
                ),
                child: Text(opt),
              ),
            ),
          )),
          const Spacer(),
        ],
      ),
    );
  }
}