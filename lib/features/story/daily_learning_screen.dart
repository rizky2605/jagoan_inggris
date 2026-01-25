import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../models/word_model.dart';
import '../../core/services/vocabulary_service.dart';
import '../../core/services/firestore_service.dart'; 
import '../../core/constants/vocabulary_data.dart';

class DailyLearningScreen extends StatefulWidget {
  const DailyLearningScreen({super.key});

  @override
  State<DailyLearningScreen> createState() => _DailyLearningScreenState();
}

class _DailyLearningScreenState extends State<DailyLearningScreen> {
  final VocabularyService _vocabService = VocabularyService();
  final FirestoreService _firestoreService = FirestoreService(); 
  final PageController _pageController = PageController();
  final FlutterTts flutterTts = FlutterTts();
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  
  List<WordModel> _dailyWords = []; 
  bool _isLoading = true;
  int _currentIndex = 0;
  bool _isQuizMode = false;
  int _quizScore = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadNewWords();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  Future<void> _loadNewWords() async {
    setState(() => _isLoading = true);
    
    List<WordModel> newBatch = await _vocabService.fetchNewDailyBatch(uid);
    
    if (!mounted) return;

    setState(() {
      _dailyWords = newBatch;
      _isLoading = false;
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

  Future<void> _finishDailyLesson() async {
    setState(() => _isSaving = true);
    
    await _vocabService.saveDailyBatch(uid, _dailyWords); 

    await _firestoreService.updateDailyStats(
      uid: uid,
      wordsLearned: _dailyWords.length, 
    );

    setState(() => _isSaving = false);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2A2A3A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.cyanAccent)),
          title: const Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber),
              SizedBox(width: 10),
              Text("Batch Selesai!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            "Skor Kuis: $_quizScore/${_dailyWords.length}\n\nIngin lanjut menambah hafalan baru?", 
            style: const TextStyle(color: Colors.white70)
          ),
          actions: [
            TextButton(
              child: const Text("CUKUP DULU", style: TextStyle(color: Colors.white54)),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); 
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent, 
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
              ),
              child: const Text("BELAJAR 5 KATA LAGI", style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(context); 
                _loadNewWords(); 
              },
            ),
          ],
          actionsAlignment: MainAxisAlignment.spaceBetween,
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
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.school, size: 80, color: Colors.amber),
                const SizedBox(height: 20),
                const Text("Luar Biasa!", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text(
                  "Kamu sudah mempelajari SEMUA kata yang ada di database kami (60+ Kata)!\n\nTunggu update berikutnya untuk kata baru ya.", 
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70)
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
                  child: const Text("KEMBALI KE MENU"),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0025),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(_isQuizMode ? "Mini Quiz" : "Belajar Kata Baru", style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea( // Tambahkan SafeArea
        child: _isSaving 
            ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
            : (_isQuizMode ? _buildQuizUI() : _buildLearningUI()),
      ),
    );
  }

  // --- TAMPILAN 1: BELAJAR (LEARNING PHASE) ---
  Widget _buildLearningUI() {
    return Column(
      children: [
        LinearProgressIndicator(
          value: (_currentIndex + 1) / _dailyWords.length,
          color: Colors.cyanAccent,
          backgroundColor: Colors.white10,
          minHeight: 6,
        ),
        
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), 
            itemCount: _dailyWords.length,
            itemBuilder: (context, index) {
              final word = _dailyWords[index];
              return SingleChildScrollView( 
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // KARTU KATA
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2C),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
                          boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.1), blurRadius: 20)],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                              child: Text(word.category.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1.5)),
                            ),
                            const SizedBox(height: 20),
                            Text(word.word, style: GoogleFonts.poppins(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            
                            // Pronunciation & Speaker
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(word.pronunciation, style: const TextStyle(color: Colors.white54, fontStyle: FontStyle.italic)),
                                const SizedBox(width: 10),
                                IconButton(
                                  onPressed: () => _speak(word.word),
                                  icon: const Icon(Icons.volume_up_rounded, color: Colors.cyanAccent),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                )
                              ],
                            ),
                            
                            const Divider(color: Colors.white12, height: 40),
                            Text(word.meaning, style: GoogleFonts.poppins(color: Colors.cyanAccent, fontSize: 28, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // KARTU JEMBATAN KELEDAI (MNEMONIC)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A3A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.amber.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                                SizedBox(width: 8),
                                Text("Cara Mengingat:", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              word.mnemonic,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      Text("\"${word.exampleSentence}\"", style: const TextStyle(color: Colors.white38, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                elevation: 10,
                shadowColor: Colors.cyanAccent.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text("SAYA SUDAH PAHAM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        )
      ],
    );
  }

  // --- TAMPILAN 2: KUIS (TESTING PHASE - LANDSCAPE FRIENDLY) ---
  Widget _buildQuizUI() {
    final word = _dailyWords[_currentIndex];
    
    List<String> options = [word.meaning];
    var allWords = VocabularyData.masterWordBank;
    var distractions = allWords.where((w) => w.meaning != word.meaning).toList()..shuffle();
    options.addAll(distractions.take(3).map((w) => w.meaning));
    options.shuffle();

    // [FIX] Gunakan SingleChildScrollView agar aman di Landscape
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Soal ${_currentIndex + 1}/${_dailyWords.length}", style: const TextStyle(color: Colors.white54)),
              Text("Skor: $_quizScore", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / _dailyWords.length,
              color: Colors.purpleAccent,
              backgroundColor: Colors.white10,
              minHeight: 8,
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Kartu Pertanyaan
          const Text("Apa arti dari:", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          Text(word.word, style: GoogleFonts.poppins(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          
          IconButton(
            onPressed: () => _speak(word.word),
            icon: const Icon(Icons.volume_up_rounded, color: Colors.white24),
          ),
          
          const SizedBox(height: 30),
          
          // Grid/List Pilihan Jawaban
          // Gunakan Column agar fleksibel scroll
          ...options.map((opt) => Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _answerQuiz(opt == word.meaning),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1E2C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: const BorderSide(color: Colors.white12),
                  ),
                  elevation: 0,
                ),
                child: Text(opt, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
              ),
            ),
          )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}