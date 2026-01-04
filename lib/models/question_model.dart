class QuestionModel {
  final String question;
  final List<String> options;
  final int correctIndex; // Index jawaban benar (0, 1, atau 2)

  QuestionModel({
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}

// --- CONTOH BANK SOAL LEVEL 1 (Subject To Be) ---
// Nanti ini bisa kita ambil dari Firebase, tapi untuk tes kita pakai dummy dulu.
final List<QuestionModel> level1Questions = [
  QuestionModel(
    question: "I ____ a student.",
    options: ["is", "am", "are"],
    correctIndex: 1, // "am"
  ),
  QuestionModel(
    question: "She ____ happy today.",
    options: ["is", "am", "are"],
    correctIndex: 0, // "is"
  ),
  QuestionModel(
    question: "They ____ playing football.",
    options: ["is", "am", "are"],
    correctIndex: 2, // "are"
  ),
  QuestionModel(
    question: "It ____ a cat.",
    options: ["are", "am", "is"],
    correctIndex: 2, // "is"
  ),
  QuestionModel(
    question: "____ you hungry?",
    options: ["Is", "Am", "Are"],
    correctIndex: 2, // "Are"
  ),
];