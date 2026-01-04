import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/word_model.dart';

class VocabularyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Ambil Kata yang PERLU direview HARI INI (atau kata baru)
  Stream<List<WordModel>> getDueWords(String uid) {
    final now = DateTime.now();
    return _db
        .collection('users')
        .doc(uid)
        .collection('vocabulary')
        .where('next_review', isLessThanOrEqualTo: Timestamp.fromDate(now)) // Hanya yang jatuh tempo
        .where('is_mastered', isEqualTo: false) // Yang belum hafal mati
        .limit(10) // Batasi 10 kata per sesi agar tidak overwhelm
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WordModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // 2. Fungsi SRS (Algoritma Leitner System Sederhana)
  Future<void> processWordReview(String uid, WordModel word, bool remembered) async {
    int newBox = word.box;
    DateTime newNextReview;

    if (remembered) {
      // Jika INGAT: Naik kelas, jeda review makin lama
      newBox++; 
      // Box 1: 1 hari, Box 2: 3 hari, Box 3: 7 hari, Box 4: 14 hari, Box 5: 30 hari
      int daysToAdd = [1, 3, 7, 14, 30][(newBox - 1).clamp(0, 4)];
      newNextReview = DateTime.now().add(Duration(days: daysToAdd));
    } else {
      // Jika LUPA: Reset ke Box 1, review lagi besok
      newBox = 1;
      newNextReview = DateTime.now().add(const Duration(days: 1));
    }

    bool isMastered = newBox > 5; // Jika lewat box 5 dianggap Mastered

    await _db
        .collection('users')
        .doc(uid)
        .collection('vocabulary')
        .doc(word.id)
        .update({
          'box': newBox,
          'next_review': Timestamp.fromDate(newNextReview),
          'is_mastered': isMastered,
        });
  }

  // 3. Tambah Kata Baru (Dipanggil saat user menyelesaikan materi Story)
  Future<void> addWordToUser(String uid, WordModel word) async {
    // Cek dulu biar gak duplikat
    final check = await _db.collection('users').doc(uid).collection('vocabulary').doc(word.id).get();
    if (!check.exists) {
      await _db.collection('users').doc(uid).collection('vocabulary').doc(word.id).set(word.toMap());
    }
  }
}