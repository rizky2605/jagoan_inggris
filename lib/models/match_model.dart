class MatchModel {
  final String matchId;
  final String player1Uid;
  final String player2Uid;
  final String player1Name;
  final String player2Name;
  final String p1PhotoUrl;
  final String p2PhotoUrl;
  
  // Avatar 3D
  final String p1Avatar; 
  final String p2Avatar;

  final String status; // 'playing', 'finished'
  final int currentRound;
  
  final int p1Health;
  final int p2Health;
  final int p1Score;
  final int p2Score;
  
  final Map<String, dynamic>? currentQuestion;
  
  // [WAJIB] List index soal yang sudah dipakai (Agar soal tidak berulang)
  final List<int> usedQuestionIndices; 

  // Gameplay Data
  final String? p1Answer;
  final String? p2Answer;
  final int? p1Time;
  final int? p2Time;

  MatchModel({
    required this.matchId,
    required this.player1Uid,
    required this.player2Uid,
    required this.player1Name,
    required this.player2Name,
    required this.p1PhotoUrl,
    required this.p2PhotoUrl,
    this.p1Avatar = 'assets/models/avatar_default.glb', 
    this.p2Avatar = 'assets/models/avatar_default.glb',
    required this.status,
    required this.currentRound,
    required this.p1Health,
    required this.p2Health,
    required this.p1Score,
    required this.p2Score,
    this.currentQuestion,
    // [WAJIB] Default list kosong
    this.usedQuestionIndices = const [], 
    this.p1Answer,
    this.p2Answer,
    this.p1Time,
    this.p2Time,
  });

  Map<String, dynamic> toMap() {
    return {
      'matchId': matchId,
      'player1Uid': player1Uid,
      'player2Uid': player2Uid,
      'player1Name': player1Name,
      'player2Name': player2Name,
      'p1PhotoUrl': p1PhotoUrl,
      'p2PhotoUrl': p2PhotoUrl,
      'p1Avatar': p1Avatar,
      'p2Avatar': p2Avatar,
      'status': status,
      'currentRound': currentRound,
      'p1Health': p1Health,
      'p2Health': p2Health,
      'p1Score': p1Score,
      'p2Score': p2Score,
      'currentQuestion': currentQuestion,
      // [WAJIB] Simpan ke DB
      'usedQuestionIndices': usedQuestionIndices, 
      'p1Answer': p1Answer,
      'p2Answer': p2Answer,
      'p1Time': p1Time,
      'p2Time': p2Time,
    };
  }

  factory MatchModel.fromMap(Map<String, dynamic> map) {
    return MatchModel(
      matchId: map['matchId'] ?? '',
      player1Uid: map['player1Uid'] ?? '',
      player2Uid: map['player2Uid'] ?? '',
      player1Name: map['player1Name'] ?? 'Unknown',
      player2Name: map['player2Name'] ?? 'Unknown',
      p1PhotoUrl: map['p1PhotoUrl'] ?? '',
      p2PhotoUrl: map['p2PhotoUrl'] ?? '',
      p1Avatar: map['p1Avatar'] ?? 'assets/models/avatar_default.glb',
      p2Avatar: map['p2Avatar'] ?? 'assets/models/avatar_default.glb',
      status: map['status'] ?? 'playing',
      currentRound: map['currentRound'] ?? 1,
      p1Health: map['p1Health'] ?? 100,
      p2Health: map['p2Health'] ?? 100,
      p1Score: map['p1Score'] ?? 0,
      p2Score: map['p2Score'] ?? 0,
      currentQuestion: map['currentQuestion'],
      // [WAJIB] Baca dari DB (List dynamic -> List int)
      usedQuestionIndices: List<int>.from(map['usedQuestionIndices'] ?? []), 
      p1Answer: map['p1Answer'],
      p2Answer: map['p2Answer'],
      p1Time: map['p1Time'],
      p2Time: map['p2Time'],
    );
  }
}