class SRSService {
  /// Menghitung jadwal review berikutnya berdasarkan performa
  /// [currentInterval]: Jeda hari saat ini (sebelum review)
  /// [accuracy]: Persentase kebenaran (0.0 - 1.0)
  static Map<String, dynamic> calculateNextReview(int currentInterval, double accuracy) {
    int nextInterval;
    int masteryLevel; // 1: Bronze (Bad), 2: Silver (Ok), 3: Gold (Master)

    if (accuracy < 0.5) {
      // Jika akurasi di bawah 50%, anggap LUPA (Hard) -> Reset ke 1 hari
      nextInterval = 1;
      masteryLevel = 1;
    } else if (accuracy < 0.85) {
      // Jika akurasi 50-85%, anggap SEDANG (Good) -> Interval x 1.5
      nextInterval = (currentInterval * 1.5).ceil();
      masteryLevel = 2;
    } else {
      // Jika akurasi > 85%, anggap MUDAH (Easy) -> Interval x 2.5
      // Bonus: Jika interval awal 1, langsung lompat ke 3 agar tidak bosan
      nextInterval = currentInterval == 1 ? 3 : (currentInterval * 2.5).ceil();
      masteryLevel = 3;
    }

    // Cap interval maksimal 60 hari agar tetap ada refresh
    if (nextInterval > 60) nextInterval = 60;

    DateTime nextDate = DateTime.now().add(Duration(days: nextInterval));

    return {
      'interval': nextInterval,
      'nextReviewDate': nextDate.toIso8601String(),
      'masteryLevel': masteryLevel,
      'lastReviewDate': DateTime.now().toIso8601String(),
    };
  }
}