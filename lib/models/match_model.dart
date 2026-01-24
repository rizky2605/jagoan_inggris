class MatchModel {
  final String matchId;
  final String player1Uid;
  final String player2Uid;
  final String player1Name;
  final String player2Name;
  final String p1PhotoUrl;
  final String p2PhotoUrl;
  
  // [BARU] Loadout Lengkap (Avatar + Hat + Wings + Effect)
  // Tipe Map<String, dynamic> agar fleksibel
  final Map<String, dynamic> p1Loadout; 
  final Map<String, dynamic> p2Loadout;

  final String status; // 'playing', 'finished'
  final int currentRound;
  
  final int p1Health;
  final int p2Health;
  final int p1Score;
  final int p2Score;
  
  final Map<String, dynamic>? currentQuestion;
  
  // List index soal yang sudah dipakai
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
    // Default loadout kosong jika tidak diisi
    this.p1Loadout = const {}, 
    this.p2Loadout = const {},
    required this.status,
    required this.currentRound,
    required this.p1Health,
    required this.p2Health,
    required this.p1Score,
    required this.p2Score,
    this.currentQuestion,
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
      // [PENTING] Simpan Map Loadout ke Firestore
      'p1Loadout': p1Loadout,
      'p2Loadout': p2Loadout,
      'status': status,
      'currentRound': currentRound,
      'p1Health': p1Health,
      'p2Health': p2Health,
      'p1Score': p1Score,
      'p2Score': p2Score,
      'currentQuestion': currentQuestion,
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
      
      // [PENTING] Ambil Loadout dari Firestore
      // Jika null, beri default map agar tidak error di UI
      p1Loadout: Map<String, dynamic>.from(map['p1Loadout'] ?? {
        'avatar': 'avatar1', 'hat': 'none', 'wings': 'none', 'effect': 'none'
      }),
      p2Loadout: Map<String, dynamic>.from(map['p2Loadout'] ?? {
        'avatar': 'avatar1', 'hat': 'none', 'wings': 'none', 'effect': 'none'
      }),

      status: map['status'] ?? 'playing',
      currentRound: map['currentRound'] ?? 1,
      p1Health: map['p1Health'] ?? 100,
      p2Health: map['p2Health'] ?? 100,
      p1Score: map['p1Score'] ?? 0,
      p2Score: map['p2Score'] ?? 0,
      currentQuestion: map['currentQuestion'],
      usedQuestionIndices: List<int>.from(map['usedQuestionIndices'] ?? []), 
      p1Answer: map['p1Answer'],
      p2Answer: map['p2Answer'],
      p1Time: map['p1Time'],
      p2Time: map['p2Time'],
    );
  }

  // --- HELPER METHODS (Opsional tapi Berguna) ---
  // Agar Anda mudah mendapatkan path file GLB langsung dari model ini

  String getP1AssetPath() {
    String av = p1Loadout['avatar'] ?? 'avatar1';
    String hat = p1Loadout['hat'] ?? 'none';
    String wings = p1Loadout['wings'] ?? 'none';
    return 'assets/models/${av}_${hat}_${wings}.glb';
  }

  String getP2AssetPath() {
    String av = p2Loadout['avatar'] ?? 'avatar1';
    String hat = p2Loadout['hat'] ?? 'none';
    String wings = p2Loadout['wings'] ?? 'none';
    return 'assets/models/${av}_${hat}_${wings}.glb';
  }

  String? getP1EffectPath() {
    String ef = p1Loadout['effect'] ?? 'none';
    if (ef == 'none') return null;
    return 'assets/models/$ef.glb';
  }

  String? getP2EffectPath() {
    String ef = p2Loadout['effect'] ?? 'none';
    if (ef == 'none') return null;
    return 'assets/models/$ef.glb';
  }
}