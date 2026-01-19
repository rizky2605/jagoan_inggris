import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math'; 
import '../../models/match_model.dart';
import '../../models/user_model.dart';

class MatchService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ... (KODE FIND MATCH & GAMEPLAY TETAP SAMA SEPERTI SEBELUMNYA) ...
  // Langsung scroll ke bagian paling bawah untuk update syncUserStats

  // ===========================================================================
  // 1. MATCHMAKING SYSTEM (FAIL-SAFE)
  // ===========================================================================
  
  Future<String> findMatch(UserModel user) async {
    try {
      await _db.collection('match_queue').doc(user.uid).set({
        'uid': user.uid,
        'username': user.username,
        'photoUrl': user.photoUrl,
        'mmr': user.mmr,
        'avatarPath': _getAvatarPath(user.equippedLoadout['body']),
        'status': 'searching', 
        'timestamp': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await Future.delayed(const Duration(milliseconds: 500));

      QuerySnapshot queueSnapshot = await _db.collection('match_queue')
          .where('status', isEqualTo: 'searching')
          .orderBy('timestamp', descending: false)
          .limit(10)
          .get();

      DocumentSnapshot? opponentDoc;
      DateTime threshold = DateTime.now().subtract(const Duration(seconds: 40));

      for (var doc in queueSnapshot.docs) {
        if (doc['uid'] == user.uid) continue;
        try {
          if (doc.data() != null && (doc.data() as Map).containsKey('lastSeen')) {
            Timestamp? ts = doc['lastSeen'];
            if (ts != null && ts.toDate().isBefore(threshold)) continue; 
          }
        } catch (e) { continue; }
        opponentDoc = doc;
        break; 
      }

      if (opponentDoc != null) {
        try {
          return await _db.runTransaction((transaction) async {
            DocumentSnapshot freshOpponent = await transaction.get(opponentDoc!.reference);
            if (!freshOpponent.exists) throw Exception("Lawan diambil.");

            String matchId = _db.collection('matches').doc().id; 
            
            String oppAvatar = 'assets/models/avatar_default.glb';
            try { oppAvatar = freshOpponent['avatarPath'] ?? 'assets/models/avatar_default.glb'; } catch (_) {}
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
              p1Health: 100, p2Health: 100, p1Score: 0, p2Score: 0,
              currentQuestion: _getRandomQuestion(), 
            );

            transaction.delete(freshOpponent.reference);
            transaction.delete(_db.collection('match_queue').doc(user.uid));
            transaction.set(_db.collection('matches').doc(matchId), newMatch.toMap());
            
            return matchId;
          });
        } catch (e) {
          return "WAITING"; 
        }
      } else {
        return "WAITING"; 
      }
    } catch (e) {
      if (e.toString().contains("failed-precondition")) throw Exception("INDEX_MISSING");
      return "WAITING"; 
    }
  }

  String _getAvatarPath(String? itemId) {
    if (itemId == 'monster') return 'assets/models/monster.glb';
    if (itemId == 'teacher') return 'assets/models/teacher.glb';
    return 'assets/models/avatar_default.glb';
  }

  Future<void> cancelSearch(String uid) async {
    try { await _db.collection('match_queue').doc(uid).delete(); } catch (e) {}
  }

  Future<void> updateHeartbeat(String uid) async {
    try { await _db.collection('match_queue').doc(uid).update({'lastSeen': FieldValue.serverTimestamp()}); } catch (e) {}
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

    int t1 = match.p1Time ?? 99999999;
    int t2 = match.p2Time ?? 99999999;

    const int damageWrong = 20; const int damageSlow = 5; 
    const int damageBothWrong = 10; const int scoreWin = 20;

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

  Stream<List<MatchModel>> getMatchHistory(String uid) {
    return _db.collection('matches')
        .where('status', isEqualTo: 'finished')
        .limit(50)
        .snapshots()
        .map((snapshot) {
          var allMatches = snapshot.docs.map((d) => MatchModel.fromMap(d.data())).toList();
          return allMatches.where((m) => m.player1Uid == uid || m.player2Uid == uid).toList();
        });
  }

  Map<String, dynamic> _getRandomQuestion() {
    final List<Map<String, dynamic>> questionBank = [
      {'question': 'I ___ a student.', 'options': ['Am', 'Is', 'Are', 'Be'], 'correctAnswer': 'Am'},
      {'question': 'She ___ to school.', 'options': ['Go', 'Goes', 'Went', 'Gone'], 'correctAnswer': 'Goes'},
      {'question': 'They ___ football.', 'options': ['Play', 'Played', 'Playing', 'Plays'], 'correctAnswer': 'Play'},
      {'question': 'Antonym of "Big"', 'options': ['Huge', 'Large', 'Small', 'Giant'], 'correctAnswer': 'Small'},
      {'question': 'Synonym of "Fast"', 'options': ['Slow', 'Quick', 'Late', 'Lazy'], 'correctAnswer': 'Quick'},
    ];
    return questionBank[Random().nextInt(questionBank.length)];
  }

  // ===========================================================================
  // [FIX] SYNC USER STATS (DENGAN LOGGING)
  // ===========================================================================
  
  Future<void> syncUserStats(String uid) async {
    try {
      print("SYNC: Memulai sinkronisasi stats untuk $uid");
      
      int wins = 0;
      int losses = 0;

      // Ambil match sebagai P1
      var q1 = await _db.collection('matches')
          .where('player1Uid', isEqualTo: uid)
          .where('status', isEqualTo: 'finished')
          .get();

      // Ambil match sebagai P2
      var q2 = await _db.collection('matches')
          .where('player2Uid', isEqualTo: uid)
          .where('status', isEqualTo: 'finished')
          .get();

      List<DocumentSnapshot> allDocs = [...q1.docs, ...q2.docs];
      print("SYNC: Ditemukan ${allDocs.length} riwayat pertandingan.");

      for (var doc in allDocs) {
        var data = doc.data() as Map<String, dynamic>;
        
        int hp1 = data['p1Health'] ?? 0;
        int hp2 = data['p2Health'] ?? 0;
        int s1 = data['p1Score'] ?? 0;
        int s2 = data['p2Score'] ?? 0;

        bool isP1 = (data['player1Uid'] == uid);
        bool userWon = false;

        // Logika Pemenang
        if (hp1 > hp2) userWon = isP1;
        else if (hp2 > hp1) userWon = !isP1;
        else if (s1 > s2) userWon = isP1;
        else userWon = !isP1; 

        if (userWon) wins++; else losses++;
      }

      print("SYNC RESULT: Wins=$wins, Losses=$losses");

      // Update Paksa ke Database User
      await _db.collection('users').doc(uid).update({
        'winCount': wins,
        'lossCount': losses,
      });
      
    } catch (e) {
      print("SYNC ERROR: $e");
    }
  }
}