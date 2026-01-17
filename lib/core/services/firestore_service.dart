import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../models/user_model.dart';
import 'srs_service.dart'; // Pastikan file srs_service.dart ada di folder yang sama

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- 1. UPDATE PROGRESS (XP, Gold, Level Up) ---
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

        if (!snapshot.exists) {
          throw Exception("User tidak ditemukan!");
        }

        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

        // Ambil data dengan casting aman (.toInt)
        int currentGold = (data['gold'] ?? 0).toInt();
        int currentXp = (data['current_xp'] ?? 0).toInt();
        int currentMaxXp = (data['max_xp'] ?? 1000).toInt();
        int currentLevel = (data['level'] ?? 1).toInt();
        int lastCompleted = (data['last_completed_level'] ?? 0).toInt();

        // Hitung Data Baru
        int newGold = currentGold + goldGained;
        int newXp = currentXp + xpGained;
        int newLevel = currentLevel;
        int newMaxXp = currentMaxXp;

        // Logika Naik Level (Level Up)
        while (newXp >= newMaxXp) {
          newLevel += 1;
          newXp = newXp - newMaxXp;
          newMaxXp = (newMaxXp * 1.2).toInt(); // Target naik 20%
        }

        // Unlock Level Baru
        int newLastCompleted = lastCompleted;
        if (currentLevelId > lastCompleted) {
          newLastCompleted = currentLevelId;
        }

        // Update Transaksi
        transaction.update(userRef, {
          'gold': newGold,
          'current_xp': newXp,
          'max_xp': newMaxXp,
          'level': newLevel,
          'last_completed_level': newLastCompleted,
        });
      });
    } catch (e) {
      debugPrint("Error update progress: $e");
      rethrow;
    }
  }

  // --- 2. UPDATE DAILY STATS (Untuk MainScreen) ---
  Future<void> updateDailyStats({
    required String uid,
    int? wordsLearned,
    int? quizScore,
  }) async {
    Map<String, dynamic> updates = {};
    
    if (wordsLearned != null) {
      // Increment jumlah kata
      updates['daily_word_count'] = FieldValue.increment(wordsLearned);
    }
    
    if (quizScore != null) {
      // Set skor kuis terbaru
      updates['daily_quiz_score'] = quizScore;
    }

    if (updates.isNotEmpty) {
      await _db.collection('users').doc(uid).update(updates);
    }
  }

  // --- 3. SRS REVIEW SYSTEM (Spaced Repetition) ---
  Future<void> submitLevelReview(String uid, String levelId, int rating, int currentInterval) async {
    try {
      // Hitung jadwal baru pakai algoritma SRS
      Map<String, dynamic> result = SRSService.calculateNextReview(currentInterval, rating);
      
      // Update di Firestore (Nested Object)
      await _db.collection('users').doc(uid).update({
        'levels_progress.$levelId': {
          'interval': result['interval'],
          'nextReviewDate': result['nextReviewDate'],
          'lastReviewed': DateTime.now().toIso8601String(),
        }
      });
    } catch (e) {
      debugPrint("Error update SRS: $e");
    }
  }

  // --- 4. SHOP: BELI ITEM ---
  Future<void> purchaseItem(String uid, String itemId, int price) async {
    DocumentReference userRef = _db.collection('users').doc(uid);

    await _db.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(userRef);
      if (!snapshot.exists) throw Exception("User not found!");

      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      int currentGold = (data['gold'] ?? 0).toInt();
      
      List<dynamic> rawItems = data['owned_items'] ?? [];
      List<String> ownedItems = List<String>.from(rawItems);

      if (ownedItems.contains(itemId)) {
        throw Exception("Barang sudah dimiliki!");
      }

      if (currentGold < price) {
        throw Exception("Gold tidak cukup!");
      }

      transaction.update(userRef, {
        'gold': currentGold - price,
        'owned_items': FieldValue.arrayUnion([itemId]),
      });
    });
  }

  // --- 5. SHOP: PAKAI ITEM (EQUIP) ---
  Future<void> equipItem(String uid, String category, String itemId) async {
    await _db.collection('users').doc(uid).update({
      'equipped_loadout.$category': itemId,
    });
  }

  // --- 6. LEADERBOARD ---
  Stream<List<Map<String, dynamic>>> getLeaderboard() {
    return _db
        .collection('users')
        .orderBy('mmr', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'username': data['username'] ?? 'Unknown',
          'mmr': (data['mmr'] ?? 0).toInt(),
          'rank_name': data['rank_name'] ?? 'Bronze',
          'photoUrl': data['photoUrl'] ?? '',
          'isMe': doc.id == FirebaseAuth.instance.currentUser?.uid, 
        };
      }).toList();
    });
  }

  // --- 7. MATCHMAKING: CARI LAWAN ---
  Future<UserModel?> findOpponent(String myUid) async {
    try {
      QuerySnapshot snapshot = await _db.collection('users')
          .where(FieldPath.documentId, isNotEqualTo: myUid)
          .limit(20)
          .get();

      if (snapshot.docs.isEmpty) return null;

      List<DocumentSnapshot> docs = snapshot.docs;
      docs.shuffle(); // Acak lawan
      
      return UserModel.fromMap(docs.first.data() as Map<String, dynamic>, docs.first.id);
    } catch (e) {
      debugPrint("Error finding opponent: $e");
      return null;
    }
  }
}