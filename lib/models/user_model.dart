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
      'body': 'default_avatar',
      'weapon': 'default_bow',
      'wings': 'none',
    },
    this.ownedItems = const ['default_avatar', 'default_bow', 'none'], 
    this.mmr = 1000,
    this.rankName = 'Bronze I',
    this.winCount = 0,
    this.lossCount = 0,
    this.lastCompletedLevel = 0,
    this.unlockedMilestones = const [],
    this.levelsProgress = const {},
  });

  // --- [PENTING] COPY WITH ---
  // Memudahkan update data sebagian tanpa menghapus data lain
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
      uid: uid, // UID tidak boleh berubah
      email: email, // Email biasanya tidak berubah lewat copyWith
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

  // --- CONVERT: FIRESTORE -> MODEL ---
  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    // Helper function agar aman jika data null atau double
    int toInt(dynamic val, int def) => (val is num) ? val.toInt() : def;

    return UserModel(
      uid: id,
      username: data['username'] ?? 'Jagoan Baru',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      bio: data['bio'] ?? 'Jagoan Inggris siap bertarung!',
      
      level: toInt(data['level'], 1),
      currentXp: toInt(data['current_xp'], 0),
      maxXp: toInt(data['max_xp'], 1000),
      totalXp: toInt(data['total_xp'], 0),
      streakCount: toInt(data['streak_count'], 0),
      lastLogin: (data['last_login'] as Timestamp?)?.toDate(),
      
      dailyWordCount: toInt(data['daily_word_count'], 0),
      dailyWordTarget: toInt(data['daily_word_target'], 10),
      dailyQuizScore: toInt(data['daily_quiz_score'], 0),

      gold: toInt(data['gold'], 0),
      equippedLoadout: Map<String, dynamic>.from(data['equipped_loadout'] ?? {}),
      ownedItems: List<String>.from(data['owned_items'] ?? ['default_avatar', 'default_bow', 'none']),
      
      mmr: toInt(data['mmr'], 1000), // Default 1000 jika null
      rankName: data['rank_name'] ?? 'Bronze I',
      winCount: toInt(data['win_count'], 0),
      lossCount: toInt(data['loss_count'], 0),
      
      lastCompletedLevel: toInt(data['last_completed_level'], 0),
      unlockedMilestones: List<String>.from(data['unlocked_milestones'] ?? []),
      levelsProgress: Map<String, dynamic>.from(data['levels_progress'] ?? {}),
    );
  }

  // --- CONVERT: MODEL -> FIRESTORE ---
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'photoUrl': photoUrl,
      'bio': bio,
      'level': level,
      'current_xp': currentXp,
      'max_xp': maxXp,
      'total_xp': totalXp,
      'streak_count': streakCount,
      'last_login': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      
      'daily_word_count': dailyWordCount,
      'daily_word_target': dailyWordTarget,
      'daily_quiz_score': dailyQuizScore,

      'gold': gold,
      'equipped_loadout': equippedLoadout,
      'owned_items': ownedItems,
      
      'mmr': mmr,
      'rank_name': rankName,
      'win_count': winCount,
      'loss_count': lossCount,
      
      'last_completed_level': lastCompletedLevel,
      'unlocked_milestones': unlockedMilestones,
      'levels_progress': levelsProgress, 
    };
  }
}