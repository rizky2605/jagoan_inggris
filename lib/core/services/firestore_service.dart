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
      
      return UserModel(
        uid: uid, 
        username: 'Jagoan Baru', 
        email: '', 
        photoUrl: '',
      );
    });
  }

  // --- 2. UPDATE PROGRESS (DENGAN LOGIKA LEVEL UP YANG AKURAT) ---
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

        // Ambil data (Mendukung camelCase & snake_case)
        int currentGold = (data['gold'] ?? 0).toInt();
        int currentXp = (data['currentXp'] ?? data['current_xp'] ?? 0).toInt(); 
        int currentTotalXp = (data['totalXp'] ?? data['total_xp'] ?? 0).toInt(); 
        int currentLevel = (data['level'] ?? 1).toInt();
        int maxXp = (data['maxXp'] ?? data['max_xp'] ?? 100).toInt(); // Default 100 agar tidak div 0
        int lastCompleted = (data['lastCompletedLevel'] ?? data['last_completed_level'] ?? 0).toInt();

        // 1. Tambah Gold & Total XP
        int newGold = currentGold + goldGained;
        int newTotalXp = currentTotalXp + xpGained;

        // 2. Logika Level Up (XP Berjenjang)
        int accumulatedXp = currentXp + xpGained;
        int newLevel = currentLevel;
        int newMaxXp = maxXp;

        // Loop jika XP melebihi batas (Bisa naik level berkali-kali)
        while (accumulatedXp >= newMaxXp) {
          accumulatedXp -= newMaxXp;
          newLevel++;
          // Target naik level berikutnya bertambah 20% lebih sulit
          newMaxXp = (newMaxXp * 1.2).toInt(); 
        }

        // 3. Unlock Level Baru (Hanya jika level yang dimainkan lebih tinggi dari rekor)
        int newLastCompleted = lastCompleted;
        if (currentLevelId > lastCompleted) {
          newLastCompleted = currentLevelId;
        }

        // 4. Update ke Firestore (Gunakan camelCase agar konsisten dengan UserModel)
        transaction.update(userRef, {
          'gold': newGold,
          'currentXp': accumulatedXp,
          'maxXp': newMaxXp,
          'totalXp': newTotalXp,
          'level': newLevel,
          'lastCompletedLevel': newLastCompleted,
          'lastUpdate': FieldValue.serverTimestamp(), // Catatan waktu update
        });
      });
      debugPrint("Progress updated: +$xpGained XP, +$goldGained Gold");
    } catch (e) {
      debugPrint("Error update progress: $e");
    }
  }

  // --- 3. UPDATE STATISTIK HARIAN (MENGGUNAKAN INCREMENT) ---
  Future<void> updateDailyStats({
    required String uid,
    int? wordsLearned,
    int? quizScore,
  }) async {
    Map<String, dynamic> updates = {};
    
    // FieldValue.increment jauh lebih akurat untuk update counter tanpa transaksi
    if (wordsLearned != null) {
      updates['dailyWordCount'] = FieldValue.increment(wordsLearned);
    }
    
    if (quizScore != null) {
      updates['dailyQuizScore'] = FieldValue.increment(quizScore);
    }

    if (updates.isNotEmpty) {
      await _db.collection('users').doc(uid).update(updates);
    }
  }

  // --- 4. SRS REVIEW SYSTEM ---
  Future<void> submitLevelReview(String uid, String levelId, int rating, int currentInterval) async {
    try {
      // 1: Hard, 2: Good, 3: Easy
      int newInterval = 1;
      if (rating == 2) newInterval = 3;
      if (rating == 3) newInterval = (currentInterval * 2).clamp(1, 60);

      DateTime nextDate = DateTime.now().add(Duration(days: newInterval));

      await _db.collection('users').doc(uid).update({
        'levelsProgress.$levelId': { 
          'interval': newInterval,
          'nextReviewDate': nextDate.toIso8601String(),
          'lastReviewDate': FieldValue.serverTimestamp(),
          'masteryLevel': rating,
        }
      });
    } catch (e) {
      debugPrint("Error update SRS: $e");
    }
  }

  // --- 5. SHOP: BELI ITEM (MENGGUNAKAN TRANSAKSI UNTUK KEAMANAN GOLD) ---
  Future<void> purchaseItem(String uid, String itemId, int price, {String? category}) async {
    DocumentReference userRef = _db.collection('users').doc(uid);

    await _db.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(userRef);
      if (!snapshot.exists) throw Exception("User tidak ditemukan!");

      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      int currentGold = (data['gold'] ?? 0).toInt();
      
      String arrayField = (category == 'effect') ? 'unlockedEffects' : 'ownedItems';
      List<dynamic> currentItems = data[arrayField] ?? [];
      
      if (currentItems.contains(itemId)) return; // Sudah punya

      if (currentGold < price) throw Exception("Gold tidak cukup!");

      transaction.update(userRef, {
        'gold': currentGold - price,
        arrayField: FieldValue.arrayUnion([itemId]),
      });
    });
  }

  // --- 6. SHOP: EQUIP ITEM ---
  Future<void> equipItem(String uid, String category, String itemId) async {
    await _db.collection('users').doc(uid).update({
      'equippedLoadout.$category': itemId, 
    });
  }

  // --- 7. LEADERBOARD ---
  Stream<List<UserModel>> getLeaderboard() {
    return _db.collection('users')
        .orderBy('totalXp', descending: true) // Lebih fair berdasarkan total XP
        .limit(20)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return UserModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // --- 8. CARI LAWAN (MATCHMAKING ACAK) ---
  Future<UserModel?> findOpponent(String myUid) async {
    try {
      // Cari user lain yang levelnya mirip (opsional, di sini acak)
      QuerySnapshot snapshot = await _db.collection('users')
          .where(FieldPath.documentId, isNotEqualTo: myUid)
          .limit(20)
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