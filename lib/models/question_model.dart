class QuestionModel {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String buffType; // 'none', 'damage', 'defense', 'heal'

  QuestionModel({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.buffType = 'none',
  });
}

// --- DATA SOAL PER LEVEL (Level 1 - 5) ---
final Map<int, List<QuestionModel>> levelQuestions = {
  
  // LEVEL 1: Subject & To Be
  1: [
    QuestionModel(question: "I ____ a student.", options: ["is", "am", "are"], correctIndex: 1, buffType: 'damage'),
    QuestionModel(question: "She ____ happy.", options: ["is", "am", "are"], correctIndex: 0, buffType: 'none'),
    QuestionModel(question: "They ____ my friends.", options: ["is", "am", "are"], correctIndex: 2, buffType: 'defense'),
    QuestionModel(question: "____ you ready?", options: ["Is", "Am", "Are"], correctIndex: 2, buffType: 'damage'),
    QuestionModel(question: "It ____ a cat.", options: ["is", "am", "are"], correctIndex: 0, buffType: 'heal'),
  ],

  // LEVEL 2: Simple Present
  2: [
    QuestionModel(question: "He ____ pizza.", options: ["like", "likes", "liking"], correctIndex: 1, buffType: 'damage'),
    QuestionModel(question: "We ____ football.", options: ["play", "plays", "playing"], correctIndex: 0, buffType: 'none'),
    QuestionModel(question: "Sun ____ in the east.", options: ["rise", "rises", "rising"], correctIndex: 1, buffType: 'damage'),
    QuestionModel(question: "She ____ not know.", options: ["do", "does", "is"], correctIndex: 1, buffType: 'defense'),
    QuestionModel(question: "____ they study?", options: ["Do", "Does", "Are"], correctIndex: 0, buffType: 'heal'),
  ],

  // LEVEL 3: Articles (A/An/The)
  3: [
    QuestionModel(question: "I have ____ apple.", options: ["a", "an", "the"], correctIndex: 1, buffType: 'damage'),
    QuestionModel(question: "He is ____ doctor.", options: ["a", "an", "two"], correctIndex: 0, buffType: 'none'),
    QuestionModel(question: "____ sun is hot.", options: ["A", "An", "The"], correctIndex: 2, buffType: 'defense'),
    QuestionModel(question: "She needs ____ umbrella.", options: ["a", "an", "the"], correctIndex: 1, buffType: 'damage'),
    QuestionModel(question: "It is ____ hour ago.", options: ["a", "an", "the"], correctIndex: 1, buffType: 'heal'), 
  ],

  // LEVEL 4: Plural Nouns
  4: [
    QuestionModel(question: "I have two ____.", options: ["cat", "cats", "cates"], correctIndex: 1, buffType: 'damage'),
    QuestionModel(question: "Three ____ are playing.", options: ["child", "childs", "children"], correctIndex: 2, buffType: 'defense'),
    QuestionModel(question: "Put the ____ in the box.", options: ["watch", "watches", "watchs"], correctIndex: 1, buffType: 'none'),
    QuestionModel(question: "My ____ hurt.", options: ["foot", "foots", "feet"], correctIndex: 2, buffType: 'heal'),
    QuestionModel(question: "There are many ____.", options: ["person", "people", "persons"], correctIndex: 1, buffType: 'damage'),
  ],

  // LEVEL 5: Mini Boss (Ujian Dasar I - Campuran Level 1-4)
  5: [
    QuestionModel(question: "She ____ ____ apple.", options: ["has / a", "have / an", "has / an"], correctIndex: 2, buffType: 'damage'),
    QuestionModel(question: "They ____ happy today.", options: ["is", "am", "are"], correctIndex: 2, buffType: 'defense'),
    QuestionModel(question: "____ he play games?", options: ["Do", "Does", "Is"], correctIndex: 1, buffType: 'damage'),
    QuestionModel(question: "Look at those ____!", options: ["mouse", "mouses", "mice"], correctIndex: 2, buffType: 'heal'),
    QuestionModel(question: "We ____ to school.", options: ["go", "goes", "going"], correctIndex: 0, buffType: 'damage'),
  ],

  // --- SECTION 2: PEMULA (Beginner) ---

  // LEVEL 6: Present Continuous (Sedang dilakukan)
  6: [
    QuestionModel(question: "I am ____ right now.", options: ["eat", "ate", "eating"], correctIndex: 2, buffType: 'damage'),
    QuestionModel(question: "She is ____ TV.", options: ["watch", "watching", "watches"], correctIndex: 1, buffType: 'none'),
    QuestionModel(question: "They ____ sleeping.", options: ["is", "am", "are"], correctIndex: 2, buffType: 'defense'),
    QuestionModel(question: "Look! It is ____.", options: ["rain", "rains", "raining"], correctIndex: 2, buffType: 'heal'),
    QuestionModel(question: "Are you ____?", options: ["listen", "listens", "listening"], correctIndex: 2, buffType: 'damage'),
  ],

  // LEVEL 7: Pronouns (Kata Ganti)
  7: [
    QuestionModel(question: "____ am a student.", options: ["I", "Me", "My"], correctIndex: 0, buffType: 'damage'),
    QuestionModel(question: "This book belongs to ____.", options: ["he", "him", "his"], correctIndex: 1, buffType: 'defense'),
    QuestionModel(question: "She loves ____ cat.", options: ["she", "her", "hers"], correctIndex: 1, buffType: 'heal'),
    QuestionModel(question: "Give it to ____.", options: ["we", "us", "our"], correctIndex: 1, buffType: 'none'),
    QuestionModel(question: "____ are my friends.", options: ["They", "Them", "Their"], correctIndex: 0, buffType: 'damage'),
  ],

  // LEVEL 8: Adjectives (Kata Sifat)
  8: [
    QuestionModel(question: "The elephant is ____.", options: ["small", "big", "thin"], correctIndex: 1, buffType: 'damage'),
    QuestionModel(question: "The candy tastes ____.", options: ["sweet", "salty", "bitter"], correctIndex: 0, buffType: 'heal'),
    QuestionModel(question: "He runs very ____.", options: ["fast", "slow", "lazy"], correctIndex: 0, buffType: 'defense'),
    QuestionModel(question: "The movie was ____.", options: ["boring", "bored", "bore"], correctIndex: 0, buffType: 'none'),
    QuestionModel(question: "She is a ____ girl.", options: ["beauty", "beautiful", "beautify"], correctIndex: 1, buffType: 'damage'),
  ],

  // LEVEL 9: Possessive ('s / Kepemilikan)
  9: [
    QuestionModel(question: "This is ____ car.", options: ["John", "John's", "Johns"], correctIndex: 1, buffType: 'damage'),
    QuestionModel(question: "Where is ____ bag?", options: ["you", "your", "yours"], correctIndex: 1, buffType: 'defense'),
    QuestionModel(question: "That house is ____.", options: ["my", "mine", "me"], correctIndex: 1, buffType: 'heal'),
    QuestionModel(question: "The ____ tail is long.", options: ["cat", "cats", "cat's"], correctIndex: 2, buffType: 'none'),
    QuestionModel(question: "Is this pen ____?", options: ["her", "hers", "she"], correctIndex: 1, buffType: 'damage'),
  ],

  // LEVEL 10: Big Boss (Ujian Dasar II - Campuran Level 6-9)
  10: [
    QuestionModel(question: "Listen! Someone is ____.", options: ["sing", "sings", "singing"], correctIndex: 2, buffType: 'damage'),
    QuestionModel(question: "____ car is red.", options: ["He", "Him", "His"], correctIndex: 2, buffType: 'defense'),
    QuestionModel(question: "They are very ____.", options: ["happiness", "happy", "happily"], correctIndex: 1, buffType: 'heal'),
    QuestionModel(question: "It is ____ not yours.", options: ["mine", "my", "me"], correctIndex: 0, buffType: 'damage'),
    QuestionModel(question: "The baby is ____.", options: ["cries", "cry", "crying"], correctIndex: 2, buffType: 'damage'),
  ],

  // --- SECTION 3: MENENGAH (Intermediate) ---

  // LEVEL 11: Past Tense (Masa Lampau)
  11: [
    QuestionModel(question: "I ____ to the park yesterday.", options: ["go", "went", "gone"], correctIndex: 1, buffType: 'damage'),
    QuestionModel(question: "She ____ happy last night.", options: ["is", "was", "were"], correctIndex: 1, buffType: 'defense'),
    QuestionModel(question: "They ____ football two days ago.", options: ["played", "play", "playing"], correctIndex: 0, buffType: 'none'),
    QuestionModel(question: "We ____ not see him.", options: ["do", "did", "does"], correctIndex: 1, buffType: 'heal'),
    QuestionModel(question: "____ you sad?", options: ["Was", "Were", "Did"], correctIndex: 1, buffType: 'damage'),
  ],

  // LEVEL 12: Future Tense (Masa Depan - Will)
  12: [
    QuestionModel(question: "I ____ visit my grandma.", options: ["will", "would", "am"], correctIndex: 0, buffType: 'damage'),
    QuestionModel(question: "She will ____ a cake.", options: ["make", "makes", "making"], correctIndex: 0, buffType: 'heal'),
    QuestionModel(question: "____ you help me?", options: ["Will", "Are", "Is"], correctIndex: 0, buffType: 'defense'),
    QuestionModel(question: "They ____ not come.", options: ["will", "are", "do"], correctIndex: 0, buffType: 'none'),
    QuestionModel(question: "It ____ rain tomorrow.", options: ["will", "is", "was"], correctIndex: 0, buffType: 'damage'),
  ],

  // LEVEL 13: Modals (Can/Must/Should)
  13: [
    QuestionModel(question: "I ____ swim very fast.", options: ["can", "cans", "canning"], correctIndex: 0, buffType: 'damage'),
    QuestionModel(question: "You ____ study hard.", options: ["must", "musts", "is"], correctIndex: 0, buffType: 'defense'),
    QuestionModel(question: "She ____ not drive.", options: ["can", "do", "is"], correctIndex: 0, buffType: 'none'),
    QuestionModel(question: "____ I go to the toilet?", options: ["May", "Will", "Must"], correctIndex: 0, buffType: 'heal'),
    QuestionModel(question: "We ____ respect elders.", options: ["should", "will", "can"], correctIndex: 0, buffType: 'damage'),
  ],

  // LEVEL 14: Prepositions (In/On/At)
  14: [
    QuestionModel(question: "The book is ____ the table.", options: ["in", "on", "at"], correctIndex: 1, buffType: 'damage'),
    QuestionModel(question: "I was born ____ 1999.", options: ["in", "on", "at"], correctIndex: 0, buffType: 'defense'),
    QuestionModel(question: "See you ____ Monday.", options: ["in", "on", "at"], correctIndex: 1, buffType: 'heal'),
    QuestionModel(question: "He is ____ school.", options: ["in", "on", "at"], correctIndex: 2, buffType: 'none'),
    QuestionModel(question: "The cat is ____ the box.", options: ["in", "on", "at"], correctIndex: 0, buffType: 'damage'),
  ],

  // LEVEL 15: Mega Boss (Ujian Menengah - Campuran Level 11-14)
  15: [
    QuestionModel(question: "Yesterday, I ____ a bird.", options: ["see", "saw", "seen"], correctIndex: 1, buffType: 'damage'),
    QuestionModel(question: "She ____ be a doctor one day.", options: ["will", "did", "is"], correctIndex: 0, buffType: 'heal'),
    QuestionModel(question: "You ____ smoke here. It's forbidden.", options: ["cannot", "must not", "may not"], correctIndex: 1, buffType: 'defense'), // 'must not' lebih tepat untuk larangan keras
    QuestionModel(question: "The party is ____ 7 PM.", options: ["in", "on", "at"], correctIndex: 2, buffType: 'damage'),
    QuestionModel(question: "____ you speak English?", options: ["Can", "Will", "Must"], correctIndex: 0, buffType: 'damage'),
  ],

  // --- SECTION 4: LANJUT (Advanced) ---

  // LEVEL 16: Comparatives (Lebih ... dari)
  16: [
    QuestionModel(question: "This box is ____ than that one.", options: ["big", "bigger", "biggest"], correctIndex: 1, buffType: 'damage'),
    QuestionModel(question: "She is ____ than me.", options: ["smart", "smarter", "smartest"], correctIndex: 1, buffType: 'defense'),
    QuestionModel(question: "Your car is ____ than mine.", options: ["expensive", "more expensive", "most expensive"], correctIndex: 1, buffType: 'none'),
    QuestionModel(question: "He runs ____ than a horse.", options: ["fast", "faster", "fastest"], correctIndex: 1, buffType: 'heal'),
    QuestionModel(question: "Today is ____ than yesterday.", options: ["good", "better", "best"], correctIndex: 1, buffType: 'damage'),
  ],

  // LEVEL 17: Superlatives (Paling ...)
  17: [
    QuestionModel(question: "He is the ____ boy in class.", options: ["tall", "taller", "tallest"], correctIndex: 2, buffType: 'damage'),
    QuestionModel(question: "This is the ____ movie ever.", options: ["bad", "worse", "worst"], correctIndex: 2, buffType: 'defense'),
    QuestionModel(question: "She is the ____ student.", options: ["diligent", "more diligent", "most diligent"], correctIndex: 2, buffType: 'heal'),
    QuestionModel(question: "It is the ____ building here.", options: ["old", "older", "oldest"], correctIndex: 2, buffType: 'none'),
    QuestionModel(question: "What is the ____ animal?", options: ["fast", "faster", "fastest"], correctIndex: 2, buffType: 'damage'),
  ],

  // LEVEL 18: Present Perfect (Sudah/Belum - Have/Has + V3)
  18: [
    QuestionModel(question: "I have ____ my homework.", options: ["finish", "finished", "finishing"], correctIndex: 1, buffType: 'damage'),
    QuestionModel(question: "She has ____ to Paris.", options: ["go", "went", "gone"], correctIndex: 2, buffType: 'heal'),
    QuestionModel(question: "We have ____ this movie.", options: ["see", "saw", "seen"], correctIndex: 2, buffType: 'defense'),
    QuestionModel(question: "____ you eaten yet?", options: ["Have", "Has", "Did"], correctIndex: 0, buffType: 'none'),
    QuestionModel(question: "He has not ____ yet.", options: ["arrive", "arrived", "arrives"], correctIndex: 1, buffType: 'damage'),
  ],

  // LEVEL 19: Passive Voice (Di... - To Be + V3)
  19: [
    QuestionModel(question: "The cake was ____ by him.", options: ["eat", "ate", "eaten"], correctIndex: 2, buffType: 'damage'),
    QuestionModel(question: "English is ____ all over the world.", options: ["speak", "spoke", "spoken"], correctIndex: 2, buffType: 'defense'),
    QuestionModel(question: "The letter was ____ yesterday.", options: ["write", "wrote", "written"], correctIndex: 2, buffType: 'heal'),
    QuestionModel(question: "My car was ____ last night.", options: ["steal", "stole", "stolen"], correctIndex: 2, buffType: 'none'),
    QuestionModel(question: "The house is ____ everyday.", options: ["clean", "cleaned", "cleaning"], correctIndex: 1, buffType: 'damage'),
  ],

  // LEVEL 20: FINAL EXAM (Ujian Terakhir - Campuran Sulit)
  20: [
    QuestionModel(question: "This problem is ____ than yours.", options: ["hard", "harder", "hardest"], correctIndex: 1, buffType: 'damage'),
    QuestionModel(question: "I have ____ him for 10 years.", options: ["know", "knew", "known"], correctIndex: 2, buffType: 'defense'),
    QuestionModel(question: "The window was ____ by the ball.", options: ["break", "broke", "broken"], correctIndex: 2, buffType: 'damage'),
    QuestionModel(question: "She is the ____ singer in the group.", options: ["good", "better", "best"], correctIndex: 2, buffType: 'heal'),
    QuestionModel(question: "____ you ever been to Bali?", options: ["Have", "Has", "Did"], correctIndex: 0, buffType: 'damage'),
  ],
};

// --- DATA SOAL UNTUK BATTLE (PVP) ---
// (Mengambil soal acak dari level yang sudah ada untuk mode bertarung)
// --- DATA SOAL UNTUK BATTLE / PVP (Campuran Level 1-20) ---
final List<QuestionModel> grammarQuestionBank = [
  // Ambil sampel dari berbagai level agar variatif
  ...levelQuestions[1]!,  // Dasar
  ...levelQuestions[3]!,  // Articles
  ...levelQuestions[6]!,  // Continuous
  ...levelQuestions[11]!, // Past Tense
  ...levelQuestions[12]!, // Future
  ...levelQuestions[16]!, // Comparative
  ...levelQuestions[18]!, // Perfect
  ...levelQuestions[20]!, // Final Exam
];