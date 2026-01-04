import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart'; // Import Model 3D
import '../../models/user_model.dart';
import '../../models/level_model.dart';
import '../../core/services/firestore_service.dart';
import '../quiz/quiz_screen.dart';
import '../../models/question_model.dart'; // Import Bank Soal

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _radarController;
  
  final FirestoreService _firestoreService = FirestoreService();
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  
  bool _isSearching = false;
  UserModel? _opponent; // Menyimpan data lawan yang ditemukan

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _radarController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _radarController.dispose();
    super.dispose();
  }

  void _startMatchmaking(UserModel myUser) async {
    setState(() {
      _isSearching = true;
      _opponent = null; // Reset lawan
    });
    _radarController.repeat();

    // 1. Simulasi delay network
    await Future.delayed(const Duration(seconds: 3));

    try {
      // 2. Cari Lawan
      UserModel? foundOpponent = await _firestoreService.findOpponent(uid);

      if (foundOpponent != null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _opponent = foundOpponent; // Tampilkan Avatar Lawan
        });
        _radarController.stop();

        // 3. Delay sejenak biar player lihat lawannya siapa
        await Future.delayed(const Duration(seconds: 2));

        if (!mounted) return; // Cek mounted lagi sebelum navigasi

        // 4. Siapkan Soal Acak
        List<QuestionModel> battleQuestions = [];
        if (grammarQuestionBank.isNotEmpty) {
           battleQuestions = List.from(grammarQuestionBank);
           battleQuestions.shuffle();
           battleQuestions = battleQuestions.take(5).toList();
        }

        // 5. Masuk ke Arena
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizScreen(
              level: LevelModel(id: 999, title: "PVP BATTLE", subtitle: "Ranked Match", type: 'pvp'),
              user: myUser,
              customQuestions: battleQuestions, // Kirim soal ini
              opponentName: foundOpponent.username,
            ),
          ),
        );
        if (!mounted) return;
        setState(() => _isSearching = false);
      } else {
        if (!mounted) return;
        setState(() => _isSearching = false);
        _radarController.reset();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tidak ada lawan ditemukan.")));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSearching = false);
      _radarController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Background dihandle MainScreen
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.8),
        title: const Text("ARENA", style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.cyanAccent,
          labelColor: Colors.cyanAccent,
          unselectedLabelColor: Colors.white54,
          tabs: const [Tab(text: "LOBBY"), Tab(text: "RANKING")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLobby(), // Tab 1
          const Center(child: Text("Leaderboard Here", style: TextStyle(color: Colors.white))), // Tab 2 Placeholder
        ],
      ),
    );
  }

  // --- UI LOBBY (KIRI - TENGAH - KANAN) ---
  Widget _buildLobby() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        UserModel myUser = UserModel.fromMap(snapshot.data!.data() as Map<String, dynamic>, uid);

        return Container(
          decoration: const BoxDecoration(
            image: DecorationImage(image: AssetImage("assets/images/bg_stars.jpg"), fit: BoxFit.cover),
          ),
          child: Row(
            children: [
              // --- KIRI: PLAYER (KITA) ---
              Expanded(
                flex: 3,
                child: _buildPlayerCard(myUser, isMe: true),
              ),

              // --- TENGAH: RADAR / VS ---
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isSearching && _opponent == null)
                      _buildRadar() // Tampilkan Radar
                    else if (_opponent != null)
                      const Text("VS", style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.redAccent, fontFamily: 'Orbitron'))
                    else
                      ElevatedButton(
                        onPressed: () => _startMatchmaking(myUser),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          elevation: 10,
                          shadowColor: Colors.cyanAccent,
                        ),
                        child: const Text("CARI LAWAN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    
                    const SizedBox(height: 20),
                    Text(
                      _isSearching ? (_opponent != null ? "LAWAN DITEMUKAN!" : "MENCARI...") : "SIAP TEMPUR",
                      style: const TextStyle(color: Colors.white, letterSpacing: 2),
                    )
                  ],
                ),
              ),

              // --- KANAN: LAWAN (MISTERIUS -> MUNCUL) ---
              Expanded(
                flex: 3,
                child: _opponent != null 
                  ? _buildPlayerCard(_opponent!, isMe: false) // Tampilkan Lawan
                  : _buildEmptySlot(), // Slot Kosong
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget Kartu Player (Kiri/Kanan)
  Widget _buildPlayerCard(UserModel user, {required bool isMe}) {
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isMe ? Colors.blue.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isMe ? Colors.cyanAccent : Colors.redAccent),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Nama & Rank
          Text(user.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(user.rankName, style: TextStyle(color: isMe ? Colors.cyanAccent : Colors.redAccent, fontSize: 12)),
          
          const SizedBox(height: 10),
          
          // Avatar 3D
          Expanded(
            child: ModelViewer(
              // Jika lawan blm punya loadout, kasih default monster/avatar
              src: isMe 
                  ? 'assets/models/avatar_default.glb' 
                  : (user.uid.hashCode % 2 == 0 ? 'assets/models/monster.glb' : 'assets/models/avatar_default.glb'),
              autoRotate: true,
              cameraControls: false,
              backgroundColor: Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }

  // Widget Slot Kosong (Kanan sebelum ketemu)
  Widget _buildEmptySlot() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white12, width: 2, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Icon(Icons.question_mark, size: 50, color: Colors.white24),
      ),
    );
  }

  // Animasi Radar
  Widget _buildRadar() {
    return RotationTransition(
      turns: _radarController,
      child: Container(
        width: 120, height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [Colors.transparent, Colors.cyanAccent.withValues(alpha: 0.5)],
          ),
          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
        ),
      ),
    );
  }
}