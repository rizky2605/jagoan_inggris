import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';

// [PENTING] Import file AuthScreen Anda (sesuaikan path folder jika perlu)
import '../auth/auth_screen.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Helper untuk mendapatkan current user
  User? get currentUser => FirebaseAuth.instance.currentUser;
  String get uid => currentUser?.uid ?? "";

  // --- LOGOUT (DIPERBAIKI) ---
  void _handleLogout() async {
    // 1. Tampilkan Konfirmasi
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text("Logout", style: TextStyle(color: Colors.white)),
        content: const Text("Apakah Anda yakin ingin keluar?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text("Batal", style: TextStyle(color: Colors.grey))
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Keluar", style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        // 2. Proses Logout Firebase
        await FirebaseAuth.instance.signOut();
        
        // 3. Cek apakah widget masih aktif (mounted) sebelum navigasi
        if (!mounted) return;

        // 4. Navigasi Paksa ke AuthScreen (Hapus semua history stack)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen()), 
          (route) => false,
        );
      } catch (e) {
        debugPrint("Gagal Logout: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal Logout: $e")),
          );
        }
      }
    }
  }

  // --- EDIT BIO & NAME ---
  void _showEditProfileDialog(UserModel user) {
    final nameController = TextEditingController(text: user.username);
    final bioController = TextEditingController(text: user.bio.isNotEmpty ? user.bio : "Jagoan Inggris siap bertarung!"); 
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text("Edit Profil", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Username", labelStyle: TextStyle(color: Colors.cyanAccent)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: bioController, 
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Bio / Moto", labelStyle: TextStyle(color: Colors.cyanAccent)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
            child: const Text("Simpan", style: TextStyle(color: Colors.black)),
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
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Pilih Avatar", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: avatars.map((url) {
                  return GestureDetector(
                    onTap: () async {
                      if (uid.isNotEmpty) {
                        await FirebaseFirestore.instance.collection('users').doc(uid).update({'photoUrl': url});
                      }
                      if (mounted) Navigator.pop(context);
                    },
                    child: CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(url),
                      backgroundColor: Colors.white10,
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
    // [PENTING] Cek jika user null (Untuk mencegah crash saat logout)
    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0025),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0025),
      appBar: AppBar(
        title: Text("PROFIL PLAYER", style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _handleLogout,
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          // Cek ekstra jika dokumen user tidak ditemukan
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text("Data User Error", style: TextStyle(color: Colors.white)));
          
          var data = snapshot.data!.data() as Map<String, dynamic>;
          UserModel user = UserModel.fromMap(data, uid);
          String bio = data['bio'] ?? "Belum ada bio."; 

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // 1. AVATAR & NAMA
                Center(
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.cyanAccent, width: 3),
                          boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.5), blurRadius: 20)],
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.black,
                          backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                          child: user.photoUrl.isEmpty ? Text(user.username[0], style: const TextStyle(fontSize: 40)) : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: GestureDetector(
                          onTap: _showAvatarSelector,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, color: Colors.black, size: 20),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Text(user.username, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                Text(user.rankName, style: const TextStyle(color: Colors.amber, fontSize: 16)),
                
                const SizedBox(height: 10),
                
                // 2. BIO SECTION
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      Text(bio, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => _showEditProfileDialog(user),
                        child: const Text("Edit Profil", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 3. STATISTIK GRID
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard("Level", "${user.level}", Icons.star, Colors.purpleAccent),
                      _buildStatCard("Total XP", "${user.currentXp}", Icons.bolt, Colors.amber), 
                      _buildStatCard("MMR", "${user.mmr}", Icons.show_chart, Colors.greenAccent),
                      _buildStatCard("Win/Loss", "${user.winCount}/${user.lossCount}", Icons.sports_esports, Colors.redAccent),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}