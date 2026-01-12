class LevelModel {
  final int id;
  final String title;
  final String subtitle;
  final String type; // 'lesson' (Materi) atau 'test' (Ujian)

  LevelModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
  });
}

// --- DATA 20 LEVEL (KURIKULUM LENGKAP) ---
final List<LevelModel> gameLevels = [
  // SECTION 1: DASAR (Basic)
  LevelModel(id: 1, title: "Level 1", subtitle: "Subject & To Be", type: 'lesson'),
  LevelModel(id: 2, title: "Level 2", subtitle: "Simple Present", type: 'lesson'),
  LevelModel(id: 3, title: "Level 3", subtitle: "Articles (A/An/The)", type: 'lesson'),
  LevelModel(id: 4, title: "Level 4", subtitle: "Plural Nouns", type: 'lesson'),
  LevelModel(id: 5, title: "Mini Boss", subtitle: "Ujian Dasar I", type: 'test'),

  // SECTION 2: PEMULA (Beginner)
  LevelModel(id: 6, title: "Level 6", subtitle: "Present Continuous", type: 'lesson'),
  LevelModel(id: 7, title: "Level 7", subtitle: "Pronouns", type: 'lesson'),
  LevelModel(id: 8, title: "Level 8", subtitle: "Adjectives", type: 'lesson'),
  LevelModel(id: 9, title: "Level 9", subtitle: "Possessive", type: 'lesson'),
  LevelModel(id: 10, title: "Big Boss", subtitle: "Ujian Dasar II", type: 'test'),

  // SECTION 3: MENENGAH (Intermediate)
  LevelModel(id: 11, title: "Level 11", subtitle: "Past Tense", type: 'lesson'),
  LevelModel(id: 12, title: "Level 12", subtitle: "Future Tense (Will)", type: 'lesson'),
  LevelModel(id: 13, title: "Level 13", subtitle: "Modals (Can/Must)", type: 'lesson'),
  LevelModel(id: 14, title: "Level 14", subtitle: "Prepositions (In/On/At)", type: 'lesson'),
  LevelModel(id: 15, title: "Mega Boss", subtitle: "Ujian Menengah", type: 'test'),

  // SECTION 4: LANJUT (Advanced)
  LevelModel(id: 16, title: "Level 16", subtitle: "Comparatives", type: 'lesson'),
  LevelModel(id: 17, title: "Level 17", subtitle: "Superlatives", type: 'lesson'),
  LevelModel(id: 18, title: "Level 18", subtitle: "Present Perfect", type: 'lesson'),
  LevelModel(id: 19, title: "Level 19", subtitle: "Passive Voice", type: 'lesson'),
  LevelModel(id: 20, title: "Final Exam", subtitle: "Ujian Terakhir", type: 'test'),
];