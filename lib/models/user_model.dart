import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  // --- IDENTITAS ---
  final String uid;
  final String username;
  final String email;
  final String photoUrl;

  // --- PROGRESI (Header UI) ---
  final int level;
  final int currentXp;
  final int maxXp;
  final int streakCount;
  final DateTime? lastLogin;

  // --- EKONOMI ---
  final int gold;

  // --- KUSTOMISASI AVATAR (Screenshot 1) ---
  // Menyimpan ID item yang sedang dipakai
  final Map<String, dynamic> equippedLoadout; 
  // Contoh isi: {'head': 'yellow_cap', 'body': 'gray_tanktop', 'wings': 'neon_wings'}

  // --- KOMPETITIF (Screenshot 6 & 7) ---
  final int mmr;
  final String rankName; // Misal: "Master III"
  final int winCount;
  final int lossCount;

  // --- STORY PROGRESS (Screenshot 2) ---
  final int lastCompletedLevel; // Misal: Level 1 selesai, berarti nilainya 1
  final List<String> unlockedMilestones; // Untuk narasi/lore (Screenshot 5)

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
    this.gold = 500, // Modal awal pemain
    this.equippedLoadout = const {
      'head': 'default',
      'body': 'default',
      'wings': 'none',
      'weapon': 'basic_bow',
    },
    this.mmr = 1000,
    this.rankName = 'Bronze I',
    this.winCount = 0,
    this.lossCount = 0,
    this.lastCompletedLevel = 0,
    this.unlockedMilestones = const [],
  });

  // --- CONVERT: FIRESTORE -> MODEL ---
  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      uid: id,
      username: data['username'] ?? 'Jagoan Baru',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      level: data['level'] ?? 1,
      currentXp: data['current_xp'] ?? 0,
      maxXp: data['max_xp'] ?? 1000,
      streakCount: data['streak_count'] ?? 0,
      lastLogin: (data['last_login'] as Timestamp?)?.toDate(),
      gold: data['gold'] ?? 0,
      equippedLoadout: Map<String, dynamic>.from(data['equipped_loadout'] ?? {}),
      mmr: data['mmr'] ?? 1000,
      rankName: data['rank_name'] ?? 'Bronze I',
      winCount: data['win_count'] ?? 0,
      lossCount: data['loss_count'] ?? 0,
      lastCompletedLevel: data['last_completed_level'] ?? 0,
      unlockedMilestones: List<String>.from(data['unlocked_milestones'] ?? []),
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
      'gold': gold,
      'equipped_loadout': equippedLoadout,
      'mmr': mmr,
      'rank_name': rankName,
      'win_count': winCount,
      'loss_count': lossCount,
      'last_completed_level': lastCompletedLevel,
      'unlocked_milestones': unlockedMilestones,
    };
  }

  // --- HELPER: COPYWITH ---
  // Sangat berguna untuk update sebagian data (misal: cuma update Gold saja)
  UserModel copyWith({
    int? gold,
    int? currentXp,
    int? level,
    Map<String, dynamic>? equippedLoadout,
    int? lastCompletedLevel,
  }) {
    return UserModel(
      uid: uid,
      username: username,
      email: email,
      gold: gold ?? this.gold,
      currentXp: currentXp ?? this.currentXp,
      level: level ?? this.level,
      equippedLoadout: equippedLoadout ?? this.equippedLoadout,
      lastCompletedLevel: lastCompletedLevel ?? this.lastCompletedLevel,
      // ... field lainnya mengikuti yang lama
    );
  }
}