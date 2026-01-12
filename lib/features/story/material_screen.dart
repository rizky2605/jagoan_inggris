import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../models/level_model.dart';
import '../../models/user_model.dart';
import '../quiz/quiz_screen.dart';

class MaterialScreen extends StatelessWidget {
  final LevelModel level;
  final UserModel user;

  MaterialScreen({super.key, required this.level, required this.user});

  // --- DATA MATERI (SAMA SEPERTI SEBELUMNYA) ---
  final Map<int, String> materialData = {
    // --- SECTION 1: BASIC ---
    1: """
Halo Jagoan! Sebelum bertualang, kenali dulu siapa pelakunya.

👤 SUBJECT (Pelaku)
👉 I  : Saya
👉 You : Kamu
👉 We : Kita / Kami
👉 They : Mereka
👉 He : Dia (Laki-laki)
👉 She : Dia (Perempuan)
👉 It : Itu (Benda/Hewan)

🔗 TO BE (Penghubung)
Ingat pasangan abadi ini ya!
✨ I am (Saya adalah...)
✨ You/We/They are (Kamu adalah...)
✨ He/She/It is (Dia adalah...)

Contoh Mantra:
I am strong! (Saya kuat!)
""",
    2: """
⚔️ SIMPLE PRESENT TENSE
Jurus untuk fakta & kebiasaan sehari-hari.

📜 Rumus Dasar:
Subject + Verb 1

⚠️ Aturan Emas:
Jika pelakunya Sendirian (He, She, It), Kata Kerjanya manja, minta tambah 's' atau 'es'.

👇 Lihat Bedanya:
👥 Rame-rame (I, You, We, They):
Makan ➡️ Eat
"They eat pizza."

👤 Sendirian (He, She, It):
Makan ➡️ Eats
"He eats pizza."

Ingat: Orang ketiga suka es (s/es)! 🍦
""",


    3: """
🍎 ARTICLES (A, An, The)
Kata sandang untuk menunjuk benda.

1️⃣ A (Sebuah/Seorang)
Untuk benda berawalan bunyi Konsonan (B, C, D, P, T...)
📦 A cat (Seekor kucing)
🚗 A car (Sebuah mobil)

2️⃣ AN (Sebuah/Seorang)
Untuk benda berawalan bunyi Vokal (A, I, U, E, O)
🍎 An apple (Sebuah apel)
🐜 An ant (Seekor semut)
⏳ An hour (Huruf H bisu, dibaca 'our', jadi pakai An)

3️⃣ THE (Itu / Spesifik)
Untuk benda yang sudah jelas atau cuma satu di dunia.
☀️ The sun (Matahari)
🚪 The door (Pintu itu)
""",

    4: """
📦 PLURAL NOUNS (Benda Banyak)
Kalau bendanya lebih dari satu, kita harus ubah bentuknya!

🔹 Tambah 'S' (Paling Umum)
🐈 Cat ➡️ Cats
🚗 Car ➡️ Cars

🔹 Tambah 'ES' (Akhiran -s, -x, -ch, -sh)
📦 Box ➡️ Boxes
⌚ Watch ➡️ Watches

🔹 Benda Ajaib (Berubah Bentuk)
Hafalkan ini, jangan sampai salah mantra!
🦶 Foot ➡️ Feet (Kaki)
🐁 Mouse ➡️ Mice (Tikus)
👶 Child ➡️ Children (Anak-anak)
👥 Person ➡️ People (Orang-orang)
""",

    5: """
⚔️ MINI BOSS: UJIAN DASAR
Waspada! Boss pertama menghadang!

Dia akan mengujimu tentang semua yang sudah kita pelajari:
1. Pasangan To Be (Am, Is, Are)
2. Penambahan 's' pada kata kerja
3. Penggunaan A vs An
4. Benda jamak (Plural)

Fokus, Jagoan! Jangan sampai HP-mu habis diserang monster ini!
""",

    // --- SECTION 2: BEGINNER ---
    6: """
⏱️ PRESENT CONTINUOUS
Sedang terjadi SEKARANG JUGA!

📜 Rumusnya Wajib:
To Be + Verb-ING

🎬 Contoh Aksi:
🏃 I am running (Saya sedang lari)
📺 She is watching (Dia sedang menonton)
💤 They are sleeping (Mereka sedang tidur)

🚫 Jangan Lupa:
Jangan bilang "I running". Harus ada "Am"!
"I AM running."
""",

    7: """
👉 PRONOUNS (Kata Ganti)
Beda posisi, beda wujudnya lho!

1️⃣ Subject (Di Depan)
I, You, We, They, He, She.
"SHE loves him."

2️⃣ Object (Di Belakang)
Me, You, Us, Them, Him, Her.
"I love HER." (Bukan I love She!)

3️⃣ Kepemilikan (Milikku)
My, Your, Our, Their, His, Her.
"This is MY sword." (Ini pedangku)
""",

    8: """
🎨 ADJECTIVES (Kata Sifat)
Kata yang memberi warna pada kalimatmu!

📍 Posisi Strategis:
1. Sebelum Benda:
🏠 A big house (Rumah besar)
❌ Bukan: House big

2. Setelah To Be:
👸 She is beautiful (Dia cantik)
☕ The coffee is hot (Kopinya panas)

Lawan Kata Populer:
🔥 Hot vs ❄️ Cold
🚀 Fast vs 🐢 Slow
😊 Happy vs 😢 Sad
""",

    9: """
🔒 POSSESSIVE ('S)
Cara cepat bilang "Milik Siapa".

Cukup tempelkan ('s) di belakang nama pemilik.

🏎️ Mobil John ➡️ John's car
🎒 Tas Ibu ➡️ Mom's bag
🐈 Ekor Kucing ➡️ The cat's tail

⚠️ Hati-hati:
It's = It is (Itu adalah)
Its = Miliknya (Tanpa koma atas)
""",

    10: """
👹 BIG BOSS: UJIAN KEDUA
Monster besar mendekat! Dia lebih kuat dari sebelumnya.

Persiapkan jurusmu:
🛡️ Kata ganti (I vs Me vs My)
🛡️ Sifat benda (Big Car, bukan Car Big)
🛡️ Tanda kepemilikan ('s)
🛡️ Kejadian sekarang (V-ing)

Kalahkan dia untuk naik ke tingkat Intermediate!
""",

    // --- SECTION 3: INTERMEDIATE ---
    11: """
📜 SIMPLE PAST TENSE
Cerita masa lalu. Sudah lewat, jangan disesali!

📜 Rumus:
Pakai VERB 2 (Kata Kerja Bentuk 2)

✌️ Dua Jenis Verb 2:
1. Regular (Teratur) ➡️ Tambah -ed
🎮 Play ➡️ Played
🍳 Cook ➡️ Cooked

2. Irregular (Berubah Total) ➡️ Hafalkan!
🏃 Go ➡️ Went
🍕 Eat ➡️ Ate
👀 See ➡️ Saw

📅 Tanda Waktu:
Yesterday (Kemarin), Last night (Tadi malam).
""",

    12: """
🔮 FUTURE TENSE (Will)
Masa depan cerah menantimu!

📜 Rumus Anti Gagal:
Will + Verb 1 (Polos)

✅ Benar:
"I will go to Bali."
"She will help you."

❌ Salah:
"I will going" (Salah!)
"She will helps" (Salah!)

🚫 Bentuk Negatif:
Will not = Won't
"I won't give up!" (Saya tidak akan menyerah!)
""",

    13: """
🛠️ MODALS (Kata Bantu Sakti)
Menambah makna "Bisa", "Harus", atau "Sebaiknya".

💪 Can (Bisa)
"I can swim." (Saya bisa berenang)

⚠️ Must (Wajib/Harus)
"You must study." (Kamu wajib belajar)

💡 Should (Sebaiknya/Saran)
"You should rest." (Kamu sebaiknya istirahat)

💎 Aturan Berlian:
Setelah Modal, kata kerja KEMBALI ASAL (Verb 1).
Tidak boleh pakai 's', 'ing', atau 'to'.
""",

    14: """
📍 PREPOSITIONS (In, On, At)
Jangan tersesat! Gunakan kompas ini.

🎯 AT (Paling Spesifik/Sempit)
⏰ Jam: At 7 PM
🏫 Tempat: At school, At home

🛣️ ON (Sedang/Jalan/Permukaan)
📅 Hari: On Monday, On Sunday
🛣️ Jalan: On Sudirman Street
🪑 Benda: On the table

🌍 IN (Paling Luas/Dalam)
📆 Tahun/Bulan: In 2025, In July
🏙️ Kota/Negara: In Jakarta, In Indonesia
📦 Ruang: In the box
""",

    15: """
🐉 MEGA BOSS: UJIAN MENENGAH
Naga penjaga gerbang Intermediate menghadang!

Kelemahannya adalah WAKTU & TEMPAT.
⚔️ Serang dengan Past Tense (V2)
⚔️ Tangkis dengan Future Tense (Will)
⚔️ Hindari jebakan In/On/At

Buktikan kalau kamu layak menjadi Pro!
""",

    // --- SECTION 4: ADVANCED ---
    16: """
⚖️ COMPARATIVES (Perbandingan)
Siapa yang lebih hebat?

1️⃣ Kata Pendek (1 suku kata) ➡️ Tambah -ER
🐘 Big ➡️ Bigger (Lebih besar)
🚀 Fast ➡️ Faster (Lebih cepat)
"I am faster than you."

2️⃣ Kata Panjang (2+ suku kata) ➡️ Pakai MORE
🌹 Beautiful ➡️ More beautiful
💰 Expensive ➡️ More expensive
"This car is more expensive."

⚠️ Pengecualian Aneh:
Good ➡️ Better (Lebih baik)
Bad ➡️ Worse (Lebih buruk)
""",

    17: """
🏆 SUPERLATIVES (Paling)
Menjadi juara satu!

1️⃣ Kata Pendek ➡️ The ... -EST
🏙️ Tall ➡️ The Tallest (Paling tinggi)
🤓 Smart ➡️ The Smartest (Paling pintar)

2️⃣ Kata Panjang ➡️ The MOST ...
🌟 Famous ➡️ The Most Famous (Paling terkenal)

⚠️ Pengecualian Aneh:
Good ➡️ The Best (Terbaik)
Bad ➡️ The Worst (Terburuk)
""",

    18: """
✅ PRESENT PERFECT
Sudah atau Belum? Hasilnya masih terasa.

📜 Rumus:
Have / Has + Verb 3

🔑 Kunci Pasangan:
I/You/We/They ➡️ Have
He/She/It ➡️ Has

🍕 Contoh:
"I have eaten." (Saya sudah makan - kenyang sekarang)
"She has gone." (Dia sudah pergi - tidak ada di sini)
"Have you finished?" (Sudah selesai belum?)
""",

    19: """
🛡️ PASSIVE VOICE (Kalimat Pasif)
Fokus pada korbannya, bukan pelakunya.
Biasanya ada kata "Di-..."

📜 Rumus:
To Be + Verb 3

🚗 Contoh Kasus:
Aktif: "Someone stole my car."
Pasif: "My car WAS STOLEN." (Mobilku dicuri!)

🍳 Contoh Lain:
"Fried Rice is cooked by Mom."
(Nasi goreng dimasak oleh Ibu)

Ingat: Wajib pakai Verb 3!
""",

     20: """
👑 FINAL EXAM: MASTER LEVEL
Raja Terakhir telah bangkit! 🤴

Ini adalah ujian penentuan gelar Master Bahasa Inggrismu.
Dia menguasai semua elemen:
🔥 Perbandingan (Better/Best)
🌊 Masa lalu & Sekarang (Perfect Tense)
🌪️ Kalimat Pasif (Passive Voice)
⚡ Vocabulary Level Tinggi

Kerahkan semua ilmumu, Jagoan! Dunia (dan sertifikatmu) menantimu!
""",
  };

