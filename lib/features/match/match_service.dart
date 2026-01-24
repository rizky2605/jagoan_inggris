import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/match_model.dart';
import '../../models/user_model.dart';

class MatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==========================================
  // 1. LOBBY & MATCHMAKING
  // ==========================================

  // Mencari match: Join jika ada yang menunggu, Buat baru jika tidak
  Future<String> findMatch(UserModel user) async {
    try {
      // Cari match yang statusnya 'waiting' & bukan diri sendiri
      QuerySnapshot waitingMatches = await _firestore
          .collection('matches')
          .where('status', isEqualTo: 'waiting')
          .where('player1Uid', isNotEqualTo: user.uid)
          .limit(1)
          .get();

      if (waitingMatches.docs.isNotEmpty) {
        // === JOIN MATCH ===
        DocumentSnapshot matchDoc = waitingMatches.docs.first;
        
        return await _firestore.runTransaction((transaction) async {
          DocumentSnapshot freshSnap = await transaction.get(matchDoc.reference);
          
          if (!freshSnap.exists || freshSnap['status'] != 'waiting') {
            throw Exception("Match expired");
          }

          transaction.update(matchDoc.reference, {
            'player2Uid': user.uid,
            'player2Name': user.username,
            'p2PhotoUrl': user.photoUrl,
            'p2Loadout': user.equippedLoadout, // Simpan Loadout P2
            'status': 'playing',
            'p2Health': 100,
            'p2Score': 0,
            // Generate soal pertama saat match dimulai
            'currentQuestion': _generateRandomQuestion([]),
          });

          return matchDoc.id;
        });
      } else {
        // === CREATE MATCH ===
        return await _createMatch(user);
      }
    } catch (e) {
      print("Error finding match: $e");
      return await _createMatch(user); 
    }
  }

  Future<String> _createMatch(UserModel user) async {
    DocumentReference newMatchRef = _firestore.collection('matches').doc();

    MatchModel newMatch = MatchModel(
      matchId: newMatchRef.id,
      player1Uid: user.uid,
      player2Uid: '',
      player1Name: user.username,
      player2Name: '', 
      p1PhotoUrl: user.photoUrl,
      p2PhotoUrl: '',
      p1Loadout: user.equippedLoadout, // Simpan Loadout P1
      p2Loadout: {}, 
      status: 'waiting',
      currentRound: 1,
      p1Health: 100,
      p2Health: 100,
      p1Score: 0,
      p2Score: 0,
      usedQuestionIndices: [],
    );

    await newMatchRef.set(newMatch.toMap());
    return "WAITING";
  }

  Future<void> cancelSearch(String uid) async {
    QuerySnapshot myWaitingMatch = await _firestore
        .collection('matches')
        .where('player1Uid', isEqualTo: uid)
        .where('status', isEqualTo: 'waiting')
        .get();

    for (var doc in myWaitingMatch.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> updateHeartbeat(String uid) async {
    // Opsional: Update status online user
  }
  
  Future<void> syncUserStats(String uid) async {
    // Opsional: Sinkronisasi data user jika perlu
  }

  // ==========================================
  // 2. GAMEPLAY LOGIC (YANG HILANG)
  // ==========================================

  /// [FIX 1] Mendapatkan Stream Data Match Realtime
  Stream<MatchModel> getMatchStream(String matchId) {
    return _firestore.collection('matches').doc(matchId).snapshots().map((doc) {
      if (!doc.exists) throw Exception("Match not found");
      return MatchModel.fromMap(doc.data()!);
    });
  }

  /// [FIX 2] Submit Jawaban Player
  Future<void> submitAnswer(String matchId, String uid, String answer, int timeTaken, bool isP1) async {
    await _firestore.collection('matches').doc(matchId).update({
      isP1 ? 'p1Answer' : 'p2Answer': answer,
      isP1 ? 'p1Time' : 'p2Time': timeTaken,
    });
  }

  /// [FIX 3] Proses Hasil Ronde (Dipanggil oleh Host/P1)
  /// Menghitung damage, skor, dan ganti ronde
  Future<void> processRoundResult(MatchModel match) async {
    if (match.status == 'finished') return;

    String correct = match.currentQuestion?['correctAnswer'] ?? '';
    bool p1Correct = match.p1Answer == correct;
    bool p2Correct = match.p2Answer == correct;

    int p1Damage = 0;
    int p2Damage = 0;
    int p1Points = 0;
    int p2Points = 0;

    // Logika Hitung Damage & Skor
    if (p1Correct && p2Correct) {
      // Jika keduanya benar, yang lebih cepat dapat poin lebih, tidak ada yang kena damage
      // Atau bisa dibuat sama-sama kena damage sedikit.
      // Skenario Jagoan Inggris: Yang cepat nyerang yang lambat.
      if ((match.p1Time ?? 999) < (match.p2Time ?? 999)) {
        p2Damage = 20; // P2 Kena hit
        p1Points = 20;
      } else {
        p1Damage = 20; // P1 Kena hit
        p2Points = 20;
      }
    } else if (p1Correct) {
      p2Damage = 30; // P2 Salah, P2 Kena Damage Besar
      p1Points = 30;
    } else if (p2Correct) {
      p1Damage = 30; // P1 Salah, P1 Kena Damage Besar
      p2Points = 30;
    } else {
      // Keduanya Salah -> Keduanya kena damage kecil?
      p1Damage = 10;
      p2Damage = 10;
    }

    int newP1Health = max(0, match.p1Health - p1Damage);
    int newP2Health = max(0, match.p2Health - p2Damage);
    
    // Cek Game Over
    String newStatus = (newP1Health == 0 || newP2Health == 0) ? 'finished' : 'playing';

    // Generate Soal Baru (jika belum game over)
    Map<String, dynamic>? nextQuestion;
    List<int> nextUsedIndices = List.from(match.usedQuestionIndices);
    
    if (newStatus == 'playing') {
      nextQuestion = _generateRandomQuestion(nextUsedIndices);
    }

    await _firestore.collection('matches').doc(match.matchId).update({
      'p1Health': newP1Health,
      'p2Health': newP2Health,
      'p1Score': match.p1Score + p1Points,
      'p2Score': match.p2Score + p2Points,
      'status': newStatus,
      'currentRound': match.currentRound + 1,
      'p1Answer': null, // Reset jawaban
      'p2Answer': null,
      'p1Time': null,
      'p2Time': null,
      'currentQuestion': nextQuestion,
      'usedQuestionIndices': nextUsedIndices, // Update index soal yg terpakai
    });
  }

  /// [FIX 4] Finalisasi Stats User (Update MMR & Win/Loss)
  Future<void> finalizeMatchStats(MatchModel match) async {
    // Pastikan ini hanya dijalankan sekali agar tidak duplikat
    // Biasanya dicek di UI atau menggunakan Cloud Functions lebih aman.
    // Untuk Sederhana: Kita update langsung.
    
    bool isDraw = match.p1Health == 0 && match.p2Health == 0;
    bool p1Win = match.p1Health > 0; // Asumsi P2 mati duluan
    if (isDraw) {
        p1Win = match.p1Score > match.p2Score; // Jika seri HP, cek skor
    }

    // Update Player 1
    await _firestore.collection('users').doc(match.player1Uid).update({
      'mmr': FieldValue.increment(p1Win ? 25 : -20),
      'winCount': FieldValue.increment(p1Win ? 1 : 0),
      'lossCount': FieldValue.increment(p1Win ? 0 : 1),
    });

    // Update Player 2
    await _firestore.collection('users').doc(match.player2Uid).update({
      'mmr': FieldValue.increment(!p1Win ? 25 : -20),
      'winCount': FieldValue.increment(!p1Win ? 1 : 0),
      'lossCount': FieldValue.increment(!p1Win ? 0 : 1),
    });
  }

  // ==========================================
  // 3. QUESTION GENERATOR (HELPER)
  // ==========================================

  // Database Soal Sederhana (Bisa dipindahkan ke Firestore collection terpisah nanti)
  final List<Map<String, dynamic>> _questionBank = [
    {'q': 'What is the past tense of "Go"?', 'opts': ['Goned', 'Went', 'Gone', 'Going'], 'ans': 'Went'},
    {'q': 'She ___ a beautiful song.', 'opts': ['Sing', 'Sangs', 'Sang', 'Singing'], 'ans': 'Sang'},
    {'q': 'Antonym of "Happy" is...', 'opts': ['Sad', 'Joy', 'Glad', 'Fun'], 'ans': 'Sad'},
    {'q': 'Which one is a fruit?', 'opts': ['Carrot', 'Potato', 'Apple', 'Spinach'], 'ans': 'Apple'},
    {'q': 'Cat ___ on the mat.', 'opts': ['Sits', 'Sit', 'Satting', 'Sited'], 'ans': 'Sits'},
    {'q': 'Plural of "Child" is...', 'opts': ['Childs', 'Children', 'Childes', 'Baby'], 'ans': 'Children'},
    {'q': 'Translate: "Saya lapar"', 'opts': ['I am angry', 'I am hungry', 'I am thirsty', 'I am sleepy'], 'ans': 'I am hungry'},
    {'q': 'Verb 3 of "Eat"', 'opts': ['Ate', 'Eaten', 'Eating', 'Eats'], 'ans': 'Eaten'},
    {'q': 'Synonym of "Big"', 'opts': ['Small', 'Tiny', 'Huge', 'Short'], 'ans': 'Huge'},
    {'q': 'I ___ football every Sunday.', 'opts': ['Play', 'Plays', 'Played', 'Playing'], 'ans': 'Play'},
  ];

  Map<String, dynamic> _generateRandomQuestion(List<int> usedIndices) {
    Random random = Random();
    int index;
    
    // Cari index yang belum terpakai (Maksimal coba 100x biar gak infinite loop)
    int attempts = 0;
    do {
      index = random.nextInt(_questionBank.length);
      attempts++;
    } while (usedIndices.contains(index) && attempts < 100);

    // Tandai index terpakai
    usedIndices.add(index);
    
    var rawQ = _questionBank[index];
    
    // Acak posisi jawaban agar tidak selalu A
    List<String> options = List<String>.from(rawQ['opts']);
    options.shuffle();

    return {
      'question': rawQ['q'],
      'options': options,
      'correctAnswer': rawQ['ans'],
      'index': index,
    };
  }
  Stream<List<MatchModel>> getMatchHistory(String uid) {
    // Menggunakan Filter.or (Fitur baru Firestore) untuk mencari match dimana
    // user menjadi player1 ATAU player2
    return _firestore.collection('matches')
        .where(Filter.or(
          Filter('player1Uid', isEqualTo: uid),
          Filter('player2Uid', isEqualTo: uid),
        ))
        .where('status', isEqualTo: 'finished')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MatchModel.fromMap(doc.data()))
              .toList();
        });
  }
}
