import 'dart:ui'; // Untuk ImageFilter
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../core/utils/rank_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? get currentUser => FirebaseAuth.instance.currentUser;
  String get uid => currentUser?.uid ?? "";

  // --- EDIT BIO & NAME ---
  void _showEditProfileDialog(UserModel user) {
    final nameController = TextEditingController(text: user.username);
    final bioController = TextEditingController(text: user.bio.isNotEmpty ? user.bio : "Jagoan Inggris siap bertarung!"); 
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.cyanAccent, width: 1)),
        title: const Text("Edit Profil", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Username", 
                labelStyle: const TextStyle(color: Colors.cyanAccent),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: bioController, 
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Bio / Moto", 
                labelStyle: const TextStyle(color: Colors.cyanAccent),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              if (uid.isNotEmpty) {
                await FirebaseFirestore.instance.collection('users').doc(uid).update({
                  'username': nameController.text,
                  'bio': bioController.text, 
                });
              }
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  // --- GANTI AVATAR ---
  void _showAvatarSelector() {
    final List<String> avatars = [
      'https://api.dicebear.com/7.x/avataaars/png?seed=Felix',
      'https://api.dicebear.com/7.x/avataaars/png?seed=Aneka',
      'https://api.dicebear.com/7.x/bottts/png?seed=Robot1',
      'https://api.dicebear.com/7.x/bottts/png?seed=Robot2',
      'https://api.dicebear.com/7.x/adventurer/png?seed=Hero',
      'https://api.dicebear.com/7.x/adventurer/png?seed=Mage',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: const Border(top: BorderSide(color: Colors.cyanAccent, width: 2)),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            color: const Color(0xFF1E1E2C),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Pilih Avatar", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: avatars.map((url) {
                  return GestureDetector(
                    onTap: () async {
                      if (uid.isNotEmpty) {
                        await FirebaseFirestore.instance.collection('users').doc(uid).update({'photoUrl': url});
                      }
                      if (mounted) Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 2),
                        boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.2), blurRadius: 10)]
                      ),
                      child: CircleAvatar(
                        radius: 35,
                        backgroundImage: NetworkImage(url),
                        backgroundColor: Colors.black,
                      ),
                    ),
                  );
                }).toList(),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0025),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0025),
      extendBodyBehindAppBar: true, // Agar background menyatu ke atas
      appBar: AppBar(
        title: Text("PLAYER PROFILE", style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        // [FIX] Logout button removed
      ),
      body: Stack(
        children: [
          // 1. BACKGROUND GLOBAL
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F0025), Color(0xFF2A0045)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          
          // 2. KONTEN UTAMA
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
              if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text("Data User Error", style: TextStyle(color: Colors.white)));
              
              var data = snapshot.data!.data() as Map<String, dynamic>;
              UserModel user = UserModel.fromMap(data, uid);

              return SafeArea(
                child: isLandscape 
                  ? _buildLandscapeLayout(user) 
                  : _buildPortraitLayout(user),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- LAYOUT PORTRAIT (VERTICAL) ---
  Widget _buildPortraitLayout(UserModel user) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildIdentitySection(user),
          const SizedBox(height: 20),
          _buildBioSection(user),
          const SizedBox(height: 20),
          _buildStatsGrid(user),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- LAYOUT LANDSCAPE (SPLIT 2 KOLOM) ---
  Widget _buildLandscapeLayout(UserModel user) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // KOLOM KIRI: Identitas (40%)
        Expanded(
          flex: 4,
          child: Center(
            child: SingleChildScrollView(
              child: _buildIdentitySection(user),
            ),
          ),
        ),
        
        // PEMISAH
        Container(width: 1, height: double.infinity, color: Colors.white10),

        // KOLOM KANAN: Bio & Stats (60%)
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(top: 20, bottom: 20),
            child: Column(
              children: [
                _buildBioSection(user),
                const SizedBox(height: 20),
                _buildStatsGrid(user),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================= KOMPONEN UI =================

  // 1. SECTION IDENTITAS (Avatar, Nama, Rank)
  Widget _buildIdentitySection(UserModel user) {
    final rank = RankHelper.getRank(user.mmr);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Avatar dengan Efek Neon
        Stack(
          alignment: Alignment.center,
          children: [
            // Glow Effect
            Container(
              width: 130, height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.cyanAccent.withOpacity(0.4), blurRadius: 30, spreadRadius: 5),
                  BoxShadow(color: Colors.purpleAccent.withOpacity(0.2), blurRadius: 50, spreadRadius: 10),
                ],
              ),
            ),
            // Border Ring
            Container(
              width: 125, height: 125,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                gradient: const LinearGradient(
                  colors: [Colors.cyanAccent, Colors.purpleAccent],
                  begin: Alignment.topLeft, end: Alignment.bottomRight
                )
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: const Color(0xFF1E1E2C),
                  backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                  child: user.photoUrl.isEmpty ? Text(user.username[0].toUpperCase(), style: const TextStyle(fontSize: 40, color: Colors.white)) : null,
                ),
              ),
            ),
            // Camera Button
            Positioned(
              bottom: 5, right: 5,
              child: GestureDetector(
                onTap: _showAvatarSelector,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber, 
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                    boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 5)]
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.black, size: 18),
                ),
              ),
            )
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Nama User
        Text(
          user.username,
          style: GoogleFonts.orbitron(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        
        // Rank Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: rank.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: rank.color.withOpacity(0.6), width: 1.5),
            boxShadow: [
              BoxShadow(color: rank.color.withOpacity(0.2), blurRadius: 15, spreadRadius: 1)
            ]
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(rank.icon, color: rank.color, size: 20),
              const SizedBox(width: 10),
              Text(
                "${rank.name} (${user.mmr})", 
                style: GoogleFonts.orbitron(color: rank.color, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1)
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 2. SECTION BIO
  Widget _buildBioSection(UserModel user) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Text("BIO", style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(
            "\"${user.bio.isNotEmpty ? user.bio : 'Belum ada status.'}\"",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white70, fontStyle: FontStyle.italic, fontSize: 14),
          ),
          const SizedBox(height: 15),
          InkWell(
            onTap: () => _showEditProfileDialog(user),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text("EDIT PROFIL", style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  // 3. SECTION STATISTIK (Grid)
  Widget _buildStatsGrid(UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 10, bottom: 10),
            child: Text("STATISTICS", style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),
          ),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1.6, // Disesuaikan agar tidak terlalu tinggi
            children: [
              _buildStatCard("Level", "${user.level}", Icons.star_rounded, Colors.purpleAccent),
              _buildStatCard("Total XP", "${user.currentXp}", Icons.bolt_rounded, Colors.amber), 
              _buildStatCard("MMR Points", "${user.mmr}", Icons.show_chart_rounded, Colors.greenAccent),
              _buildStatCard("Win / Loss", "${user.winCount} / ${user.lossCount}", Icons.sports_esports_rounded, Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.orbitron(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }
}