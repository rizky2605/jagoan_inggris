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
  
  // Struktur: {'body': 'monster', 'effect': 'fire'}
  final Map<String, dynamic> equippedLoadout; 
  
  // Item fisik (baju/avatar)
  final List<String> ownedItems; 
  
  // [BARU] Efek visual (fire, lightning, etc)
  final List<String> unlockedEffects; 

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
    // Default loadout termasuk effect
    this.equippedLoadout = const {
      'body': 'avatar_default',
      'weapon': 'none',
      'effect': 'fire', // Default Effect
    },
    this.ownedItems = const ['avatar_default'], 
    // Default unlocked effects
    this.unlockedEffects = const ['fire'], 
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
    List<String>? unlockedEffects, // [BARU]
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
      unlockedEffects: unlockedEffects ?? this.unlockedEffects, // [BARU]
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
      
      level: toInt(data['level'], 1),
      currentXp: toInt(data['currentXp'], 0),
      maxXp: toInt(data['maxXp'], 1000),
      totalXp: toInt(data['totalXp'], 0),
      streakCount: toInt(data['streakCount'], 0),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
      
      dailyWordCount: toInt(data['dailyWordCount'], 0),
      dailyWordTarget: toInt(data['dailyWordTarget'], 10),
      dailyQuizScore: toInt(data['dailyQuizScore'], 0),

      gold: toInt(data['gold'], 500),
      // [FIX] Ensure 'effect' exists in loadout
      equippedLoadout: Map<String, dynamic>.from(data['equippedLoadout'] ?? {
        'body': 'avatar_default',
        'weapon': 'none',
        'effect': 'fire' 
      }),
      ownedItems: List<String>.from(data['ownedItems'] ?? ['avatar_default']),
      // [BARU] Load unlocked effects
      unlockedEffects: List<String>.from(data['unlockedEffects'] ?? ['fire']),
      
      mmr: toInt(data['mmr'], 1000),
      rankName: data['rankName'] ?? 'Bronze I',
      winCount: toInt(data['winCount'], 0), 
      lossCount: toInt(data['lossCount'], 0),
      
      lastCompletedLevel: toInt(data['lastCompletedLevel'], 0),
      unlockedMilestones: List<String>.from(data['unlockedMilestones'] ?? []),
      levelsProgress: Map<String, dynamic>.from(data['levelsProgress'] ?? {}),
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
      'unlockedEffects': unlockedEffects, // [BARU] Simpan ke DB
      
      'mmr': mmr,
      'rankName': rankName,
      'winCount': winCount,
      'lossCount': lossCount,
      
      'lastCompletedLevel': lastCompletedLevel,
      'unlockedMilestones': unlockedMilestones,
      'levelsProgress': levelsProgress, 
    };
  }
}