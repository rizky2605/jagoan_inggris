class QuestionModel {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String buffType; // 'none', 'damage', 'defense', 'heal'

  QuestionModel({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.buffType = 'none', // Nilai default agar tidak error null
  });
}

// --- DATA DUMMY SOAL LEVEL 1 (Fallback) ---
final List<QuestionModel> level1Questions = [
  QuestionModel(question: "I ____ a student.", options: ["is", "am", "are"], correctIndex: 1, buffType: 'none'),
  QuestionModel(question: "She ____ happy.", options: ["is", "am", "are"], correctIndex: 0, buffType: 'none'),
  QuestionModel(question: "They ____ football.", options: ["play", "plays", "playing"], correctIndex: 0, buffType: 'damage'),
  QuestionModel(question: "We ____ to school.", options: ["go", "goes", "going"], correctIndex: 0, buffType: 'none'),
  QuestionModel(question: "He ____ pizza.", options: ["like", "likes", "liking"], correctIndex: 1, buffType: 'heal'),
];

// --- DATA DUMMY BANK SOAL GRAMMAR (Untuk Battle) ---
final List<QuestionModel> grammarQuestionBank = [
  QuestionModel(question: "This is ____ apple.", options: ["a", "an", "the"], correctIndex: 1, buffType: 'damage'), 
  QuestionModel(question: "She ____ my teacher.", options: ["is", "am", "are"], correctIndex: 0, buffType: 'none'),
  QuestionModel(question: "They ____ students.", options: ["is", "am", "are"], correctIndex: 2, buffType: 'defense'), 
  QuestionModel(question: "He ____ pizza.", options: ["like", "likes", "liking"], correctIndex: 1, buffType: 'damage'),
  QuestionModel(question: "We ____ to school.", options: ["go", "goes", "going"], correctIndex: 0, buffType: 'heal'), 
  QuestionModel(question: "Sun ____ in the east.", options: ["rise", "rises", "rose"], correctIndex: 1, buffType: 'none'),
  QuestionModel(question: "I have ____ cat.", options: ["a", "an", "two"], correctIndex: 0, buffType: 'none'),
  QuestionModel(question: "You ____ my friend.", options: ["is", "am", "are"], correctIndex: 2, buffType: 'heal'),
];