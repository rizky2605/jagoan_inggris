import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math'; 
import '../../models/match_model.dart';
import '../../models/user_model.dart';
import '../../core/constants/question_data.dart'; // Pastikan import ini ada

class MatchService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ===========================================================================
  // 1. MATCHMAKING SYSTEM
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

            // Ambil soal unik pertama
            Map<String, dynamic> firstQResult = _getUniqueRandomQuestion([]); 
            
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
              currentQuestion: firstQResult['question'],
              usedQuestionIndices: [firstQResult['index']],
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
  
  // ===========================================================================
  // 2. GAMEPLAY LOGIC
  // ===========================================================================

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

    bool isGameOver = p1NewHealth <= 0 || p2NewHealth <= 0 || match.currentRound >= 10;

    // Siapkan soal berikutnya jika belum Game Over
    Map<String, dynamic>? nextQuestion;
    List<int> nextUsedIndices = List.from(match.usedQuestionIndices);

    if (!isGameOver) {
      var res = _getUniqueRandomQuestion(nextUsedIndices);
      nextQuestion = res['question'];
      nextUsedIndices.add(res['index']);
    }

    await _db.collection('matches').doc(match.matchId).update({
      'p1Health': max(0, p1NewHealth),
      'p2Health': max(0, p2NewHealth),
      'p1Score': p1NewScore,
      'p2Score': p2NewScore,
      'p1Answer': null, 'p2Answer': null, 'p1Time': null, 'p2Time': null,
      'currentRound': isGameOver ? match.currentRound : match.currentRound + 1,
      'status': isGameOver ? 'finished' : 'playing',
      'currentQuestion': nextQuestion,
      'usedQuestionIndices': nextUsedIndices,
    });
  }

  // --- LOGIKA SOAL UNIK ---
  Map<String, dynamic> _getUniqueRandomQuestion(List<int> usedIndices) {
    List<int> availableIndices = [];
    for (int i = 0; i < QuestionData.questions.length; i++) {
      if (!usedIndices.contains(i)) {
        availableIndices.add(i);
      }
    }

    if (availableIndices.isEmpty) {
      int randomIndex = Random().nextInt(QuestionData.questions.length);
      return {'question': QuestionData.questions[randomIndex], 'index': randomIndex};
    }

    int selectedIndex = availableIndices[Random().nextInt(availableIndices.length)];
    return {'question': QuestionData.questions[selectedIndex], 'index': selectedIndex};
  }

  // ===========================================================================
  // 3. STATS & SYNC
  // ===========================================================================

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
      if (!doc.exists) throw Exception("Match missing");
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

  Future<void> syncUserStats(String uid) async {
    try {
      int wins = 0; int losses = 0;
      var q1 = await _db.collection('matches').where('player1Uid', isEqualTo: uid).where('status', isEqualTo: 'finished').get();
      var q2 = await _db.collection('matches').where('player2Uid', isEqualTo: uid).where('status', isEqualTo: 'finished').get();
      List<DocumentSnapshot> allDocs = [...q1.docs, ...q2.docs];

      for (var doc in allDocs) {
        var data = doc.data() as Map<String, dynamic>;
        int hp1 = data['p1Health'] ?? 0; int hp2 = data['p2Health'] ?? 0;
        int s1 = data['p1Score'] ?? 0; int s2 = data['p2Score'] ?? 0;
        bool isP1 = (data['player1Uid'] == uid);
        bool userWon = false;
        if (hp1 > hp2) userWon = isP1;
        else if (hp2 > hp1) userWon = !isP1;
        else if (s1 > s2) userWon = isP1;
        else userWon = !isP1; 
        if (userWon) wins++; else losses++;
      }
      await _db.collection('users').doc(uid).update({'winCount': wins, 'lossCount': losses});
    } catch (e) { print("Sync Error: $e"); }
  }
}