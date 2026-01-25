// lib/core/services/vocabulary_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/word_model.dart';
import '../constants/vocabulary_data.dart'; // Import Data Bank

class VocabularyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ===========================================================================
  // 1. STATISTIK (Untuk Menu)
  // ===========================================================================

  // Hitung jumlah kata yang perlu direview (Next Review <= Sekarang)
  Stream<int> getDueCountStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('vocabulary')
        .where('next_review', isLessThanOrEqualTo: DateTime.now().toIso8601String())
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Hitung total kata yang sudah dipelajari
  Stream<int> getTotalLearnedStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('vocabulary')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ===========================================================================
  // 2. FITUR UTAMA (Review & Belajar)
  // ===========================================================================

  // Ambil daftar kata yang waktunya direview
Stream<List<WordModel>> getDueWords(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('vocabulary')
        .where('next_review', isLessThanOrEqualTo: DateTime.now().toIso8601String())
        .orderBy('next_review')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => WordModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // [BARU] Ambil SEMUA kata yang sudah dipelajari (Mode Latihan/Cramming)
  Stream<List<WordModel>> getAllLearnedWords(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('vocabulary')
        .orderBy('word') // Urutkan abjad atau berdasarkan 'box'
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => WordModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
  // Proses setelah review (Ingat/Lupa) -> Update Box & Tanggal
  Future<void> processWordReview(String uid, WordModel word, bool remembered) async {
    int newBox = remembered ? (word.box + 1).clamp(1, 5) : 1;
    
    // Interval hari berdasarkan Box (Leitner System)
    // Box 1: 1 hari, Box 2: 3 hari, Box 3: 7 hari, Box 4: 14 hari, Box 5: 30 hari
    int intervalDays = 1;
    if (newBox == 2) intervalDays = 3;
    if (newBox == 3) intervalDays = 7;
    if (newBox == 4) intervalDays = 14;
    if (newBox == 5) intervalDays = 30;

    await _db
        .collection('users')
        .doc(uid)
        .collection('vocabulary')
        .doc(word.id)
        .update({
      'box': newBox,
      'next_review': DateTime.now().add(Duration(days: intervalDays)).toIso8601String(),
    });
  }

  // ===========================================================================
  // 3. FITUR HARIAN (Daily Learning)
  // ===========================================================================

  // Mengambil 5 kata baru secara acak yang BELUM pernah dipelajari user
  Future<List<WordModel>> fetchNewDailyBatch(String uid) async {
    // 1. Ambil daftar kata yang SUDAH dipelajari user dari Firestore
    // Tips: Untuk efisiensi bandwidth jika data besar, idealnya hanya ambil field 'word' saja.
    // Tapi Firestore klien standar mengambil full document.
    final userVocabSnapshot = await _db.collection('users').doc(uid).collection('vocabulary').get();
    
    // Buat Set berisi kata-kata yang sudah dipelajari agar pencarian cepat (O(1))
    final learnedWords = userVocabSnapshot.docs.map((doc) => doc['word'] as String).toSet();

    // 2. Filter dari MASTER DATA (vocabulary_data.dart)
    // Hanya ambil kata yang TIDAK ADA di learnedWords
    List<WordModel> availableWords = VocabularyData.masterWordBank
        .where((word) => !learnedWords.contains(word.word))
        .toList();

    // 3. Acak dan ambil 5 kata
    availableWords.shuffle();
    return availableWords.take(5).toList();
  }

  // Simpan 5 kata hasil belajar ke database user
  Future<void> saveDailyBatch(String uid, List<WordModel> words) async {
    final batch = _db.batch();
    for (var word in words) {
      // Gunakan ID kata yang konsisten jika ada, atau auto-id
      // Agar lebih rapi, kita biarkan auto-id dari Firestore untuk user collection
      // Tapi kita simpan 'original_id' jika perlu tracking ke master bank.
      var docRef = _db.collection('users').doc(uid).collection('vocabulary').doc(); 
      
      // Pastikan tanggal review pertama adalah BESOK (bukan sekarang)
      WordModel newWord = WordModel(
        id: docRef.id,
        word: word.word,
        meaning: word.meaning,
        pronunciation: word.pronunciation,
        category: word.category,
        exampleSentence: word.exampleSentence,
        mnemonic: word.mnemonic,
        box: 1,
        nextReview: DateTime.now().add(const Duration(days: 1)) // Review pertama besok
      );

      batch.set(docRef, newWord.toMap());
    }
    await batch.commit();
  }

  // ===========================================================================
  // 4. HELPER (Untuk Admin / Debug)
  // ===========================================================================

  // Menambah satu kata manual ke user (Misal untuk testing)
  Future<void> addWord(String uid, WordModel word) async {
    await _db.collection('users').doc(uid).collection('vocabulary').add(word.toMap());
  }
}