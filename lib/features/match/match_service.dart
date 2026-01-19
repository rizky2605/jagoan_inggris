import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math'; 
import '../../models/match_model.dart';
import '../../models/user_model.dart';

class MatchService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ===========================================================================
  // 1. MATCHMAKING SYSTEM (LOGIKA AMAN & SEDERHANA)
  // ===========================================================================
  
  Future<String> findMatch(UserModel user) async {
    try {
      // TAHAP 1: Masukkan diri ke antrean (Status: searching)
      // Gunakan set() dengan merge agar tidak menimpa data penting lain
      await _db.collection('match_queue').doc(user.uid).set({
        'uid': user.uid,
        'username': user.username,
        'photoUrl': user.photoUrl,
        'mmr': user.mmr,
        'status': 'searching', 
        'timestamp': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // TAHAP 2: Query Sederhana (Hanya butuh Index: status + timestamp)
      // Kita ambil 10 orang teratas, nanti kita filter manual mana yang aktif.
      QuerySnapshot queueSnapshot = await _db.collection('match_queue')
          .where('status', isEqualTo: 'searching')
          .orderBy('timestamp', descending: false) // FIFO (Siapa cepat dia dapat)
          .limit(10)
          .get();

      DocumentSnapshot? opponentDoc;
      // Batas waktu aktif 30 detik (User dianggap offline jika > 30 detik tidak update)
      DateTime threshold = DateTime.now().subtract(const Duration(seconds: 30));

      // TAHAP 3: Filter Manual (Di sisi Aplikasi, bukan Database)
      for (var doc in queueSnapshot.docs) {
        // Jangan lawan diri sendiri
        if (doc['uid'] == user.uid) continue;

        // Cek apakah lawan masih aktif (lastSeen)
        // Kita lakukan di sini agar tidak butuh Index 'lastSeen' yang rumit
        if (doc.data() != null && (doc.data() as Map).containsKey('lastSeen')) {
          Timestamp? ts = doc['lastSeen'];
          if (ts != null) {
            DateTime lastSeenDate = ts.toDate();
            if (lastSeenDate.isBefore(threshold)) {
              // Lawan sudah offline lama (Hantu), skip saja (nanti bisa dihapus worker)
              continue; 
            }
          }
        }

        // Ketemu lawan valid!
        opponentDoc = doc;
        break; 
      }

      // TAHAP 4: Transaksi Kunci (Locking)
      if (opponentDoc != null) {
        return await _db.runTransaction((transaction) async {
          // Cek lagi apakah lawan masih ada di DB
          DocumentSnapshot freshOpponent = await transaction.get(opponentDoc!.reference);
          if (!freshOpponent.exists) {
            throw Exception("Lawan sudah diambil orang lain.");
          }

          String matchId = _db.collection('matches').doc().id; 
          
          MatchModel newMatch = MatchModel(
            matchId: matchId,
            player1Uid: freshOpponent['uid'], // Lawan jadi Host
            player2Uid: user.uid,             // Kita jadi Tamu
            player1Name: freshOpponent['username'],
            player2Name: user.username,
            p1PhotoUrl: freshOpponent['photoUrl'] ?? '', 
            p2PhotoUrl: user.photoUrl,
            status: 'playing',      
            currentRound: 1,
            p1Health: 100,
            p2Health: 100,
            p1Score: 0,
            p2Score: 0,
            currentQuestion: _getRandomQuestion(), 
          );

          // Hapus antrean keduanya -> Buat Match
          transaction.delete(freshOpponent.reference);
          transaction.delete(_db.collection('match_queue').doc(user.uid));
          transaction.set(_db.collection('matches').doc(matchId), newMatch.toMap());
          
          return matchId;
        });
      } else {
        // Tidak ada lawan -> Kita tunggu (WAITING)
        return "WAITING"; 
      }

    } catch (e) {
      print("Matchmaking Error: $e");
      // Jangan langsung cancelSearch agar tidak keluar dari UI, 
      // tapi kembalikan error string kosong agar UI tahu ada masalah.
      return "";
    }
  }

  Future<void> cancelSearch(String uid) async {
    try {
      await _db.collection('match_queue').doc(uid).delete();
    } catch (e) {
      print("Error cancel search: $e");
    }
  }

  Future<void> updateHeartbeat(String uid) async {
    try {
      await _db.collection('match_queue').doc(uid).update({
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {}
  }

  // --- LOGIKA GAMEPLAY (Tidak Berubah) ---
  Future<void> submitAnswer(String matchId, String uid, String answer, int timeTaken, bool isPlayer1) async {
    await _db.collection('matches').doc(matchId).update({
      isPlayer1 ? 'p1Answer' : 'p2Answer': answer,
      isPlayer1 ? 'p1Time' : 'p2Time': timeTaken,
    });
  }

  Future<void> processRoundResult(MatchModel match) async {
    if (match.p1Answer == null || match.p2Answer == null) return;

    String correctAnswer = match.currentQuestion!['correctAnswer'];
    bool p1Correct = match.p1Answer == correctAnswer;
    bool p2Correct = match.p2Answer == correctAnswer;
    
    int p1NewHealth = match.p1Health;
    int p2NewHealth = match.p2Health;
    int p1NewScore = match.p1Score;
    int p2NewScore = match.p2Score;

    if (p1Correct && !p2Correct) {
      p2NewHealth -= 20; p1NewScore += 10;
    } else if (!p1Correct && p2Correct) {
      p1NewHealth -= 20; p2NewScore += 10;
    } else if (p1Correct && p2Correct) {
      if ((match.p1Time ?? 0) < (match.p2Time ?? 0)) {
        p2NewHealth -= 10; p1NewScore += 15;
      } else {
        p1NewHealth -= 10; p2NewScore += 15;
      }
    } else {
      p1NewHealth -= 5; p2NewHealth -= 5; 
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

  Future<void> finalizeMatchStats(MatchModel match) async {
    final matchRef = _db.collection('matches').doc(match.matchId);
    final matchSnap = await matchRef.get();
    
    if (matchSnap.data()?['statsProcessed'] == true) return;

    String winnerUid;
    String loserUid;

    if (match.p1Health > match.p2Health) {
      winnerUid = match.player1Uid; loserUid = match.player2Uid;
    } else if (match.p2Health > match.p1Health) {
      winnerUid = match.player2Uid; loserUid = match.player1Uid;
    } else if (match.p1Score > match.p2Score) {
      winnerUid = match.player1Uid; loserUid = match.player2Uid;
    } else {
      winnerUid = match.player2Uid; loserUid = match.player1Uid;
    }

    WriteBatch batch = _db.batch();

    batch.update(_db.collection('users').doc(winnerUid), {
      'mmr': FieldValue.increment(20),
      'winCount': FieldValue.increment(1),
      'gold': FieldValue.increment(50), 
    });

    DocumentSnapshot loserSnap = await _db.collection('users').doc(loserUid).get();
    if (loserSnap.exists) {
       int currentMmr = (loserSnap.data() as Map<String, dynamic>)['mmr'] ?? 0;
       int deduction = currentMmr >= 10 ? -10 : -currentMmr;

       batch.update(_db.collection('users').doc(loserUid), {
         'mmr': FieldValue.increment(deduction),
         'lossCount': FieldValue.increment(1),
         'gold': FieldValue.increment(10),
       });
    }

    batch.update(matchRef, {'statsProcessed': true});
    await batch.commit();
  }

  Stream<MatchModel> getMatchStream(String matchId) {
    return _db.collection('matches').doc(matchId).snapshots().map((doc) {
      if (!doc.exists) throw Exception("Match doc missing");
      return MatchModel.fromMap(doc.data() as Map<String, dynamic>);
    });
  }

  Map<String, dynamic> _getRandomQuestion() {
    final List<Map<String, dynamic>> questionBank = [
      {'question': 'I ___ a student.', 'options': ['Am', 'Is', 'Are', 'Be'], 'correctAnswer': 'Am'},
      {'question': 'She ___ to school yesterday.', 'options': ['Go', 'Goes', 'Went', 'Gone'], 'correctAnswer': 'Went'},
      {'question': 'Opposite of "Big" is ...', 'options': ['Large', 'Small', 'Huge', 'Giant'], 'correctAnswer': 'Small'},
      {'question': 'Synonym of "Happy" is ...', 'options': ['Sad', 'Angry', 'Glad', 'Tired'], 'correctAnswer': 'Glad'},
      {'question': 'We ___ Bali last year.', 'options': ['Visit', 'Visits', 'Visited', 'Visiting'], 'correctAnswer': 'Visited'},
    ];
    return questionBank[Random().nextInt(questionBank.length)];
  }
}