  @override
  Widget build(BuildContext context) {
    String content = materialData[level.id] ?? "Materi rahasia sedang disusun oleh Sensei.";

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      // Gunakan SafeArea agar tidak tertutup notch/status bar
      body: SafeArea(
        // PERUBAHAN UTAMA: Menggunakan ROW untuk layout Kiri-Kanan
        child: Row(
          children: [
            // ================= BAGIAN KIRI (PANEL GURU) =================
            Expanded(
              flex: 4, // Mengambil 40% lebar layar
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF2D2D44),
                      const Color(0xFF1E1E2C),
                    ],
                  ),
                  // Border kanan sebagai pemisah
                  border: Border(right: BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.1))),
                ),
                child: Column(
                  children: [
                    // Tombol Back di pojok kiri atas panel kiri
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    
                    // Avatar Guru 3D (Mengisi ruang vertikal yang tersisa)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: ModelViewer(
                          src: 'assets/models/teacher.glb', // Pastikan aset ini ada
                          backgroundColor: Colors.transparent,
                          autoRotate: true,
                          cameraControls: false,
                          disableZoom: true,
                        ),
                      ),
                    ),

                    // Judul Level & Materi (Chat Bubble di bawah guru)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(30)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "LEVEL ${level.id}",
                            style: GoogleFonts.poppins(
                              color: Colors.cyanAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            level.title,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Sensei berkata: \"Perhatikan materinya di sebelah kanan! 👉\"",
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ================= BAGIAN KANAN (KONTEN MATERI) =================
            Expanded(
              flex: 6, // Mengambil 60% lebar layar
              child: Column(
                children: [
                  // Area Scroll Materi
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(30, 30, 30, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.menu_book_rounded, color: Colors.cyanAccent, size: 24),
                              const SizedBox(width: 10),
                              Text(
                                "Catatan Sensei:",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // Container Teks Materi
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(25),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D2D44),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: Colors.white10),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0,5))
                              ],
                            ),
                            child: Text(
                              content,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 15,
                                height: 1.8, // Spasi antar baris lega
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // Tombol Siap Ujian (Fixed di bawah kanan)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2C),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0,-5))
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuizScreen(level: level, user: user),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "SIAP UJIAN!",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.flash_on_rounded, color: Colors.redAccent),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}