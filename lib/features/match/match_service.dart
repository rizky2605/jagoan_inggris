import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math'; 
import '../../models/match_model.dart';
import '../../models/user_model.dart';

class MatchService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ===========================================================================
  // 1. MATCHMAKING SYSTEM (FAIL-SAFE)
  // ===========================================================================
  
  Future<String> findMatch(UserModel user) async {
    try {
      // 1. Masukkan diri ke antrean (Status: searching)
      // Gunakan set dengan merge agar tidak menimpa data jika sudah ada
      await _db.collection('match_queue').doc(user.uid).set({
        'uid': user.uid,
        'username': user.username,
        'photoUrl': user.photoUrl,
        'mmr': user.mmr,
        // Simpan avatar path agar musuh bisa melihatnya
        'avatarPath': _getAvatarPath(user.equippedLoadout['body']),
        'status': 'searching', 
        'timestamp': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Beri jeda sedikit agar data kita masuk dulu (mencegah glitch pembacaan sendiri)
      await Future.delayed(const Duration(milliseconds: 500));

      // 2. Cari Lawan
      QuerySnapshot queueSnapshot = await _db.collection('match_queue')
          .where('status', isEqualTo: 'searching')
          .orderBy('timestamp', descending: false) // FIFO
          .limit(10)
          .get();

      DocumentSnapshot? opponentDoc;
      DateTime threshold = DateTime.now().subtract(const Duration(seconds: 40));

      for (var doc in queueSnapshot.docs) {
        // Jangan lawan diri sendiri
        if (doc['uid'] == user.uid) continue;

        // Cek User Aktif (Safe Check)
        try {
          if (doc.data() != null && (doc.data() as Map).containsKey('lastSeen')) {
            Timestamp? ts = doc['lastSeen'];
            // Jika null (baru banget join), anggap aktif. Jika ada tanggal, cek threshold.
            if (ts != null && ts.toDate().isBefore(threshold)) {
              continue; // Skip user hantu
            }
          }
        } catch (e) {
          continue; // Skip jika data error
        }

        opponentDoc = doc;
        break; 
      }

      // 3. Transaksi (Mencoba Match)
      if (opponentDoc != null) {
        try {
          return await _db.runTransaction((transaction) async {
            DocumentSnapshot freshOpponent = await transaction.get(opponentDoc!.reference);
            if (!freshOpponent.exists) {
              throw Exception("Lawan sudah diambil.");
            }

            String matchId = _db.collection('matches').doc().id; 
            
            // Ambil avatar lawan (Safe)
            String oppAvatar = 'assets/models/avatar_default.glb';
            try {
              oppAvatar = freshOpponent['avatarPath'] ?? 'assets/models/avatar_default.glb';
            } catch (_) {}

            String myAvatar = _getAvatarPath(user.equippedLoadout['body']);

            MatchModel newMatch = MatchModel(
              matchId: matchId,
              player1Uid: freshOpponent['uid'],
              player2Uid: user.uid,
              player1Name: freshOpponent['username'],
              player2Name: user.username,
              p1PhotoUrl: freshOpponent['photoUrl'] ?? '', 
              p2PhotoUrl: user.photoUrl,
              p1Avatar: oppAvatar, 
              p2Avatar: myAvatar,
              status: 'playing',      
              currentRound: 1,
              p1Health: 100,
              p2Health: 100,
              p1Score: 0,
              p2Score: 0,
              currentQuestion: _getRandomQuestion(), 
            );

            // Hapus keduanya dari queue
            transaction.delete(freshOpponent.reference);
            transaction.delete(_db.collection('match_queue').doc(user.uid));
            
            // Buat Room
            transaction.set(_db.collection('matches').doc(matchId), newMatch.toMap());
            
            return matchId;
          });
        } catch (e) {
          // [FIX UTAMA] Jika transaksi gagal (misal lawan diambil orang lain duluan)
          // JANGAN ERROR. Tapi kembali ke mode MENUNGGU.
          print("Tabrakan Transaksi (Wajar): $e");
          return "WAITING"; 
        }
      } else {
        // Tidak ada lawan, kita menunggu
        return "WAITING"; 
      }

    } catch (e) {
      print("Global Match Error: $e");
      // Jika error index, lempar agar UI tahu. Jika error lain, tetap waiting.
      if (e.toString().contains("failed-precondition")) {
        throw Exception("INDEX_MISSING");
      }
      return "WAITING"; // Fallback aman
    }
  }

  // Helper Avatar
  String _getAvatarPath(String? itemId) {
    if (itemId == 'monster') return 'assets/models/monster.glb';
    if (itemId == 'teacher') return 'assets/models/teacher.glb';
    return 'assets/models/avatar_default.glb';
  }

  // --- SISA FUNGSI (TIDAK BERUBAH) ---

  Future<void> cancelSearch(String uid) async {
    try { await _db.collection('match_queue').doc(uid).delete(); } catch (e) {}
  }

  Future<void> updateHeartbeat(String uid) async {
    try {
      await _db.collection('match_queue').doc(uid).update({'lastSeen': FieldValue.serverTimestamp()});
    } catch (e) {}
  }
  
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

    // FIX Waktu Null = Sangat Lambat
    int t1 = match.p1Time ?? 99999999;
    int t2 = match.p2Time ?? 99999999;

    const int damageWrong = 20;       
    const int damageSlow = 5;         
    const int damageBothWrong = 10;   
    const int scoreWin = 20;

    if (p1Correct && !p2Correct) {
      p2NewHealth -= damageWrong; p1NewScore += scoreWin;
    } else if (!p1Correct && p2Correct) {
      p1NewHealth -= damageWrong; p2NewScore += scoreWin;
    } else if (p1Correct && p2Correct) {
      if (t1 < t2) { p2NewHealth -= damageSlow; p1NewScore += scoreWin; } 
      else if (t2 < t1) { p1NewHealth -= damageSlow; p2NewScore += scoreWin; } 
      else { p1NewScore += 10; p2NewScore += 10; }
    } else {
      p1NewHealth -= damageBothWrong; p2NewHealth -= damageBothWrong;
    }

    bool isGameOver = p1NewHealth <= 0 || p2NewHealth <= 0 || match.currentRound >= 5;

    await _db.collection('matches').doc(match.matchId).update({
      'p1Health': max(0, p1NewHealth),
      'p2Health': max(0, p2NewHealth),
      'p1Score': p1NewScore,
      'p2Score': p2NewScore,
      'p1Answer': null, 'p2Answer': null, 'p1Time': null, 'p2Time': null,
      'currentRound': isGameOver ? match.currentRound : match.currentRound + 1,
      'status': isGameOver ? 'finished' : 'playing',
      'currentQuestion': isGameOver ? null : _getRandomQuestion(),
    });
  }

  Future<void> finalizeMatchStats(MatchModel match) async {
    final matchRef = _db.collection('matches').doc(match.matchId);
    final matchSnap = await matchRef.get();
    if (matchSnap.data()?['statsProcessed'] == true) return;

    String winnerUid; String loserUid;
    if (match.p1Health > match.p2Health) { winnerUid = match.player1Uid; loserUid = match.player2Uid; } 
    else if (match.p2Health > match.p1Health) { winnerUid = match.player2Uid; loserUid = match.player1Uid; } 
    else if (match.p1Score > match.p2Score) { winnerUid = match.player1Uid; loserUid = match.player2Uid; } 
    else { winnerUid = match.player2Uid; loserUid = match.player1Uid; }

    WriteBatch batch = _db.batch();
    batch.update(_db.collection('users').doc(winnerUid), {
      'mmr': FieldValue.increment(25), 'winCount': FieldValue.increment(1), 'gold': FieldValue.increment(100), 
    });
    DocumentSnapshot loserSnap = await _db.collection('users').doc(loserUid).get();
    if (loserSnap.exists) {
       int currentMmr = (loserSnap.data() as Map<String, dynamic>)['mmr'] ?? 0;
       int deduction = currentMmr >= 15 ? -15 : -currentMmr;
       batch.update(_db.collection('users').doc(loserUid), {
         'mmr': FieldValue.increment(deduction), 'lossCount': FieldValue.increment(1), 'gold': FieldValue.increment(20),
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
      {'question': 'She ___ to school.', 'options': ['Go', 'Goes', 'Went', 'Gone'], 'correctAnswer': 'Goes'},
      {'question': 'They ___ football now.', 'options': ['Play', 'Played', 'Are playing', 'Is playing'], 'correctAnswer': 'Are playing'},
      {'question': 'Opposite of "Happy"', 'options': ['Sad', 'Angry', 'Glad', 'Joy'], 'correctAnswer': 'Sad'},
      {'question': 'We ___ busy yesterday.', 'options': ['Was', 'Were', 'Are', 'Is'], 'correctAnswer': 'Were'},
    ];
    return questionBank[Random().nextInt(questionBank.length)];
  }
}