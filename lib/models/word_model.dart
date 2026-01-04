import 'package:cloud_firestore/cloud_firestore.dart';

class WordModel {
  final String id;
  final String word;        // Kata (Inggris)
  final String meaning;     // Arti (Indonesia)
  final String pronunciation; // Cara baca
  final String exampleSentence;
  final String category;    // Noun, Verb, etc.
  
  // --- SRS LOGIC FIELDS ---
  final int box;            // Kotak Leitner (1-5). Semakin tinggi, semakin jarang muncul.
  final DateTime nextReview; // Kapan harus direview lagi?
  final bool isMastered;    // Apakah sudah hafal mati?

  WordModel({
    required this.id,
    required this.word,
    required this.meaning,
    required this.pronunciation,
    required this.exampleSentence,
    required this.category,
    this.box = 1,
    required this.nextReview,
    this.isMastered = false,
  });

  // Convert dari Firestore
  factory WordModel.fromMap(Map<String, dynamic> map, String id) {
    return WordModel(
      id: id,
      word: map['word'] ?? '',
      meaning: map['meaning'] ?? '',
      pronunciation: map['pronunciation'] ?? '',
      exampleSentence: map['example_sentence'] ?? '',
      category: map['category'] ?? 'General',
      box: map['box'] ?? 1,
      nextReview: (map['next_review'] as Timestamp).toDate(),
      isMastered: map['is_mastered'] ?? false,
    );
  }

  // Convert ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'word': word,
      'meaning': meaning,
      'pronunciation': pronunciation,
      'example_sentence': exampleSentence,
      'category': category,
      'box': box,
      'next_review': Timestamp.fromDate(nextReview),
      'is_mastered': isMastered,
    };
  }
}