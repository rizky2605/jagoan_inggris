class WordModel {
  final String id;
  final String word;
  final String meaning;
  final String pronunciation;
  final String category;
  final String exampleSentence;
  final String mnemonic; // <--- FIELD BARU: Jembatan Keledai
  final int box;
  final DateTime nextReview;

  WordModel({
    required this.id,
    required this.word,
    required this.meaning,
    required this.pronunciation,
    required this.category,
    required this.exampleSentence,
    required this.mnemonic, // Tambahkan di constructor
    this.box = 1,
    required this.nextReview,
  });

  Map<String, dynamic> toMap() {
    return {
      'word': word,
      'meaning': meaning,
      'pronunciation': pronunciation,
      'category': category,
      'example_sentence': exampleSentence,
      'mnemonic': mnemonic, // Simpan ke DB
      'box': box,
      'next_review': nextReview.toIso8601String(),
    };
  }

  factory WordModel.fromMap(Map<String, dynamic> data, String id) {
    return WordModel(
      id: id,
      word: data['word'] ?? '',
      meaning: data['meaning'] ?? '',
      pronunciation: data['pronunciation'] ?? '',
      category: data['category'] ?? '',
      exampleSentence: data['example_sentence'] ?? '',
      mnemonic: data['mnemonic'] ?? '', // Ambil dari DB
      box: data['box'] ?? 1,
      nextReview: data['next_review'] != null 
          ? DateTime.parse(data['next_review']) 
          : DateTime.now(),
    );
  }
}