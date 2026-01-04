import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <--- INI YANG TADI KURANG

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- 1. UPDATE PROGRESS (Saat Menang Kuis) ---
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

        if (!snapshot.exists) throw Exception("User tidak ditemukan!");

        // AMBIL DATA DENGAN AMAN
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

        int currentGold = data['gold'] ?? 0;
        int currentXp = data['current_xp'] ?? 0;
        int currentMaxXp = data['max_xp'] ?? 1000;
        int currentLevel = data['level'] ?? 1;
        int lastCompleted = data['last_completed_level'] ?? 0;

        // Logika Penambahan
        int newGold = currentGold + goldGained;
        int newXp = currentXp + xpGained;
        int newLevel = currentLevel;
        int newMaxXp = currentMaxXp;

        // Logika Naik Level
        while (newXp >= newMaxXp) {
          newLevel += 1;
          newXp = newXp - newMaxXp;
          newMaxXp = (newMaxXp * 1.2).toInt();
        }

        // Unlock Level
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
      print("Error update progress: $e");
      rethrow;
    }
  }

  // --- 2. FUNGSI BELI ITEM (SHOP) ---
  Future<void> purchaseItem(String uid, String itemId, int price) async {
    DocumentReference userRef = _db.collection('users').doc(uid);

    await _db.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(userRef);
      if (!snapshot.exists) throw Exception("User not found!");

      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      int currentGold = data['gold'] ?? 0;
      
      // Ambil list item dengan aman
      List<dynamic> rawItems = data['owned_items'] ?? [];
      List<String> ownedItems = List<String>.from(rawItems);

      if (ownedItems.contains(itemId)) {
        throw Exception("Barang sudah dimiliki!");
      }

      if (currentGold < price) {
        throw Exception("Gold tidak cukup! Main game lagi yuk.");
      }

      transaction.update(userRef, {
        'gold': currentGold - price,
        'owned_items': FieldValue.arrayUnion([itemId]),
      });
    });
  }

  // --- 3. FUNGSI PAKAI ITEM (EQUIP) ---
  Future<void> equipItem(String uid, String category, String itemId) async {
    await _db.collection('users').doc(uid).update({
      'equipped_loadout.$category': itemId,
    });
  }

  // --- 4. FUNGSI LEADERBOARD (MATCHMAKING) ---
  Stream<List<Map<String, dynamic>>> getLeaderboard() {
    return _db
        .collection('users')
        .orderBy('mmr', descending: true) // Urutkan dari MMR tertinggi
        .limit(20) // Ambil Top 20 saja
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'username': data['username'] ?? 'Unknown',
          'mmr': data['mmr'] ?? 0,
          'rank_name': data['rank_name'] ?? 'Bronze',
          'photoUrl': data['photoUrl'] ?? '',
          // Di baris inilah kita butuh import firebase_auth
          'isMe': doc.id == FirebaseAuth.instance.currentUser?.uid, 
        };
      }).toList();
    });
  }
}