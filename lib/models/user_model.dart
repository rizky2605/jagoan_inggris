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
  
  // Struktur Loadout:
  // {
  //   'body': 'avatar1',   (Michelle) atau 'avatar2' (Nayla)
  //   'head': 'hat1',      (Witch Hat) atau 'none'
  //   'wings': 'wings1',   (Phoenix) atau 'none'
  //   'effect': 'fire'     (Api) atau 'lightning' (Petir)
  // }
  final Map<String, dynamic> equippedLoadout; 
  
  // Item fisik yang dimiliki (ID: avatar1, avatar2, hat1, wings1, none)
  final List<String> ownedItems; 
  
  // Efek visual yang terbuka (ID: fire, lightning)
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
    
    // [DEFAULT LOADOUT]
    // Sesuai dengan aset default Anda: Michelle (avatar1) tanpa topi/sayap, efek api.
    this.equippedLoadout = const {
      'body': 'avatar1',
      'head': 'none',
      'wings': 'none',
      'effect': 'fire', 
    },
    
    // Item awal: Avatar 1 & Avatar 2 (opsional), dan 'none'
    this.ownedItems = const ['avatar1', 'avatar2', 'none'], 
    
    // Efek awal: Fire
    this.unlockedEffects = const ['fire'], 
    
    this.mmr = 1000,
    this.rankName = 'Bronze I',
    this.winCount = 0,
    this.lossCount = 0,
    this.lastCompletedLevel = 0,
    this.unlockedMilestones = const [],
    this.levelsProgress = const {},
  });

  // ===========================================================================
  // [HELPER 1] AVATAR PATH (GLB)
  // Menggabungkan body + hat + wings menjadi satu nama file
  // Contoh output: "assets/models/avatar1_hat1_none.glb"
  // ===========================================================================
  String get fullAvatarPath {
    String body = equippedLoadout['body'] ?? 'avatar1';
    String head = equippedLoadout['head'] ?? 'none';
    String wings = equippedLoadout['wings'] ?? 'none';
    
    return 'assets/models/${body}_${head}_${wings}.glb';
  }

  // ===========================================================================
  // [HELPER 2] EFFECT PATH (JSON / LOTTIE)
  // [PERBAIKAN] Mengarah ke folder 'assets/effects/' dengan format .json
  // Contoh output: "assets/effects/fire.json"
  // ===========================================================================
  String get effectPath {
    String effect = equippedLoadout['effect'] ?? 'fire';
    return 'assets/effects/$effect.json'; 
  }

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
    List<String>? unlockedEffects,
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
      unlockedEffects: unlockedEffects ?? this.unlockedEffects,
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
      
      // Mengamankan loadout jika data null di DB
      equippedLoadout: Map<String, dynamic>.from(data['equippedLoadout'] ?? {
        'body': 'avatar1',
        'head': 'none',
        'wings': 'none',
        'effect': 'fire' 
      }),
      
      ownedItems: List<String>.from(data['ownedItems'] ?? ['avatar1', 'avatar2', 'none']),
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
      'unlockedEffects': unlockedEffects, 
      
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