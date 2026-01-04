import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../core/services/firestore_service.dart';
import '../../models/level_model.dart';
import '../quiz/quiz_screen.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  bool _isSearching = false; // Status sedang mencari lawan

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // --- LOGIKA MATCHMAKING ---
  void _startMatchmaking(UserModel user) async {
    setState(() => _isSearching = true);

    // Simulasi mencari lawan (Delay 2 detik)
    // Nanti di sini logika Backend "Cloud Functions" bekerja
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isSearching = false);
      
      // LOGIKA SEMENTARA: 
      // Karena real-time multiplayer butuh server canggih, 
      // kita arahkan ke Mode "Ranked Quiz" (Soal lebih sulit/acak).
      // Kita pakai Level dummy ID 999 sebagai penanda "Ranked Match".
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizScreen(
            level: LevelModel(id: 999, title: "RANKED MATCH", subtitle: "VS Random Opponent", type: 'test'),
            user: user,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Transparan agar background MainScreen terlihat
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        toolbarHeight: 0, // Sembunyikan AppBar default
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.cyanAccent,
          labelColor: Colors.cyanAccent,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "BATTLE"),
            Tab(text: "LEADERBOARD"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBattleTab(),      // Tab 1: Lobby
          _buildLeaderboardTab(), // Tab 2: Peringkat
        ],
      ),
    );
  }

  // --- TAB 1: BATTLE LOBBY ---
  Widget _buildBattleTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        // Parsing data aman
        Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
        UserModel user = UserModel.fromMap(data, uid);

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Rank Badge (Lingkaran Neon)
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.purpleAccent, width: 4),
                  boxShadow: [
                    BoxShadow(color: Colors.purpleAccent.withOpacity(0.5), blurRadius: 40, spreadRadius: 10)
                  ],
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2A0045), Color(0xFF000000)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shield, size: 60, color: Colors.amber),
                    const SizedBox(height: 10),
                    Text(
                      user.rankName.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text(
                      "${user.mmr} MMR",
                      style: const TextStyle(color: Colors.cyanAccent, fontSize: 14),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 50),

              // Statistik Menang/Kalah
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatItem("WIN", user.winCount, Colors.greenAccent),
                  Container(height: 30, width: 1, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 20)),
                  _buildStatItem("LOSS", user.lossCount, Colors.redAccent),
                ],
              ),

              const SizedBox(height: 50),

              // Tombol Cari Lawan
              if (_isSearching)
                Column(
                  children: const [
                    CircularProgressIndicator(color: Colors.cyanAccent),
                    SizedBox(height: 20),
                    Text("MENCARI LAWAN...", style: TextStyle(color: Colors.white70, letterSpacing: 2)),
                  ],
                )
              else
                ElevatedButton(
                  onPressed: () => _startMatchmaking(user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 10,
                    shadowColor: Colors.cyanAccent,
                  ),
                  child: const Text("CARI LAWAN", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text("$value", style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  // --- TAB 2: LEADERBOARD ---
  Widget _buildLeaderboardTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getLeaderboard(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        List<Map<String, dynamic>> players = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: players.length,
          itemBuilder: (context, index) {
            final player = players[index];
            bool isTop3 = index < 3;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: player['isMe'] 
                    ? Colors.cyanAccent.withOpacity(0.2) // Highlight diri sendiri
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: player['isMe'] ? Border.all(color: Colors.cyanAccent) : null,
              ),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isTop3 ? Colors.amber : Colors.grey[800],
                  ),
                  child: Text(
                    "#${index + 1}",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
                title: Text(
                  player['username'],
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  player['rank_name'],
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.purpleAccent, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      "${player['mmr']}",
                      style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}