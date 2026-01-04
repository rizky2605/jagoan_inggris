import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fungsi untuk Update Data User setelah menang Battle
  Future<void> updateUserProgress({
    required String uid,
    required int goldGained,
    required int xpGained,
    required int currentLevelId,
  }) async {
    try {
      DocumentReference userRef = _db.collection('users').doc(uid);

      // Gunakan Transaction agar data aman dan sinkron
      await _db.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userRef);

        if (!snapshot.exists) {
          throw Exception("User tidak ditemukan!");
        }

        // 1. Ambil data saat ini
        int currentGold = snapshot.get('gold') ?? 0;
        int currentXp = snapshot.get('current_xp') ?? 0;
        int currentMaxXp = snapshot.get('max_xp') ?? 1000;
        int currentLevel = snapshot.get('level') ?? 1;
        int lastCompleted = snapshot.get('last_completed_level') ?? 0;

        // 2. Hitung penambahan
        int newGold = currentGold + goldGained;
        int newXp = currentXp + xpGained;
        int newLevel = currentLevel;
        int newMaxXp = currentMaxXp;

        // 3. Logika Naik Level (Level Up)
        // Jika XP penuh, level naik dan sisa XP dibawa ke level baru
        while (newXp >= newMaxXp) {
          newLevel += 1;
          newXp = newXp - newMaxXp; 
          newMaxXp = (newMaxXp * 1.2).toInt(); // Target XP makin susah (naik 20%)
        }

        // 4. Buka Level Selanjutnya (Story Unlock)
        int newLastCompleted = lastCompleted;
        if (currentLevelId > lastCompleted) {
          newLastCompleted = currentLevelId;
        }

        // 5. Update ke Firebase
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
}