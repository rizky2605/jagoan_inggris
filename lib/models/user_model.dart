import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  // --- IDENTITAS ---
  final String uid;
  final String username;
  final String email;
  final String photoUrl;

  // --- PROGRESI PLAYER ---
  final int level;
  final int currentXp;
  final int maxXp;
  final int streakCount;
  final DateTime? lastLogin;

  // --- STATISTIK HARIAN ---
  final int dailyWordCount;   // Kata yg sudah dipelajari hari ini
  final int dailyWordTarget;  // Target kata per hari
  final int dailyQuizScore;   // Skor kuis hari ini (0-100)

  // --- EKONOMI & KUSTOMISASI ---
  final int gold;
  final Map<String, dynamic> equippedLoadout; 
  final List<String> ownedItems; 

  // --- KOMPETITIF (MATCH) ---
  final int mmr;
  final String rankName;
  final int winCount;
  final int lossCount;

  // --- STORY PROGRESS & SRS ---
  final int lastCompletedLevel;
  final List<String> unlockedMilestones;
  final Map<String, dynamic> levelsProgress; // Data Review SRS

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.photoUrl = '',
    this.level = 1,
    this.currentXp = 0,
    this.maxXp = 1000,
    this.streakCount = 0,
    this.lastLogin,
    // Default Daily Stats
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
    this.levelsProgress = const {}, // Default kosong untuk SRS
  });

  // --- CONVERT: FIRESTORE -> MODEL (DENGAN SAFE CASTING) ---
  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      uid: id,
      username: data['username'] ?? 'Jagoan Baru',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      
      // Safe Casting .toInt()
      level: (data['level'] ?? 1).toInt(),
      currentXp: (data['current_xp'] ?? 0).toInt(),
      maxXp: (data['max_xp'] ?? 1000).toInt(),
      streakCount: (data['streak_count'] ?? 0).toInt(),
      lastLogin: (data['last_login'] as Timestamp?)?.toDate(),
      
      // Data Harian
      dailyWordCount: (data['daily_word_count'] ?? 0).toInt(),
      dailyWordTarget: (data['daily_word_target'] ?? 10).toInt(),
      dailyQuizScore: (data['daily_quiz_score'] ?? 0).toInt(),

      // Ekonomi
      gold: (data['gold'] ?? 0).toInt(),
      equippedLoadout: Map<String, dynamic>.from(data['equipped_loadout'] ?? {}),
      ownedItems: List<String>.from(data['owned_items'] ?? ['default_avatar', 'default_bow', 'none']),
      
      // Kompetitif
      mmr: (data['mmr'] ?? 1000).toInt(),
      rankName: data['rank_name'] ?? 'Bronze I',
      winCount: (data['win_count'] ?? 0).toInt(),
      lossCount: (data['loss_count'] ?? 0).toInt(),
      
      // Story & SRS
      lastCompletedLevel: (data['last_completed_level'] ?? 0).toInt(),
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
      'level': level,
      'current_xp': currentXp,
      'max_xp': maxXp,
      'streak_count': streakCount,
      'last_login': lastLogin,
      
      // Data Harian
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
      
      // Story & SRS
      'last_completed_level': lastCompletedLevel,
      'unlocked_milestones': unlockedMilestones,
      'levels_progress': levelsProgress, // Jangan lupa simpan ini!
    };
  }
}