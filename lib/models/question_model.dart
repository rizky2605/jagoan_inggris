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

// --- GUDANG SOAL GRAMMAR (Untuk Ulasan Harian) ---
final List<QuestionModel> grammarQuestionBank = [
  // LEVEL 1: TO BE
  QuestionModel(question: "I ____ happy.", options: ["is", "am", "are"], correctIndex: 1),
  QuestionModel(question: "She ____ my teacher.", options: ["is", "am", "are"], correctIndex: 0),
  QuestionModel(question: "They ____ students.", options: ["is", "am", "are"], correctIndex: 2),
  
  // LEVEL 2: SIMPLE PRESENT
  QuestionModel(question: "He ____ pizza.", options: ["like", "likes", "liking"], correctIndex: 1),
  QuestionModel(question: "We ____ to school.", options: ["go", "goes", "going"], correctIndex: 0),
  QuestionModel(question: "Sun ____ in the east.", options: ["rise", "rises", "rose"], correctIndex: 1),

  // LEVEL 3: ARTICLES
  QuestionModel(question: "This is ____ apple.", options: ["a", "an", "the"], correctIndex: 1),
  QuestionModel(question: "I have ____ cat.", options: ["a", "an", "two"], correctIndex: 0),
  
  // LEVEL 4: PAST TENSE
  QuestionModel(question: "I ____ football yesterday.", options: ["play", "played", "playing"], correctIndex: 1),
  QuestionModel(question: "She ____ to Paris last year.", options: ["go", "went", "gone"], correctIndex: 1),
];