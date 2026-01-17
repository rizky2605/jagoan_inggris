class SRSService {
  /// Menghitung jadwal review berikutnya
  /// [lastInterval]: Jeda hari sebelumnya (default 1)
  /// [rating]: 1 (Sulit/Lupa), 2 (Ingat Sedikit), 3 (Mudah/Lancar)
  static Map<String, dynamic> calculateNextReview(int lastInterval, int rating) {
    int nextInterval;
    
    if (rating == 1) {
      // Jika sulit/lupa, reset interval jadi besok harus belajar lagi
      nextInterval = 1; 
    } else if (rating == 2) {
      // Jika ingat tapi ragu, interval dikali 1.5
      nextInterval = (lastInterval * 1.5).ceil(); 
    } else {
      // Jika mudah, interval dikali 2.5 (semakin lama munculnya)
      nextInterval = (lastInterval * 2.5).ceil();
    }

    // Hitung tanggal berikutnya
    DateTime nextDate = DateTime.now().add(Duration(days: nextInterval));

    return {
      'interval': nextInterval,
      'nextReviewDate': nextDate.toIso8601String(), // Simpan sebagai String ISO
    };
  }
}