import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
        // Field lain menggunakan nilai default di UserModel
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

        // Ambil data dengan key snake_case
        int currentGold = (data['gold'] ?? 0).toInt();
        int currentXp = (data['current_xp'] ?? 0).toInt(); 
        int currentTotalXp = (data['total_xp'] ?? 0).toInt(); // [BARU] Ambil Total XP
        int currentLevel = (data['level'] ?? 1).toInt();
        int maxXp = (data['max_xp'] ?? 1000).toInt();
        int lastCompleted = (data['last_completed_level'] ?? 0).toInt();

        // Hitung Data Baru
        int newGold = currentGold + goldGained;
        
        // [BARU] Update Total XP (Akumulasi Seumur Hidup)
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

        // Update ke Firestore
        transaction.update(userRef, {
          'gold': newGold,
          'current_xp': accumulatedXp,
          'max_xp': newMaxXp,
          'total_xp': newTotalXp, // [BARU] Simpan Total XP
          'level': newLevel,
          'last_completed_level': newLastCompleted,
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
      updates['daily_word_count'] = FieldValue.increment(wordsLearned);
    }
    
    if (quizScore != null) {
      updates['daily_quiz_score'] = quizScore;
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
        'levels_progress.$levelId': {
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

  // --- 5. SHOP: BELI ITEM ---
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

  // --- 6. SHOP: EQUIP ITEM ---
  Future<void> equipItem(String uid, String category, String itemId) async {
    await _db.collection('users').doc(uid).update({
      'equipped_loadout.$category': itemId,
    });
  }

  // --- 7. LEADERBOARD ---
  Stream<List<Map<String, dynamic>>> getLeaderboard() {
    // [PERBAIKAN] Sorting berdasarkan 'total_xp' agar ranking adil (akumulatif)
    // Jika pakai 'current_xp', rank akan turun saat user naik level (karena current_xp reset)
    return _db
        .collection('users')
        .orderBy('total_xp', descending: true) 
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'username': data['username'] ?? 'Jagoan',
          'score': (data['total_xp'] ?? 0).toInt(), // Tampilkan Total XP
          'photoUrl': data['photoUrl'] ?? '',
          'isMe': doc.id == FirebaseAuth.instance.currentUser?.uid, 
        };
      }).toList();
    });
  }

  // --- 8. CARI LAWAN (FALLBACK MATCHMAKING) ---
  // Fungsi ini opsional jika sudah pakai MatchService, tapi berguna untuk tes
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