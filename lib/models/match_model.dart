class MatchModel {
  final String matchId;
  final String player1Uid; // Host
  final String player2Uid; // Challenger
  final String player1Name;
  final String player2Name;
  
  // --- [TAMBAHAN BARU] FOTO PROFILE ---
  final String p1PhotoUrl;
  final String p2PhotoUrl;
  
  // Status Game
  final String status; // 'waiting', 'playing', 'finished'
  final int currentRound;
  
  // State Player (HP & Jawaban)
  final int p1Health;
  final int p2Health;
  final int p1Score;
  final int p2Score;
  
  // Logika Jawaban Ronde Ini
  final String? p1Answer; // 'A', 'B', 'C', 'D' atau null
  final int? p1Time;      // Waktu menjawab (milliseconds)
  final String? p2Answer;
  final int? p2Time;

  // Soal Ronde Ini
  final Map<String, dynamic>? currentQuestion;

  MatchModel({
    required this.matchId,
    required this.player1Uid,
    required this.player2Uid,
    required this.player1Name,
    required this.player2Name,
    this.p1PhotoUrl = '', // Default kosong jika tidak ada foto
    this.p2PhotoUrl = '', // Default kosong jika tidak ada foto
    this.status = 'waiting',
    this.currentRound = 1,
    this.p1Health = 100,
    this.p2Health = 100,
    this.p1Score = 0,
    this.p2Score = 0,
    this.p1Answer,
    this.p1Time,
    this.p2Answer,
    this.p2Time,
    this.currentQuestion,
  });

  // --- SERIALISASI (Object ke Map Database) ---
  Map<String, dynamic> toMap() {
    return {
      'matchId': matchId,
      'player1Uid': player1Uid,
      'player2Uid': player2Uid,
      'player1Name': player1Name,
      'player2Name': player2Name,
      'p1PhotoUrl': p1PhotoUrl, // Simpan ke DB
      'p2PhotoUrl': p2PhotoUrl, // Simpan ke DB
      'status': status,
      'currentRound': currentRound,
      'p1Health': p1Health,
      'p2Health': p2Health,
      'p1Score': p1Score,
      'p2Score': p2Score,
      'p1Answer': p1Answer,
      'p1Time': p1Time,
      'p2Answer': p2Answer,
      'p2Time': p2Time,
      'currentQuestion': currentQuestion,
    };
  }

  // --- DESERIALISASI (Map Database ke Object) ---
  factory MatchModel.fromMap(Map<String, dynamic> map) {
    return MatchModel(
      matchId: map['matchId'] ?? '',
      player1Uid: map['player1Uid'] ?? '',
      player2Uid: map['player2Uid'] ?? '',
      player1Name: map['player1Name'] ?? '',
      player2Name: map['player2Name'] ?? '',
      p1PhotoUrl: map['p1PhotoUrl'] ?? '', // Ambil dari DB
      p2PhotoUrl: map['p2PhotoUrl'] ?? '', // Ambil dari DB
      status: map['status'] ?? 'waiting',
      currentRound: map['currentRound'] ?? 1,
      p1Health: map['p1Health'] ?? 100,
      p2Health: map['p2Health'] ?? 100,
      p1Score: map['p1Score'] ?? 0,
      p2Score: map['p2Score'] ?? 0,
      p1Answer: map['p1Answer'],
      p1Time: map['p1Time'],
      p2Answer: map['p2Answer'],
      p2Time: map['p2Time'],
      currentQuestion: map['currentQuestion'],
    );
  }
}