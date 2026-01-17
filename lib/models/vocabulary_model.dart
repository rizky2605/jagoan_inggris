import 'package:flutter/material.dart';

class VocabularyModel {
  final String word;          // Kata Inggris (misal: Gloomy)
  final String pronunciation; // Cara baca (misal: /gluːmi/)
  final String meaning;       // Arti (misal: Suram / Mendung)
  final String memoryAid;     // Jembatan Keledai (misal: "Gloom" mirip "Belum". Ruangan BELUM ada lampu jadi GLOOM (Gelap/Suram))
  final String exampleSentence;
  final IconData icon;

  VocabularyModel({
    required this.word,
    required this.pronunciation,
    required this.meaning,
    required this.memoryAid,
    required this.exampleSentence,
    required this.icon,
  });
}

// --- DATA SET KOSA KATA (Daily Set) ---
final List<VocabularyModel> dailyVocabSet = [
  VocabularyModel(
    word: "Abundant",
    pronunciation: "/əˈbʌn.dənt/",
    meaning: "Melimpah / Banyak Sekali",
    memoryAid: "Bayangkan 'A Bun' (sebuah roti) dan 'Dance' (menari). Ada roti menari karena saking ABUNDANT (banyaknya) makanan di pesta!",
    exampleSentence: "We have abundant food for everyone.",
    icon: Icons.bakery_dining,
  ),
  VocabularyModel(
    word: "Gloomy",
    pronunciation: "/ˈɡluː.mi/",
    meaning: "Suram / Mendung / Sedih",
    memoryAid: "Ingat kata 'LEM' (Glue). Kalau kaki kena LEM, pasti perasaan jadi GLOOMY (sedih/suram) karena nggak bisa jalan.",
    exampleSentence: "The sky looks gloomy today.",
    icon: Icons.cloud_off,
  ),
  VocabularyModel(
    word: "Candid",
    pronunciation: "/ˈkæn.dɪd/",
    meaning: "Jujur / Apa adanya",
    memoryAid: "Mirip kata 'KANDIDAT'. Kandidat pemimpin yang baik harus CANDID (jujur) kepada rakyat.",
    exampleSentence: "Please be candid with me.",
    icon: Icons.record_voice_over,
  ),
  VocabularyModel(
    word: "Keen",
    pronunciation: "/kiːn/",
    meaning: "Sangat tertarik / Tajam",
    memoryAid: "Mirip 'IKIN' (nama orang). Si Ikin sangat KEEN (tertarik) belajar coding.",
    exampleSentence: "She is keen on learning music.",
    icon: Icons.emoji_objects,
  ),
  VocabularyModel(
    word: "Huge",
    pronunciation: "/hjuːdʒ/",
    meaning: "Sangat Besar",
    memoryAid: "Bayangkan 'HIU'. Ikan Hiu itu badannya HUGE (besar sekali)!",
    exampleSentence: "That building is huge!",
    icon: Icons.apartment,
  ),
];