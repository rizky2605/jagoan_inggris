import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  // --- 1. IDENTITAS ---
  final String uid;
  final String username;
  final String email;
  final String photoUrl;
  final String bio;

  // --- 2. PROGRESI PLAYER ---
  final int level;
  final int currentXp; 
  final int maxXp;     
  final int totalXp;   
  final int streakCount;
  final DateTime? lastLogin;

  // --- 3. STATISTIK HARIAN ---
  final int dailyWordCount;   
  final int dailyWordTarget;  
  final int dailyQuizScore;   

  // --- 4. EKONOMI & KUSTOMISASI ---
  final int gold;
  final Map<String, dynamic> equippedLoadout; 
  final List<String> ownedItems; 

  // --- 5. KOMPETITIF (MATCH & RANK) ---
  final int mmr;
  final String rankName;
  final int winCount;
  final int lossCount;

  // --- 6. STORY PROGRESS & SRS ---
  final int lastCompletedLevel;
  final List<String> unlockedMilestones;
  final Map<String, dynamic> levelsProgress; 

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.photoUrl = '',
    this.bio = 'Jagoan Inggris siap bertarung!',
    this.level = 1,
    this.currentXp = 0,
    this.maxXp = 1000,
    this.totalXp = 0,
    this.streakCount = 0,
    this.lastLogin,
    this.dailyWordCount = 0, 
    this.dailyWordTarget = 10,
    this.dailyQuizScore = 0,
    this.gold = 500,
    this.equippedLoadout = const {
      'body': 'avatar_default',
      'weapon': 'none',
      'wings': 'none',
    },
    this.ownedItems = const ['avatar_default'], 
    this.mmr = 1000,
    this.rankName = 'Bronze I',
    this.winCount = 0,
    this.lossCount = 0,
    this.lastCompletedLevel = 0,
    this.unlockedMilestones = const [],
    this.levelsProgress = const {},
  });

  // --- COPY WITH ---
  UserModel copyWith({
    String? username,
    String? photoUrl,
    String? bio,
    int? level,
    int? currentXp,
    int? maxXp,
    int? totalXp,
    int? streakCount,
    DateTime? lastLogin,
    int? dailyWordCount,
    int? dailyWordTarget,
    int? dailyQuizScore,
    int? gold,
    Map<String, dynamic>? equippedLoadout,
    List<String>? ownedItems,
    int? mmr,
    String? rankName,
    int? winCount,
    int? lossCount,
    int? lastCompletedLevel,
    List<String>? unlockedMilestones,
    Map<String, dynamic>? levelsProgress,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      username: username ?? this.username,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      maxXp: maxXp ?? this.maxXp,
      totalXp: totalXp ?? this.totalXp,
      streakCount: streakCount ?? this.streakCount,
      lastLogin: lastLogin ?? this.lastLogin,
      dailyWordCount: dailyWordCount ?? this.dailyWordCount,
      dailyWordTarget: dailyWordTarget ?? this.dailyWordTarget,
      dailyQuizScore: dailyQuizScore ?? this.dailyQuizScore,
      gold: gold ?? this.gold,
      equippedLoadout: equippedLoadout ?? this.equippedLoadout,
      ownedItems: ownedItems ?? this.ownedItems,
      mmr: mmr ?? this.mmr,
      rankName: rankName ?? this.rankName,
      winCount: winCount ?? this.winCount,
      lossCount: lossCount ?? this.lossCount,
      lastCompletedLevel: lastCompletedLevel ?? this.lastCompletedLevel,
      unlockedMilestones: unlockedMilestones ?? this.unlockedMilestones,
      levelsProgress: levelsProgress ?? this.levelsProgress,
    );
  }

  // --- CONVERT: FIRESTORE -> MODEL (FIXED KEYS) ---
  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    // Helper agar tidak error jika data double/null
    int toInt(dynamic val, int def) {
      if (val == null) return def;
      if (val is int) return val;
      if (val is double) return val.toInt();
      return def;
    }

    return UserModel(
      uid: id,
      username: data['username'] ?? 'User',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      bio: data['bio'] ?? 'Jagoan Inggris siap bertarung!',
      
      // Menggunakan key camelCase agar sesuai dengan MatchService
      level: toInt(data['level'], 1),
      currentXp: toInt(data['currentXp'] ?? data['current_xp'], 0), // Support kedua format
      maxXp: toInt(data['maxXp'] ?? data['max_xp'], 1000),
      totalXp: toInt(data['totalXp'] ?? data['total_xp'], 0),
      streakCount: toInt(data['streakCount'] ?? data['streak_count'], 0),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
      
      dailyWordCount: toInt(data['dailyWordCount'] ?? data['daily_word_count'], 0),
      dailyWordTarget: toInt(data['dailyWordTarget'] ?? data['daily_word_target'], 10),
      dailyQuizScore: toInt(data['dailyQuizScore'] ?? data['daily_quiz_score'], 0),

      gold: toInt(data['gold'], 500),
      equippedLoadout: Map<String, dynamic>.from(data['equippedLoadout'] ?? data['equipped_loadout'] ?? {
        'body': 'avatar_default',
        'weapon': null,
        'wings': null
      }),
      ownedItems: List<String>.from(data['ownedItems'] ?? data['owned_items'] ?? ['avatar_default']),
      
      // [FIX UTAMA] Pastikan ini membaca 'winCount' (camelCase)
      mmr: toInt(data['mmr'], 1000),
      rankName: data['rankName'] ?? 'Bronze I',
      winCount: toInt(data['winCount'] ?? data['win_count'], 0), 
      lossCount: toInt(data['lossCount'] ?? data['loss_count'], 0),
      
      lastCompletedLevel: toInt(data['lastCompletedLevel'] ?? data['last_completed_level'], 0),
      unlockedMilestones: List<String>.from(data['unlockedMilestones'] ?? []),
      levelsProgress: Map<String, dynamic>.from(data['levelsProgress'] ?? {}),
    );
  }

  // --- CONVERT: MODEL -> FIRESTORE (STANDARD CAMELCASE) ---
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'photoUrl': photoUrl,
      'bio': bio,
      
      'level': level,
      'currentXp': currentXp,
      'maxXp': maxXp,
      'totalXp': totalXp,
      'streakCount': streakCount,
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      
      'dailyWordCount': dailyWordCount,
      'dailyWordTarget': dailyWordTarget,
      'dailyQuizScore': dailyQuizScore,

      'gold': gold,
      'equippedLoadout': equippedLoadout,
      'ownedItems': ownedItems,
      
      'mmr': mmr,
      'rankName': rankName,
      'winCount': winCount,   // Konsisten camelCase
      'lossCount': lossCount, // Konsisten camelCase
      
      'lastCompletedLevel': lastCompletedLevel,
      'unlockedMilestones': unlockedMilestones,
      'levelsProgress': levelsProgress, 
    };
  }
}