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
  int _selectedIndex = 1;
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // --- FUNGSI PENYELAMAT (SELF-HEALING) ---
  // Jika profil macet/tidak ada, fungsi ini akan membuatnya manual
  Future<void> _forceCreateProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        UserModel newUser = UserModel(
          uid: uid,
          username: user.email!.split('@')[0], // Pakai nama dari email
          email: user.email!,
          lastLogin: DateTime.now(),
        );
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(newUser.toMap());
            
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil berhasil diperbaiki!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          // 1. LOADING STATE
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState("Menghubungkan ke server...");
          }

          // 2. ERROR STATE
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }

          // 3. DATA KOSONG (PENYEBAB FREEZE) -> TAMPILKAN TOMBOL PERBAIKI
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 60, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text(
                    "Profil belum siap.",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Data database terlambat masuk.",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _forceCreateProfile, // Panggil fungsi penyelamat
                    icon: const Icon(Icons.build),
                    label: const Text("BUAT PROFIL SEKARANG"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                    ),
                  )
                ],
              ),
            );
          }

          // 4. DATA AMAN -> TAMPILKAN UI UTAMA
          UserModel user;
          try {
            user = UserModel.fromMap(
              snapshot.data!.data() as Map<String, dynamic>, 
              uid
            );
          } catch (e) {
            return Center(child: Text("Data Corrupt: $e", style: const TextStyle(color: Colors.red)));
          }

          // List Halaman
          List<Widget> pages = [
            const AvatarScreen(),    
            StoryScreen(user: user), 
            const MatchScreen(),     
          ];

          return Stack(
            children: [
              // Background
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F0025), Color(0xFF200040)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Konten
              SafeArea(
                child: Column(
                  children: [
                    _buildProfileHeader(user),
                    Expanded(child: pages[_selectedIndex]),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      // Navigasi Bawah
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

  // Widget Loading Cantik
  Widget _buildLoadingState(String message) {
    return Container(
      color: const Color(0xFF0F0025),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.cyanAccent),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  // Widget Header (Copy dari sebelumnya)
  Widget _buildProfileHeader(UserModel user) {
    double progress = user.maxXp > 0 ? (user.currentXp / user.maxXp).clamp(0.0, 1.0) : 0.0;
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
                    value: progress,
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