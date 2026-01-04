class QuestionModel {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String buffType; // 'none', 'damage', 'defense', 'heal'

  QuestionModel({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.buffType = 'none', // Default tidak ada buff
  });
}

// --- DATA DUMMY DENGAN BUFF ---
final List<QuestionModel> grammarQuestionBank = [
  QuestionModel(question: "I ____ happy.", options: ["is", "am", "are"], correctIndex: 1, buffType: 'damage'), // Buff Serangan
  QuestionModel(question: "She ____ my teacher.", options: ["is", "am", "are"], correctIndex: 0),
  QuestionModel(question: "They ____ students.", options: ["is", "am", "are"], correctIndex: 2, buffType: 'defense'), // Buff Pertahanan
  QuestionModel(question: "He ____ pizza.", options: ["like", "likes", "liking"], correctIndex: 1),
  QuestionModel(question: "We ____ to school.", options: ["go", "goes", "going"], correctIndex: 0, buffType: 'heal'), // Buff Healing
  QuestionModel(question: "Sun ____ in the east.", options: ["rise", "rises", "rose"], correctIndex: 1),
  QuestionModel(question: "This is ____ apple.", options: ["a", "an", "the"], correctIndex: 1, buffType: 'damage'),
  QuestionModel(question: "I have ____ cat.", options: ["a", "an", "two"], correctIndex: 0),
];

// Fallback untuk Level 1
final List<QuestionModel> level1Questions = [
  QuestionModel(question: "I ____ a student.", options: ["is", "am", "are"], correctIndex: 1),
  QuestionModel(question: "She ____ happy.", options: ["is", "am", "are"], correctIndex: 0),
];