import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  // --- IDENTITAS ---
  final String uid;
  final String username;
  final String email;
  final String photoUrl;

  // --- PROGRESI ---
  final int level;
  final int currentXp;
  final int maxXp;
  final int streakCount;
  final DateTime? lastLogin;

  // --- EKONOMI & KUSTOMISASI ---
  final int gold;
  final Map<String, dynamic> equippedLoadout; // Apa yang dipakai sekarang
  final List<String> ownedItems; // <--- UPDATE: Daftar item yang dimiliki

  // --- KOMPETITIF ---
  final int mmr;
  final String rankName;
  final int winCount;
  final int lossCount;

  // --- STORY PROGRESS ---
  final int lastCompletedLevel;
  final List<String> unlockedMilestones;

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
    this.gold = 500,
    this.equippedLoadout = const {
      'body': 'default_avatar', // Default item
      'weapon': 'default_bow',
      'wings': 'none',
    },
    // Item awal yang pasti dimiliki
    this.ownedItems = const ['default_avatar', 'default_bow', 'none'], 
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
      ownedItems: List<String>.from(data['owned_items'] ?? ['default_avatar', 'default_bow', 'none']),
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
      'owned_items': ownedItems, // <--- Simpan ke database
      'mmr': mmr,
      'rank_name': rankName,
      'win_count': winCount,
      'loss_count': lossCount,
      'last_completed_level': lastCompletedLevel,
      'unlocked_milestones': unlockedMilestones,
    };
  }
}