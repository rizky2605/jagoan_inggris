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

// Data statis kurikulum (Nanti bisa dipindahkan ke Firebase jika mau dinamis)
final List<LevelModel> gameLevels = [
  LevelModel(id: 1, title: "Level 1", subtitle: "Subject 'To Be'", type: 'lesson'),
  LevelModel(id: 2, title: "Level 2", subtitle: "Simple Present", type: 'lesson'),
  LevelModel(id: 3, title: "Articles", subtitle: "(A/An)", type: 'lesson'),
  LevelModel(id: 4, title: "Final Test", subtitle: "Ujian Boss", type: 'test'),
  LevelModel(id: 5, title: "Level 3", subtitle: "Past Tense", type: 'lesson'),
];