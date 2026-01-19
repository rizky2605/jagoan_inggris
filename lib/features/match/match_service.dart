import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math'; 
import '../../models/match_model.dart';
import '../../models/user_model.dart';

class MatchService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ===========================================================================
  // 1. MATCHMAKING SYSTEM (TRANSACTIONAL & SAFE)
  // ===========================================================================
  Future<String> findMatch(UserModel user) async {
    // Menggunakan Transaction untuk mencegah "Race Condition" (Rebutan Lawan)
    return await _db.runTransaction((transaction) async {
      
      // Filter: Cari pemain lain yang aktif dalam 20 detik terakhir
      DateTime threshold = DateTime.now().subtract(const Duration(seconds: 20));
      
      // Query membutuhkan Composite Index di Firestore
      QuerySnapshot queueSnapshot = await _db.collection('match_queue')
          .where('uid', isNotEqualTo: user.uid)
          .where('lastSeen', isGreaterThan: threshold)
          .orderBy('uid') 
          .orderBy('timestamp')
          .limit(1)
          .get();

      if (queueSnapshot.docs.isNotEmpty) {
        // --> KASUS A: LAWAN DITEMUKAN (Kita jadi Player 2)
        var opponentDoc = queueSnapshot.docs.first;
        String opponentUid = opponentDoc['uid'];
        
        // Cek lagi apakah dokumen lawan masih ada (Double Check)
        DocumentSnapshot freshOpponent = await transaction.get(opponentDoc.reference);
        if (!freshOpponent.exists) {
          throw Exception("Lawan sudah diambil pemain lain, mencoba ulang...");
        }

        String matchId = _db.collection('matches').doc().id; 
        
        MatchModel newMatch = MatchModel(
          matchId: matchId,
          player1Uid: opponentUid, // Pemain yang menunggu jadi P1 (Host)
          player2Uid: user.uid,    // Kita jadi P2
          player1Name: opponentDoc['username'],
          player2Name: user.username,
          p1PhotoUrl: opponentDoc['photoUrl'] ?? '', 
          p2PhotoUrl: user.photoUrl,
          status: 'playing',      
          currentRound: 1,
          p1Health: 100,
          p2Health: 100,
          p1Score: 0,
          p2Score: 0,
          currentQuestion: _getRandomQuestion(), 
        );

        // Hapus lawan dari antrean & Buat Room Match sekaligus
        transaction.delete(opponentDoc.reference);
        transaction.set(_db.collection('matches').doc(matchId), newMatch.toMap());
        
        return matchId;

      } else {
        // --> KASUS B: TIDAK ADA LAWAN (Kita Masuk Antrean)
        DocumentReference myQueueRef = _db.collection('match_queue').doc(user.uid);
        transaction.set(myQueueRef, {
          'uid': user.uid,
          'username': user.username,
          'photoUrl': user.photoUrl, 
          'timestamp': FieldValue.serverTimestamp(),
          'lastSeen': FieldValue.serverTimestamp(),
        });
        return "WAITING"; 
      }
    }).catchError((e) {
      // PENTING: Print error lengkap untuk melihat link pembuatan Index
      print("Matchmaking Error: $e");
      return "";
    });
  }

  // ===========================================================================
  // 2. GAMEPLAY LOGIC
  // ===========================================================================
  
  // Update Heartbeat: Menandakan user masih standby di layar pencarian
  Future<void> updateHeartbeat(String uid) async {
    try {
      await _db.collection('match_queue').doc(uid).update({
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Abaikan error jika doc sudah dihapus (karena match ketemu)
    }
  }

  // Kirim Jawaban ke Server
  Future<void> submitAnswer(String matchId, String uid, String answer, int timeTaken, bool isPlayer1) async {
    await _db.collection('matches').doc(matchId).update({
      isPlayer1 ? 'p1Answer' : 'p2Answer': answer,
      isPlayer1 ? 'p1Time' : 'p2Time': timeTaken,
    });
  }

  // LOGIKA "HAKIM" (Dijalankan hanya oleh P1/Host)
  Future<void> processRoundResult(MatchModel match) async {
    // Validasi: Jangan proses jika salah satu belum menjawab
    if (match.p1Answer == null || match.p2Answer == null) return;

    String correctAnswer = match.currentQuestion!['correctAnswer'];
    bool p1Correct = match.p1Answer == correctAnswer;
    bool p2Correct = match.p2Answer == correctAnswer;
    
    int p1NewHealth = match.p1Health;
    int p2NewHealth = match.p2Health;
    int p1NewScore = match.p1Score;
    int p2NewScore = match.p2Score;

    // --- LOGIKA PERHITUNGAN DAMAGE ---
    if (p1Correct && !p2Correct) {
      // P1 Benar, P2 Salah -> P2 Kena Damage Besar
      p2NewHealth -= 20; 
      p1NewScore += 10;
    } else if (!p1Correct && p2Correct) {
      // P1 Salah, P2 Benar -> P1 Kena Damage Besar
      p1NewHealth -= 20; 
      p2NewScore += 10;
    } else if (p1Correct && p2Correct) {
      // Keduanya Benar -> Adu Kecepatan
      if ((match.p1Time ?? 0) < (match.p2Time ?? 0)) {
        p2NewHealth -= 10; // P1 Lebih Cepat
        p1NewScore += 15;
      } else {
        p1NewHealth -= 10; // P2 Lebih Cepat
        p2NewScore += 15;
      }
    } else {
      // Keduanya Salah -> Sama-sama kena damage kecil
      p1NewHealth -= 5; 
      p2NewHealth -= 5; 
    }

    // Cek Game Over
    bool isGameOver = p1NewHealth <= 0 || p2NewHealth <= 0 || match.currentRound >= 5;

    await _db.collection('matches').doc(match.matchId).update({
      'p1Health': max(0, p1NewHealth),
      'p2Health': max(0, p2NewHealth),
      'p1Score': p1NewScore,
      'p2Score': p2NewScore,
      // Reset Jawaban untuk ronde berikutnya
      'p1Answer': null, 
      'p2Answer': null,
      'p1Time': null,
      'p2Time': null,
      'currentRound': isGameOver ? match.currentRound : match.currentRound + 1,
      'status': isGameOver ? 'finished' : 'playing',
      'currentQuestion': isGameOver ? null : _getRandomQuestion(),
    });
  }

  // ===========================================================================
  // 3. POST-GAME LOGIC (MMR & REWARDS)
  // ===========================================================================
  
  Future<void> finalizeMatchStats(MatchModel match) async {
    final matchRef = _db.collection('matches').doc(match.matchId);
    final matchSnap = await matchRef.get();
    
    // Cek apakah stats sudah pernah diproses agar tidak double reward
    if (matchSnap.data()?['statsProcessed'] == true) return;

    // DEFINITE ASSIGNMENT: Tidak pakai tanda tanya (?) agar tidak warning
    // Kita jamin variabel ini akan terisi lewat logika if-else di bawah.
    String winnerUid;
    String loserUid;

    // --- LOGIKA PENENTUAN PEMENANG MUTLAK ---

    // 1. Cek Darah (HP)
    if (match.p1Health > match.p2Health) {
      winnerUid = match.player1Uid; 
      loserUid = match.player2Uid;
    } else if (match.p2Health > match.p1Health) {
      winnerUid = match.player2Uid; 
      loserUid = match.player1Uid;
    } 
    // 2. Jika HP Sama, Cek Skor
    else if (match.p1Score > match.p2Score) {
      winnerUid = match.player1Uid; 
      loserUid = match.player2Uid;
    } 
    // 3. Jika HP Sama & Skor P2 Lebih Tinggi (atau SAMA PERSIS)
    // Blok 'else' ini menangkap kondisi (P2 > P1) DAN kondisi (P2 == P1)
    // Jadi P2 dianggap menang jika seri total (Keuntungan Penantang)
    else {
      winnerUid = match.player2Uid; 
      loserUid = match.player1Uid;
    }

    WriteBatch batch = _db.batch();

    // 1. UPDATE PEMENANG: +20 MMR, +1 Win, +50 Gold
    batch.update(_db.collection('users').doc(winnerUid), {
      'mmr': FieldValue.increment(20),
      'winCount': FieldValue.increment(1),
      'gold': FieldValue.increment(50), 
    });

    // 2. UPDATE PECUNDANG: -10 MMR (Min 0), +1 Loss, +10 Gold
    DocumentSnapshot loserSnap = await _db.collection('users').doc(loserUid).get();
    
    // Safety check jika user sudah dihapus
    if (loserSnap.exists) {
       int currentMmr = (loserSnap.data() as Map<String, dynamic>)['mmr'] ?? 0;
       int deduction = currentMmr >= 10 ? -10 : -currentMmr;

       batch.update(_db.collection('users').doc(loserUid), {
         'mmr': FieldValue.increment(deduction),
         'lossCount': FieldValue.increment(1),
         'gold': FieldValue.increment(10),
       });
    }

    // Tandai match ini sudah selesai diproses stats-nya
    batch.update(matchRef, {'statsProcessed': true});
    await batch.commit();
  }

  Future<void> cancelSearch(String uid) async {
    try {
      await _db.collection('match_queue').doc(uid).delete();
    } catch (e) {
      print("Error cancel search: $e");
    }
  }

  Stream<MatchModel> getMatchStream(String matchId) {
    return _db.collection('matches').doc(matchId).snapshots().map((doc) {
      if (!doc.exists) throw Exception("Match doc missing");
      return MatchModel.fromMap(doc.data() as Map<String, dynamic>);
    });
  }

  // ===========================================================================
  // 4. QUESTION BANK (SOAL BAHASA INGGRIS)
  // ===========================================================================
  Map<String, dynamic> _getRandomQuestion() {
    final List<Map<String, dynamic>> questionBank = [
      // Grammar
      {'question': 'I ___ a student.', 'options': ['Am', 'Is', 'Are', 'Be'], 'correctAnswer': 'Am'},
      {'question': 'She ___ to school yesterday.', 'options': ['Go', 'Goes', 'Went', 'Gone'], 'correctAnswer': 'Went'},
      {'question': 'They ___ playing football now.', 'options': ['Is', 'Am', 'Are', 'Be'], 'correctAnswer': 'Are'},
      
      // Vocabulary
      {'question': 'Opposite of "Big" is ...', 'options': ['Large', 'Small', 'Huge', 'Giant'], 'correctAnswer': 'Small'},
      {'question': 'Synonym of "Happy" is ...', 'options': ['Sad', 'Angry', 'Glad', 'Tired'], 'correctAnswer': 'Glad'},
      {'question': 'Apple is a kind of ...', 'options': ['Vegetable', 'Fruit', 'Meat', 'Drink'], 'correctAnswer': 'Fruit'},
      
      // Tenses
      {'question': 'We ___ Bali last year.', 'options': ['Visit', 'Visits', 'Visited', 'Visiting'], 'correctAnswer': 'Visited'},
    ];
    return questionBank[Random().nextInt(questionBank.length)];
  }
}