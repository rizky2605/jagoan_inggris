import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../story/story_screen.dart';
import '../avatar/avatar_screen.dart';
import '../match/match_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Indeks tab yang aktif
  int _selectedIndex = 1; 

  // Mengambil UID user saat ini
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  // HAPUS variabel List<Widget> _pages dari sini. 
  // Kita tidak bisa membuatnya di sini karena butuh data 'user'.

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // StreamBuilder mendengarkan perubahan data user secara real-time
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          // 1. Cek Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Cek Error/Data Kosong
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Gagal memuat profil."));
          }

          // 3. Ambil Data User
          UserModel user = UserModel.fromMap(
            snapshot.data!.data() as Map<String, dynamic>, 
            uid
          );

          // PERBAIKAN DI SINI:
          // Kita mendefinisikan daftar halaman DI DALAM builder,
          // sehingga kita bisa mengirim variabel 'user' ke StoryScreen.
          List<Widget> pages = [
            const AvatarScreen(),    // Halaman 0
            StoryScreen(user: user), // Halaman 1 (Sekarang error hilang karena user dikirim)
            const MatchScreen(),     // Halaman 2
          ];

          return Stack(
            children: [
              // BACKGROUND
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F0025), Color(0xFF200040)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // KONTEN UTAMA
              SafeArea(
                child: Column(
                  children: [
                    // Header Profil
                    _buildProfileHeader(user),

                    // Menampilkan Halaman sesuai tab yang dipilih
                    Expanded(
                      child: pages[_selectedIndex], 
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),

      // NAVIGASI BAWAH
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F0025).withValues(alpha: 0.9),
          border: const Border(top: BorderSide(color: Colors.white10)),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.cyanAccent,
          unselectedItemColor: Colors.white38,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.checkroom), label: 'AVATAR'),
            BottomNavigationBarItem(icon: Icon(Icons.auto_stories), label: 'STORY'),
            BottomNavigationBarItem(icon: Icon(Icons.flash_on), label: 'MATCH'),
          ],
        ),
      ),
    );
  }

  // WIDGET HEADER PROFIL (Tetap Sama)
  Widget _buildProfileHeader(UserModel user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: Text("Lv. ${user.level}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: Colors.purple,
            radius: 16,
            child: Text(user.username.isNotEmpty ? user.username[0].toUpperCase() : "U"),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (user.currentXp / user.maxXp).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[800],
                    color: const Color(0xFFBD00FF),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          Row(
            children: [
              const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text("${user.gold}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}