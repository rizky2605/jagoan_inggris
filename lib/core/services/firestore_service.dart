import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- 1. STREAM USER UTAMA ---
  Stream<UserModel> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserModel.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
      }
      
      // Fallback jika data kosong (User Baru)
      return UserModel(
        uid: uid, 
        username: 'Jagoan Baru', 
        email: '', 
        photoUrl: '',
      );
    });
  }

  // --- 2. UPDATE PROGRESS (XP, Gold, Level Up, Total XP) ---
  Future<void> updateUserProgress({
    required String uid,
    required int goldGained,
    required int xpGained,
    required int currentLevelId,
  }) async {
    try {
      DocumentReference userRef = _db.collection('users').doc(uid);

      await _db.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userRef);

        if (!snapshot.exists) return;

        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

        // Ambil data dengan key snake_case (pastikan konsisten dengan UserModel.toMap)
        int currentGold = (data['gold'] ?? 0).toInt();
        int currentXp = (data['currentXp'] ?? data['current_xp'] ?? 0).toInt(); 
        int currentTotalXp = (data['totalXp'] ?? data['total_xp'] ?? 0).toInt(); 
        int currentLevel = (data['level'] ?? 1).toInt();
        int maxXp = (data['maxXp'] ?? data['max_xp'] ?? 1000).toInt();
        int lastCompleted = (data['lastCompletedLevel'] ?? data['last_completed_level'] ?? 0).toInt();

        // Hitung Data Baru
        int newGold = currentGold + goldGained;
        
        // Update Total XP (Akumulasi Seumur Hidup)
        int newTotalXp = currentTotalXp + xpGained;

        // Update Current XP (Untuk progress bar level ini)
        int accumulatedXp = currentXp + xpGained;
        int newLevel = currentLevel;
        int newMaxXp = maxXp;

        // Logika Level Up (XP berlebih lanjut ke level berikutnya)
        while (accumulatedXp >= newMaxXp) {
          newLevel++;
          accumulatedXp -= newMaxXp; // Sisa XP
          newMaxXp = (newMaxXp * 1.2).toInt(); // Target naik 20%
        }

        // Unlock Level Baru
        int newLastCompleted = lastCompleted;
        if (currentLevelId > lastCompleted) {
          newLastCompleted = currentLevelId;
        }

        // Update ke Firestore (Gunakan camelCase sesuai UserModel toMap agar konsisten)
        transaction.update(userRef, {
          'gold': newGold,
          'currentXp': accumulatedXp,
          'maxXp': newMaxXp,
          'totalXp': newTotalXp,
          'level': newLevel,
          'lastCompletedLevel': newLastCompleted,
        });
      });
    } catch (e) {
      debugPrint("Error update progress: $e");
    }
  }

  // --- 3. UPDATE STATISTIK HARIAN ---
  Future<void> updateDailyStats({
    required String uid,
    int? wordsLearned,
    int? quizScore,
  }) async {
    Map<String, dynamic> updates = {};
    
    if (wordsLearned != null) {
      updates['dailyWordCount'] = FieldValue.increment(wordsLearned);
    }
    
    if (quizScore != null) {
      updates['dailyQuizScore'] = quizScore;
    }

    if (updates.isNotEmpty) {
      await _db.collection('users').doc(uid).update(updates);
    }
  }

  // --- 4. SRS REVIEW SYSTEM ---
  Future<void> submitLevelReview(String uid, String levelId, int rating, int currentInterval) async {
    try {
      // Logika Interval Manual (SRS)
      // 1: Hard (Reset 1 hari), 2: Good (3 hari), 3: Easy (x2 hari)
      int newInterval = 1;
      if (rating == 2) newInterval = 3;
      if (rating == 3) newInterval = (currentInterval * 2).clamp(1, 60);

      DateTime nextDate = DateTime.now().add(Duration(days: newInterval));

      await _db.collection('users').doc(uid).update({
        'levelsProgress.$levelId': { // Gunakan camelCase
          'interval': newInterval,
          'nextReviewDate': nextDate.toIso8601String(),
          'lastReviewDate': DateTime.now().toIso8601String(),
          'masteryLevel': rating,
        }
      });
    } catch (e) {
      debugPrint("Error update SRS: $e");
    }
  }

  // --- 5. SHOP: BELI ITEM (SUPPORT EFEK) ---
  Future<void> purchaseItem(String uid, String itemId, int price, {String? category}) async {
    DocumentReference userRef = _db.collection('users').doc(uid);

    await _db.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(userRef);
      if (!snapshot.exists) throw Exception("User not found!");

      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      int currentGold = (data['gold'] ?? 0).toInt();
      
      // Tentukan array tujuan berdasarkan kategori
      String arrayField = (category == 'effect') ? 'unlockedEffects' : 'ownedItems';
      // Support camelCase dan snake_case untuk kompatibilitas data lama
      List<dynamic> currentItems = data[arrayField] ?? data[arrayField == 'unlockedEffects' ? 'unlocked_effects' : 'owned_items'] ?? [];
      
      if (currentItems.contains(itemId)) {
        // Jika sudah punya, tidak perlu throw error, cukup return
        return; 
      }

      if (currentGold < price) {
        throw Exception("Gold tidak cukup!");
      }

      transaction.update(userRef, {
        'gold': currentGold - price,
        arrayField: FieldValue.arrayUnion([itemId]),
      });
    });
  }

  // --- 6. SHOP: EQUIP ITEM ---
  Future<void> equipItem(String uid, String category, String itemId) async {
    // category bisa 'body', 'head', 'wings', 'effect'
    await _db.collection('users').doc(uid).update({
      'equippedLoadout.$category': itemId, // Gunakan camelCase
    });
  }

  // --- 7. LEADERBOARD ---
  Stream<List<UserModel>> getLeaderboard() {
    return _db.collection('users')
        .orderBy('mmr', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return UserModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // --- 8. CARI LAWAN (FALLBACK MATCHMAKING) ---
  Future<UserModel?> findOpponent(String myUid) async {
    try {
      QuerySnapshot snapshot = await _db.collection('users')
          .where(FieldPath.documentId, isNotEqualTo: myUid)
          .limit(10)
          .get();

      if (snapshot.docs.isEmpty) return null;

      List<DocumentSnapshot> docs = snapshot.docs;
      docs.shuffle();
      
      return UserModel.fromMap(docs.first.data() as Map<String, dynamic>, docs.first.id);
    } catch (e) {
      debugPrint("Error finding opponent: $e");
      return null;
    }
  }
}