import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/word_model.dart';
import '../../core/services/vocabulary_service.dart';

class DailyLearningScreen extends StatefulWidget {
  const DailyLearningScreen({super.key});

  @override
  State<DailyLearningScreen> createState() => _DailyLearningScreenState();
}

class _DailyLearningScreenState extends State<DailyLearningScreen> {
  final VocabularyService _vocabService = VocabularyService();
  final PageController _pageController = PageController();
  
  // State
  int _currentIndex = 0;
  bool _isQuizMode = false;
  int _quizScore = 0;
  bool _isSaving = false;

  // --- DATA KATA HARIAN (Nanti bisa diambil dari Server) ---
  // Inilah 5 kata yang akan dipelajari hari ini
  final List<WordModel> _dailyWords = [
    WordModel(id: '', word: 'Abundant', pronunciation: '/əˈbʌn.dənt/', category: 'Adjective', meaning: 'Melimpah', 
      mnemonic: "Ingat 'A Bun Dance' (Roti Menari). Rotinya menari karena selainya MELIMPAH (Abundant).", 
      exampleSentence: "We have abundant food.", nextReview: DateTime.now()),
    WordModel(id: '', word: 'Gloomy', pronunciation: '/ˈɡluː.mi/', category: 'Adjective', meaning: 'Suram / Mendung', 
      mnemonic: "Ingat 'GLUE' (Lem). Kalau kaki kena lem, perasaan jadi GLOOMY (Suram/Sedih).", 
      exampleSentence: "The sky is gloomy.", nextReview: DateTime.now()),
    WordModel(id: '', word: 'Keen', pronunciation: '/kiːn/', category: 'Adjective', meaning: 'Tertarik / Tajam', 
      mnemonic: "Mirip nama 'IKIN'. Si Ikin sangat KEEN (Tertarik) belajar gitar.", 
      exampleSentence: "She is keen on music.", nextReview: DateTime.now()),
    WordModel(id: '', word: 'Candid', pronunciation: '/ˈkæn.dɪd/', category: 'Adjective', meaning: 'Jujur / Apa adanya', 
      mnemonic: "Mirip 'KANDIDAT'. Kandidat pemimpin harus CANDID (Jujur).", 
      exampleSentence: "To be candid, I dislike it.", nextReview: DateTime.now()),
    WordModel(id: '', word: 'Huge', pronunciation: '/hjuːdʒ/', category: 'Adjective', meaning: 'Sangat Besar', 
      mnemonic: "Bayangkan 'HIU'. Ikan Hiu itu badannya HUGE (Besar sekali).", 
      exampleSentence: "A huge mistake.", nextReview: DateTime.now()),
  ];

  // --- LOGIKA ALUR ---

  void _nextStep() {
    if (_currentIndex < _dailyWords.length - 1) {
      // Pindah ke kata berikutnya
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentIndex++);
    } else {
      // Kata habis, masuk ke Kuis
      setState(() {
        _isQuizMode = true;
        _currentIndex = 0;
      });
    }
  }

  void _answerQuiz(bool isCorrect) async {
    if (isCorrect) {
      // Kita gunakan variabel ini sekarang
      setState(() {
        _quizScore++; 
      });
    }

    if (_currentIndex < _dailyWords.length - 1) {
      setState(() => _currentIndex++);
    } else {
      await _finishDailyLesson();
    }
  }

  // 2. UPDATE DIALOG SELESAI (Tampilkan Skor)
  Future<void> _finishDailyLesson() async {
    setState(() => _isSaving = true);
    
    String uid = FirebaseAuth.instance.currentUser!.uid;
    await _vocabService.saveDailyBatch(uid, _dailyWords);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2A2A3A),
          title: const Text("Hafalan Selesai!", style: TextStyle(color: Colors.white)),
          // TAMPILKAN SKOR DI SINI AGAR VARIABEL TERPAKAI
          content: Text(
            "Skor Kuis: $_quizScore/${_dailyWords.length}\n\nKata-kata ini sudah masuk ke Bank Flashcard kamu.", 
            style: const TextStyle(color: Colors.white70)
          ),
          actions: [
            TextButton(
              child: const Text("OK, MANTAP", style: TextStyle(color: Colors.cyanAccent)),
              onPressed: () {
                Navigator.pop(context); 
                Navigator.pop(context); 
              },
            )
          ],
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
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
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
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
                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
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