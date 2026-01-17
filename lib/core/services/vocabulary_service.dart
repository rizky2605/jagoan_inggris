import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/word_model.dart';


class VocabularyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Mengambil kata yang JADWAL REVIEWNYA SUDAH TIBA (<= Hari Ini)
  Stream<List<WordModel>> getDueWords(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('vocabulary')
        .where('next_review', isLessThanOrEqualTo: DateTime.now().toIso8601String())
        .orderBy('next_review') // Urutkan dari yang paling lama tertunda
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => WordModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> saveDailyBatch(String uid, List<WordModel> words) async {
    final batch = _db.batch();
    
    for (var word in words) {
      // Buat referensi dokumen baru di koleksi vocabulary user
      var docRef = _db.collection('users').doc(uid).collection('vocabulary').doc();
      
      // Kita set data awal (Box 1, Review Besok)
      batch.set(docRef, word.toMap());
    }

    await batch.commit();
  }


  // Logika "Brain" - Menentukan nasib kata setelah direview
  Future<void> processWordReview(String uid, WordModel word, bool remembered) async {
    int newBox = word.box;
    DateTime newNextReview;

    if (remembered) {
      // Jika ingat, naik level (jarak review makin lama)
      newBox = (newBox + 1).clamp(1, 5); // Maksimal Box 5
    } else {
      // Jika lupa, reset ke Box 1 (harus sering direview lagi)
      newBox = 1;
    }

    // Hitung Jeda Hari Berdasarkan Box (Leitner System Sederhana)
    // Box 1: 1 hari, Box 2: 3 hari, Box 3: 7 hari, Box 4: 14 hari, Box 5: 30 hari
    int intervalDays = 1;
    switch (newBox) {
      case 2: intervalDays = 3; break;
      case 3: intervalDays = 7; break;
      case 4: intervalDays = 14; break;
      case 5: intervalDays = 30; break;
      default: intervalDays = 1;
    }

    newNextReview = DateTime.now().add(Duration(days: intervalDays));

    // Update ke Database
    await _db
        .collection('users')
        .doc(uid)
        .collection('vocabulary')
        .doc(word.id)
        .update({
      'box': newBox,
      'next_review': newNextReview.toIso8601String(),
      'last_reviewed': DateTime.now().toIso8601String(),
    });
    
    // Opsional: Tambah statistik harian user (Daily Word Count)
    if (remembered) {
      _db.collection('users').doc(uid).update({
        'daily_word_count': FieldValue.increment(1),
      });
    }
  }
  
  // Fungsi Helper untuk Menambah Kata Baru (Untuk Testing/Seed)
  Future<void> addWord(String uid, WordModel word) async {
    await _db.collection('users').doc(uid).collection('vocabulary').add(word.toMap());
  }
}