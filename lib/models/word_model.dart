class WordModel {
  final String word;        // Kata bahasa Inggris (misal: "Apple")
  final String meaning;     // Arti (misal: "Apel")
  final String pronunciation; // Cara baca (misal: "/ˈæp.əl/")
  final String exampleSentence; // Contoh kalimat
  final String category;    // Kategori (Noun, Verb, Adjective)

  WordModel({
    required this.word,
    required this.meaning,
    required this.pronunciation,
    required this.exampleSentence,
    required this.category,
  });
}

// --- DATA DUMMY KOSA KATA HARIAN ---
// Nanti ini bisa kita ambil acak dari database setiap hari
final List<WordModel> dailyVocabList = [
  WordModel(
    word: "Resilient",
    meaning: "Tangguh / Ulet",
    pronunciation: "/rɪˈzɪl.jənt/",
    exampleSentence: "She is resilient in the face of difficulties.",
    category: "Adjective",
  ),
  WordModel(
    word: "Determination",
    meaning: "Tekad",
    pronunciation: "/dɪˌtɜː.mɪˈneɪ.ʃən/",
    exampleSentence: "He fought with great determination.",
    category: "Noun",
  ),
  WordModel(
    word: "Achieve",
    meaning: "Mencapai",
    pronunciation: "/əˈtʃiːv/",
    exampleSentence: "Work hard to achieve your goals.",
    category: "Verb",
  ),
  WordModel(
    word: "Wisdom",
    meaning: "Kebijaksanaan",
    pronunciation: "/ˈwɪz.dəm/",
    exampleSentence: "Experience brings wisdom.",
    category: "Noun",
  ),
  WordModel(
    word: "Warrior",
    meaning: "Pejuang",
    pronunciation: "/ˈwɒr.i.ər/",
    exampleSentence: "A true warrior never gives up.",
    category: "Noun",
  ),
];