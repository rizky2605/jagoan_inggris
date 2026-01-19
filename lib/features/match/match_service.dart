import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math'; 
import '../../models/match_model.dart';
import '../../models/user_model.dart';

class MatchService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. CARI LAWAN (MATCHMAKING) DENGAN TRANSAKSI
  Future<String> findMatch(UserModel user) async {
    // Kita gunakan Transaction agar tidak ada 2 orang yang "mengambil" lawan yang sama dari queue
    return await _db.runTransaction((transaction) async {
      
      // Filter: Cari pemain yang bukan diri sendiri DAN aktif (heartbeat < 20 detik)
      DateTime threshold = DateTime.now().subtract(const Duration(seconds: 20));
      
      QuerySnapshot queueSnapshot = await _db.collection('match_queue')
          .where('uid', isNotEqualTo: user.uid)
          .where('lastSeen', isGreaterThan: threshold)
          .orderBy('uid') 
          .orderBy('timestamp')
          .limit(1)
          .get();

      if (queueSnapshot.docs.isNotEmpty) {
        // --> KASUS: ADA LAWAN AKTIF
        var opponentDoc = queueSnapshot.docs.first;
        String opponentUid = opponentDoc['uid'];
        String opponentName = opponentDoc['username'];
        String opponentPhoto = opponentDoc['photoUrl'] ?? ''; 

        // Verifikasi ulang di dalam transaksi apakah lawan masih ada di queue
        DocumentSnapshot freshOpponent = await transaction.get(opponentDoc.reference);
        if (!freshOpponent.exists) {
          throw Exception("Lawan sudah diambil pemain lain, mengulang...");
        }

        String matchId = _db.collection('matches').doc().id; 
        
        MatchModel newMatch = MatchModel(
          matchId: matchId,
          player1Uid: opponentUid, // Penunggu jadi P1 (Host)
          player2Uid: user.uid,    // Kita jadi P2
          player1Name: opponentName,
          player2Name: user.username,
          p1PhotoUrl: opponentPhoto, 
          p2PhotoUrl: user.photoUrl,
          status: 'playing',      
          currentRound: 1,
          p1Health: 100,
          p2Health: 100,
          p1Score: 0,
          p2Score: 0,
          currentQuestion: _getRandomQuestion(), 
        );

        // Eksekusi: Hapus dari queue dan buat match room secara atomik
        transaction.delete(opponentDoc.reference);
        transaction.set(_db.collection('matches').doc(matchId), newMatch.toMap());
        
        return matchId;

      } else {
        // --> KASUS: TIDAK ADA LAWAN (Masuk Queue)
        DocumentReference myQueueRef = _db.collection('match_queue').doc(user.uid);
        transaction.set(myQueueRef, {
          'uid': user.uid,
          'username': user.username,
          'photoUrl': user.photoUrl, 
          'timestamp': FieldValue.serverTimestamp(),
          'lastSeen': FieldValue.serverTimestamp(), // Inisialisasi heartbeat
        });
        return "WAITING"; 
      }
    }).catchError((e) {
      print("Matchmaking Error: $e");
      return "";
    });
  }

  // 2. UPDATE HEARTBEAT (PENTING: Agar antrean tetap segar)
  Future<void> updateHeartbeat(String uid) async {
    try {
      await _db.collection('match_queue').doc(uid).update({
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Jika dokumen sudah dihapus (karena match ditemukan), abaikan error
    }
  }

  // 3. KIRIM JAWABAN
  Future<void> submitAnswer(String matchId, String uid, String answer, int timeTaken, bool isPlayer1) async {
    await _db.collection('matches').doc(matchId).update({
      isPlayer1 ? 'p1Answer' : 'p2Answer': answer,
      isPlayer1 ? 'p1Time' : 'p2Time': timeTaken,
    });
  }

  // 4. LOGIKA LANJUT RONDE (Hanya dijalankan oleh Player 1 / Host)
  Future<void> processRoundResult(MatchModel match) async {
    if (match.p1Answer == null || match.p2Answer == null) return;

    String correctAnswer = match.currentQuestion!['correctAnswer'];
    bool p1Correct = match.p1Answer == correctAnswer;
    bool p2Correct = match.p2Answer == correctAnswer;
    
    int p1NewHealth = match.p1Health;
    int p2NewHealth = match.p2Health;
    int p1NewScore = match.p1Score;
    int p2NewScore = match.p2Score;

    // Logika Damage
    if (p1Correct && !p2Correct) {
      p2NewHealth -= 20; p1NewScore += 10;
    } else if (!p1Correct && p2Correct) {
      p1NewHealth -= 20; p2NewScore += 10;
    } else if (p1Correct && p2Correct) {
      // Adu Cepat
      if ((match.p1Time ?? 0) < (match.p2Time ?? 0)) {
        p2NewHealth -= 10; p1NewScore += 15;
      } else {
        p1NewHealth -= 10; p2NewScore += 15;
      }
    } else {
      p1NewHealth -= 5; p2NewHealth -= 5; // Keduanya salah
    }

    bool isGameOver = p1NewHealth <= 0 || p2NewHealth <= 0 || match.currentRound >= 5;

    await _db.collection('matches').doc(match.matchId).update({
      'p1Health': max(0, p1NewHealth),
      'p2Health': max(0, p2NewHealth),
      'p1Score': p1NewScore,
      'p2Score': p2NewScore,
      'p1Answer': null, 
      'p2Answer': null,
      'p1Time': null,
      'p2Time': null,
      'currentRound': isGameOver ? match.currentRound : match.currentRound + 1,
      'status': isGameOver ? 'finished' : 'playing',
      'currentQuestion': isGameOver ? null : _getRandomQuestion(),
    });
  }

  // 5. FINALIZE STATS (MMR & Win/Loss)
  Future<void> finalizeMatchStats(MatchModel match) async {
    final matchRef = _db.collection('matches').doc(match.matchId);
    final matchSnap = await matchRef.get();
    
    if (matchSnap.data()?['statsProcessed'] == true) return;

    String? winnerUid, loserUid;
    if (match.p1Health > match.p2Health) {
      winnerUid = match.player1Uid; loserUid = match.player2Uid;
    } else if (match.p2Health > match.p1Health) {
      winnerUid = match.player2Uid; loserUid = match.player1Uid;
    }

    WriteBatch batch = _db.batch();

    if (winnerUid != null && loserUid != null) {
      // Update Pemenang (+20 MMR)
      batch.update(_db.collection('users').doc(winnerUid), {
        'mmr': FieldValue.increment(20),
        'winCount': FieldValue.increment(1),
      });

      // Update Pecundang (-10 MMR, proteksi agar tidak < 0)
      DocumentSnapshot loserSnap = await _db.collection('users').doc(loserUid).get();
      int currentMmr = (loserSnap.data() as Map<String, dynamic>)['mmr'] ?? 0;
      int deduction = currentMmr >= 10 ? -10 : -currentMmr;

      batch.update(_db.collection('users').doc(loserUid), {
        'mmr': FieldValue.increment(deduction),
        'lossCount': FieldValue.increment(1),
      });
    }

    batch.update(matchRef, {'statsProcessed': true});
    await batch.commit();
  }

  // Helper lainnya tetap sama...
  Future<void> cancelSearch(String uid) async => await _db.collection('match_queue').doc(uid).delete();

  Stream<MatchModel> getMatchStream(String matchId) {
    return _db.collection('matches').doc(matchId).snapshots().map((doc) {
      if (!doc.exists) throw Exception("Match doc missing");
      return MatchModel.fromMap(doc.data() as Map<String, dynamic>);
    });
  }

  Map<String, dynamic> _getRandomQuestion() {
    final List<Map<String, dynamic>> questionBank = [
      {'question': 'Apple is a ...', 'options': ['Fruit', 'Job', 'Animal', 'Car'], 'correctAnswer': 'Fruit'},
      {'question': 'I ___ a student.', 'options': ['Am', 'Is', 'Are', 'Be'], 'correctAnswer': 'Am'},
      {'question': 'She ___ to the park yesterday.', 'options': ['Went', 'Go', 'Going', 'Goes'], 'correctAnswer': 'Went'},
      {'question': 'They ___ soccer now.', 'options': ['Play', 'Playing', 'Are playing', 'Is playing'], 'correctAnswer': 'Are playing'},
      {'question': 'We ___ at the cinema last night.', 'options': ['Was', 'Were', 'Am', 'Are'], 'correctAnswer': 'Were'},
    ];
    return questionBank[Random().nextInt(questionBank.length)];
  }
}