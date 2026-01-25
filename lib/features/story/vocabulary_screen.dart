import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math; 
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/word_model.dart';
import '../../core/services/vocabulary_service.dart';

class VocabularyScreen extends StatefulWidget {
  final List<WordModel>? overrideWords; 
  final bool isPracticeMode; 

  const VocabularyScreen({
    super.key, 
    this.overrideWords,
    this.isPracticeMode = false, 
  });

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  final VocabularyService _vocabService = VocabularyService();
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  final FlutterTts flutterTts = FlutterTts();
  
  bool _isFlipped = false; 
  final Set<String> _processedWordIds = {};

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  // Helper untuk warna level hafalan (Box)
  Color _getLevelColor(int box) {
    if (box <= 1) return Colors.redAccent;      // Baru belajar
    if (box <= 3) return Colors.orangeAccent;   // Lumayan
    return Colors.greenAccent;                  // Master
  }

  // Helper untuk teks level
  String _getLevelText(int box) {
    if (box == 1) return "Baru";
    if (box == 5) return "Master";
    return "Lv. $box";
  }
  
  @override
  Widget build(BuildContext context) {
    String title = "Review Harian";
    if (widget.overrideWords != null) title = "Review Cepat";
    else if (widget.isPracticeMode) title = "Latihan Bebas";

    return Scaffold(
      backgroundColor: const Color(0xFF0F0025),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      
      body: widget.overrideWords != null 
          ? _buildContent(widget.overrideWords!) 
          : StreamBuilder<List<WordModel>>(
              stream: widget.isPracticeMode 
                  ? _vocabService.getAllLearnedWords(uid) 
                  : _vocabService.getDueWords(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
                }
                if (snapshot.hasError) {
                   return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
                }

                List<WordModel> words = snapshot.data ?? [];
                words = words.where((w) => !_processedWordIds.contains(w.id)).toList();

                return _buildContent(words);
              },
            ),
    );
  }

  Widget _buildContent(List<WordModel> words) {
    // 1. KONDISI KOSONG (SELESAI)
    if (words.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.isPracticeMode ? Icons.check_circle : Icons.task_alt, 
                size: 80, 
                color: widget.isPracticeMode ? Colors.purpleAccent : Colors.greenAccent
              ),
              const SizedBox(height: 20),
              Text(
                widget.isPracticeMode ? "Latihan Selesai!" : "Target Tercapai!",
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                widget.isPracticeMode 
                    ? "Semua kata sudah direview."
                    : "Tidak ada kartu 'jatuh tempo'.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 30),
              
              if (!widget.isPracticeMode && widget.overrideWords == null) ...[
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context, 
                      MaterialPageRoute(builder: (context) => const VocabularyScreen(isPracticeMode: true))
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                  ),
                  child: const Text("LATIHAN BEBAS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ]
            ],
          ),
        ),
      );
    }

    WordModel currentWord = words.first;

    // Layout Builder untuk Responsif
    return LayoutBuilder(
      builder: (context, constraints) {
        double maxHeight = constraints.maxHeight;
        double maxWidth = constraints.maxWidth;
        
        double cardWidth = maxWidth * 0.85;
        double cardHeight = maxHeight * 0.75; 

        if (cardWidth > 400) cardWidth = 400;
        
        return Column(
          children: [
            // --- [INFO BAR YANG DIPERBAIKI] ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // KIRI: SISA KARTU (Dulu: Antrian)
                  Row(
                    children: [
                      const Icon(Icons.filter_none, color: Colors.cyanAccent, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        "Sisa: ${words.length}", 
                        style: GoogleFonts.poppins(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.w600)
                      ),
                    ],
                  ),

                  // KANAN: LEVEL PENGUASAAN (Dulu: Box)
                  Row(
                    children: [
                      Text(
                        _getLevelText(currentWord.box), 
                        style: GoogleFonts.poppins(color: _getLevelColor(currentWord.box), fontSize: 12, fontWeight: FontWeight.w600)
                      ),
                      const SizedBox(width: 6),
                      // Visualisasi Bar Sinyal
                      Row(
                        children: List.generate(5, (index) {
                          return Container(
                            margin: const EdgeInsets.only(left: 2),
                            width: 4,
                            height: 8 + (index * 2), // Tinggi bertingkat
                            decoration: BoxDecoration(
                              color: index < currentWord.box ? _getLevelColor(currentWord.box) : Colors.white10,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      )
                    ],
                  ),
                ],
              ),
            ),

            // AREA KARTU UTAMA
            Expanded(
              child: Center(
                child: Dismissible(
                  key: Key(currentWord.id + (widget.isPracticeMode ? "_prac" : "")), 
                  direction: DismissDirection.horizontal,
                  onDismissed: (direction) {
                    bool remembered = direction == DismissDirection.startToEnd;
                    _processReview(currentWord, remembered);
                  },
                  background: _buildSwipeBackground(Colors.green, Icons.check_circle, "INGAT", Alignment.centerLeft),
                  secondaryBackground: _buildSwipeBackground(Colors.redAccent, Icons.cancel, "LUPA", Alignment.centerRight),

                  child: GestureDetector(
                    onTap: () => setState(() => _isFlipped = !_isFlipped),
                    child: SizedBox(
                      width: cardWidth,
                      height: cardHeight,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
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
                        child: _isFlipped 
                          ? _buildBackCard(currentWord) 
                          : _buildFrontCard(currentWord),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // FOOTER
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  if (!_isFlipped)
                    const Text("👆 Ketuk balik • ↔️ Geser nilai", style: TextStyle(color: Colors.white38, fontSize: 12))
                  else 
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () => _processReview(currentWord, false),
                          icon: const Icon(Icons.close, color: Colors.redAccent),
                          tooltip: "Lupa",
                        ),
                        const SizedBox(width: 20),
                        const Text("Geser atau Pilih", style: TextStyle(color: Colors.white24, fontSize: 10)),
                        const SizedBox(width: 20),
                        IconButton(
                          onPressed: () => _processReview(currentWord, true),
                          icon: const Icon(Icons.check, color: Colors.greenAccent),
                          tooltip: "Ingat",
                        ),
                      ],
                    )
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSwipeBackground(Color color, IconData icon, String label, Alignment alignment) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2), 
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 40),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14))
        ],
      ),
    );
  }

  void _processReview(WordModel word, bool remembered) async {
    setState(() {
      _isFlipped = false;
      if (widget.overrideWords != null) {
        widget.overrideWords!.remove(word);
      } else {
        _processedWordIds.add(word.id);
      }
    });

    if (widget.overrideWords != null && widget.overrideWords!.isEmpty) {
       Navigator.pop(context);
       return;
    }
    _vocabService.processWordReview(uid, word, remembered);
  }
  
  // --- WIDGET KARTU DEPAN ---
  Widget _buildFrontCard(WordModel word) {
    return Container(
      key: const ValueKey(false),
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.cyanAccent.withOpacity(0.1), blurRadius: 20, spreadRadius: 1),
          const BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
            child: Text(word.category.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 2)),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              word.word,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),
          Text(word.pronunciation, style: const TextStyle(color: Colors.white38, fontStyle: FontStyle.italic)),
          const Spacer(),
          
          IconButton(
            onPressed: () => _speak(word.word),
            icon: const Icon(Icons.volume_up_rounded, color: Colors.cyanAccent, size: 36),
            style: IconButton.styleFrom(
              backgroundColor: Colors.cyanAccent.withOpacity(0.1),
              padding: const EdgeInsets.all(12)
            ),
          ),
          const SizedBox(height: 10),
          const Text("Ketuk untuk arti", style: TextStyle(color: Colors.white24, fontSize: 10)),
        ],
      ),
    );
  }

  // --- WIDGET KARTU BELAKANG ---
  Widget _buildBackCard(WordModel word) {
    return Container(
      key: const ValueKey(true),
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF2A0045), Color(0xFF150025)]
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFBD00FF), width: 1.5),
        boxShadow: [
          BoxShadow(color: const Color(0xFFBD00FF).withOpacity(0.2), blurRadius: 20),
          const BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("ARTINYA", style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 2)),
            const SizedBox(height: 10),
            Text(
              word.meaning,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const Divider(color: Colors.white12, height: 30),
            Text(
              "\"${word.exampleSentence}\"",
              style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.amber.withOpacity(0.3))
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lightbulb, color: Colors.amber, size: 16),
                      SizedBox(width: 8),
                      Text("TIPS INGAT", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11)),
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
            ),
          ],
        ),
      ),
    );
  }
}