# 🎮 Jagoan Inggris

**Jagoan Inggris** adalah aplikasi gamifikasi pembelajaran bahasa Inggris berbasis Flutter. Aplikasi ini menggabungkan konsep RPG Battle dengan kuis tata bahasa (grammar) untuk membuat pengalaman belajar menjadi lebih seru dan kompetitif.

## 🚀 Fitur Utama

- **PVP Battle Arena:** Bertarung melawan pemain lain atau monster dalam duel cerdas.
- **Dynamic Quiz System:** Soal tata bahasa yang menantang dengan sistem poin berbasis kecepatan menjawab.
- **Buff & Debuff System:** - ⚔️ **Damage:** Memberikan serangan kritikal ke lawan.
  - 🛡️ **Defense:** Melindungi nyawa dari serangan lawan.
  - 💊 **Heal:** Menambah HP saat berhasil menjawab soal tertentu.
- **3D Avatar Integration:** Menggunakan `model_viewer_plus` untuk menampilkan karakter 3D yang interaktif.
- **Real-time Matchmaking:** Mencari lawan secara otomatis menggunakan Firebase Cloud Firestore.

## 📚 Dokumentasi & Panduan

Untuk memahami cara kerja aplikasi dan melihat tampilan antarmuka secara mendetail, silakan akses tautan di bawah ini:

* **📷 Galeri Foto Dokumentasi dan Buku Panduan Pengguna (PDF):** [Klik di Sini](https://drive.google.com/drive/folders/1HUJcejF0LHDGyI-CdFaZFrGLxX9LyOFq?usp=sharing)

## 🛠️ Teknologi yang Digunakan

- **Framework:** [Flutter](https://flutter.dev/) (Version 3.27+)
- **Database & Auth:** [Firebase](https://firebase.google.com/) (Firestore & Auth)
- **3D Rendering:** [Model Viewer Plus](https://pub.dev/packages/model_viewer_plus)
- **State Management:** StatefulWidget (Clean Logic)

## 💻 Cara Menjalankan Proyek

1.  **Clone Repository:**
    ```bash
    git clone [https://github.com/rizky2065/jagoan_Inggris.git](https://github.com/rizky2065/jagoan_Inggris.git)
    ```
2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Konfigurasi Firebase:**
    * Pastikan Anda sudah menjalankan `flutterfire configure` untuk menghubungkan proyek dengan akun Firebase Anda.
4.  **Jalankan Aplikasi:**
    ```bash
    flutter run
    ```

## 📂 Struktur Folder Utama

```text
lib/
├── core/           # Service (Auth, Firestore, Theme)
├── features/       # Fitur (Auth, Avatar, Matchmaking, Quiz, Story)
├── models/         # Data Models (User, Question, Level)
└── main.dart       # Entry Point aplikasi