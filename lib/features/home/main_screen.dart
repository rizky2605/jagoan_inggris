import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui'; // Untuk ImageFilter (Blur)

import '../../models/user_model.dart';
import '../story/story_screen.dart';
import '../avatar/avatar_screen.dart';
import '../match/match_screen.dart';
import '../profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1; // Default ke Story
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    // Kunci Landscape & Immersive Mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _forceCreateProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        UserModel newUser = UserModel(uid: uid, username: user.email!.split('@')[0], email: user.email!);
        await FirebaseFirestore.instance.collection('users').doc(uid).set(newUser.toMap());
      }
    } catch (e) { debugPrint("Error: $e"); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C), 
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || !snapshot.data!.exists) return _buildEmptyState();
          
          UserModel user;
          try {
             user = UserModel.fromMap(snapshot.data!.data() as Map<String, dynamic>, uid);
          } catch(e) { return const Center(child: Text("Data Error")); }

          List<Widget> pages = [
            const AvatarScreen(),    
            StoryScreen(user: user), 
            const MatchScreen(),     
          ];

          return Stack(
            children: [
              // 1. BACKGROUND GLOBAL
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1E1E2C), Color(0xF20F0025)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // 2. LAYOUT UTAMA (ROW)
              Row(
                children: [
                  // --- SIDEBAR KIRI (SELALU MUNCUL) ---
                  _buildRefinedSidebar(user),

                  // --- KONTEN KANAN ---
                  Expanded(
                    child: Column(
                      children: [
                        // [PERBAIKAN UTAMA DISINI]
                        // Header Atas HANYA muncul jika BUKAN index 2 (MatchScreen)
                        // Jadi saat index == 2 (Match), header ini hilang, sisa Navbar kiri saja.
                        if (_selectedIndex != 2)
                          _buildHeaderNoName(user), 
                        
                        // HALAMAN UTAMA
                        Expanded(child: pages[_selectedIndex]),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // WIDGETS UI
  // ===========================================================================

  // 1. SIDEBAR KIRI
  Widget _buildRefinedSidebar(UserModel user) {
    return Container(
      width: 72, 
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2), 
        border: const Border(right: BorderSide(color: Colors.white10, width: 1)),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              const SizedBox(height: 15),
              
              // A. FOTO PROFIL
              _buildSideProfileIcon(user),
              
              const Spacer(), 
              
              // B. MENU NAVIGASI
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildNavItemWithLine(0, Icons.checkroom, "AVATAR"),
                  _buildNavItemWithLine(1, Icons.auto_stories, "STORY"),
                  _buildNavItemWithLine(2, Icons.flash_on, "MATCH"),
                ],
              ),
              
              const Spacer(), 
              
              // C. PENGATURAN
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.settings, color: Colors.white24, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // 2. HEADER ATAS (Info Level, XP, Gold)
  Widget _buildHeaderNoName(UserModel user) {
    double xpProgress = user.maxXp > 0 ? (user.currentXp / user.maxXp).clamp(0.0, 1.0) : 0.0;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: Colors.transparent, 
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          
          // BADGE LEVEL
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber, 
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]
            ),
            child: Text("Lv.${user.level}", style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
          ),

          const SizedBox(width: 15),

          // XP BAR
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: xpProgress,
                    backgroundColor: Colors.white10, 
                    color: const Color(0xFFBD00FF), 
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${user.currentXp}/${user.maxXp} XP", 
                  style: const TextStyle(color: Colors.white38, fontSize: 8)
                ),
              ],
            ),
          ),

          const SizedBox(width: 30),

          // GOLD
          Row(
            children: [
              const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text(
                "${user.gold}", 
                style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14)
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- KOMPONEN ITEM ---

  Widget _buildSideProfileIcon(UserModel user) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
      child: Container(
        height: 45, width: 45,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 1.5),
        ),
        child: CircleAvatar(
          backgroundColor: const Color(0xFF2A0040),
          backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
          child: user.photoUrl.isEmpty ? Text(user.username[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 14)) : null,
        ),
      ),
    );
  }

  Widget _buildNavItemWithLine(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        height: 55, 
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.centerLeft, 
          children: [
            // A. GARIS INDIKATOR
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              left: 0,
              top: isSelected ? 12 : 27, 
              bottom: isSelected ? 12 : 27,
              child: Container(
                width: 3, 
                decoration: BoxDecoration(
                  color: isSelected ? Colors.cyanAccent : Colors.transparent,
                  borderRadius: const BorderRadius.only(topRight: Radius.circular(2), bottomRight: Radius.circular(2)),
                  boxShadow: isSelected ? [const BoxShadow(color: Colors.cyanAccent, blurRadius: 4)] : []
                ),
              ),
            ),

            // B. IKON DAN LABEL
            Center(
              child: AnimatedScale(
                scale: isSelected ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon, 
                      size: 24, 
                      color: isSelected ? Colors.cyanAccent : Colors.white24
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label, 
                      style: TextStyle(
                        fontSize: 8, 
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, 
                        color: isSelected ? Colors.cyanAccent : Colors.white24,
                        letterSpacing: 0.5
                      )
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: ElevatedButton(onPressed: _forceCreateProfile, child: const Text("Start Game")));
  }
}