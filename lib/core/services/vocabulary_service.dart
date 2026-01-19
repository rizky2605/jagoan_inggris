import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/word_model.dart';

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
    // 1. Ambil kata yang sudah dipelajari user
    final userVocabSnapshot = await _db.collection('users').doc(uid).collection('vocabulary').get();
    final learnedWords = userVocabSnapshot.docs.map((doc) => doc['word'] as String).toSet();

    // 2. Filter dari Master Bank (Hanya ambil yang belum ada di learnedWords)
    List<WordModel> newWords = _masterWordBank.where((word) => !learnedWords.contains(word.word)).toList();

    // 3. Acak dan ambil 5
    newWords.shuffle();
    return newWords.take(5).toList();
  }

  // Simpan 5 kata hasil belajar ke database user
  Future<void> saveDailyBatch(String uid, List<WordModel> words) async {
    final batch = _db.batch();
    for (var word in words) {
      var docRef = _db.collection('users').doc(uid).collection('vocabulary').doc(); 
      batch.set(docRef, word.toMap());
    }
    await batch.commit();
  }

  // ===========================================================================
  // 4. HELPER & DEBUG (Ini yang bikin error sebelumnya)
  // ===========================================================================

  // --- INI FUNGSI YANG HILANG SEBELUMNYA ---
  Future<void> addWord(String uid, WordModel word) async {
    await _db.collection('users').doc(uid).collection('vocabulary').add(word.toMap());
  }

  // ===========================================================================
  // 5. MASTER DATA BANK (Simulasi Database Server)
  // ===========================================================================
  final List<WordModel> _masterWordBank = [
    WordModel(id: '', word: 'Abundant', pronunciation: '/əˈbʌn.dənt/', category: 'Adjective', meaning: 'Melimpah', mnemonic: "Roti (Bun) Menari (Dance) karena selai MELIMPAH.", exampleSentence: "We have abundant food.", nextReview: DateTime.now()),
    WordModel(id: '', word: 'Gloomy', pronunciation: '/ˈɡluː.mi/', category: 'Adjective', meaning: 'Suram', mnemonic: "Kena LEM (Glue) jadi SURAM.", exampleSentence: "The sky is gloomy.", nextReview: DateTime.now()),
    WordModel(id: '', word: 'Keen', pronunciation: '/kiːn/', category: 'Adjective', meaning: 'Tertarik', mnemonic: "Si IKIN sangat TERTARIK belajar.", exampleSentence: "She is keen on music.", nextReview: DateTime.now()),
    WordModel(id: '', word: 'Candid', pronunciation: '/ˈkæn.dɪd/', category: 'Adjective', meaning: 'Jujur', mnemonic: "KANDIDAT harus JUJUR.", exampleSentence: "To be candid, I dislike it.", nextReview: DateTime.now()),
    WordModel(id: '', word: 'Huge', pronunciation: '/hjuːdʒ/', category: 'Adjective', meaning: 'Besar', mnemonic: "HIU itu badannya BESAR.", exampleSentence: "A huge mistake.", nextReview: DateTime.now()),
    WordModel(id: '', word: 'Vanish', pronunciation: '/ˈvæn.ɪʃ/', category: 'Verb', meaning: 'Menghilang', mnemonic: "Pakai 'Vanish' noda MENGHILANG.", exampleSentence: "The ghost vanished.", nextReview: DateTime.now()),
    WordModel(id: '', word: 'Elaborate', pronunciation: '/iˈlæb.ə.reɪt/', category: 'Verb', meaning: 'Menjelaskan Detail', mnemonic: "Laboratorium (LAB) butuh PENJELASAN DETAIL.", exampleSentence: "Please elaborate your idea.", nextReview: DateTime.now()),
    WordModel(id: '', word: 'Fragile', pronunciation: '/ˈfrædʒ.aɪl/', category: 'Adjective', meaning: 'Rapuh', mnemonic: "Pergi (GO) kalau hati RAPUH.", exampleSentence: "Glass is fragile.", nextReview: DateTime.now()),
    WordModel(id: '', word: 'Obstacle', pronunciation: '/ˈɒb.stə.kəl/', category: 'Noun', meaning: 'Hambatan', mnemonic: "OBor SaTAip (Obstacle) menerangi HAMBATAN.", exampleSentence: "Face the obstacle.", nextReview: DateTime.now()),
    WordModel(id: '', word: 'Rural', pronunciation: '/ˈrʊə.rəl/', category: 'Adjective', meaning: 'Pedesaan', mnemonic: "RUSA tinggal di PEDESAAN.", exampleSentence: "I like rural areas.", nextReview: DateTime.now()),
  ];
}