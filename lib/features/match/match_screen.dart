import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../models/user_model.dart';
import '../../core/services/firestore_service.dart';
import 'match_service.dart';
import 'history_screen.dart';
import 'leaderboard_screen.dart'; 
import 'game_screen.dart'; 

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> with TickerProviderStateMixin {
  // Services
  final MatchService _matchService = MatchService();
  final FirestoreService _firestoreService = FirestoreService();
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  // Controllers
  late AnimationController _radarController;
  
  // State
  bool _isSearching = false;
  Map<String, dynamic>? _foundOpponent; 
  int _countdown = 3;
  
  StreamSubscription? _matchSub;
  Timer? _heartbeat;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    
    // Sync data user terbaru saat masuk screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _matchService.syncUserStats(uid);
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
    _heartbeat?.cancel();
    _matchSub?.cancel();
    if (_isSearching) _matchService.cancelSearch(uid);
    super.dispose();
  }

  // ==========================================
  // 1. LOGIKA ASET (FIXED SESUAI DATABASE)
  // ==========================================

  String _getCharFilename(Map<String, dynamic> loadout) {
    // DATABASE STRUCTURE:
    // body: "avatar2"
    // head: "hat1"
    // wings: "none"
    // effect: "fire" (Kita abaikan effect untuk visual karakter)
    
    // LOGIC PERBAIKAN: Gunakan key 'body' & 'head'
    String body = loadout['body'] ?? 'avatar1'; 
    String head = loadout['head'] ?? 'none';    
    String wings = loadout['wings'] ?? 'none';  
    
    // RUMUS FILE: assets/models/{body}_{head}_{wings}.glb
    return 'assets/models/${body}_${head}_${wings}.glb';
  }

  // ==========================================
  // 2. MATCHMAKING LOGIC
  // ==========================================

  void _onTapSearch() async {
    if (_isSearching) {
      _cancelSearch();
      return;
    }

    setState(() => _isSearching = true);
    _radarController.repeat();

    _heartbeat = Timer.periodic(const Duration(seconds: 5), (t) {
      if (!_isSearching || _foundOpponent != null) {
        t.cancel();
        return;
      }
      _matchService.updateHeartbeat(uid);
    });

    try {
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      var user = UserModel.fromMap(userDoc.data()!, uid);

      String matchId = await _matchService.findMatch(user);

      if (!mounted || !_isSearching) return;

      if (matchId == "WAITING") {
        _listenQueue(uid);
      } else if (matchId.isNotEmpty) {
        _processFoundMatch(matchId, uid);
      } else {
        _cancelSearch();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tidak ada lawan.")));
      }
    } catch (e) {
      debugPrint("Error: $e");
      _cancelSearch();
    }
  }

  void _listenQueue(String myUid) {
    _matchSub = FirebaseFirestore.instance.collection('matches')
        .where('player1Uid', isEqualTo: myUid)
        .where('status', isEqualTo: 'playing')
        .snapshots().listen((snap) {
      if (snap.docs.isNotEmpty && _isSearching) {
        _matchSub?.cancel();
        _processFoundMatch(snap.docs.first.id, myUid);
      }
    });
  }

  void _processFoundMatch(String matchId, String myUid) async {
    _radarController.stop();
    HapticFeedback.heavyImpact();

    var doc = await FirebaseFirestore.instance.collection('matches').doc(matchId).get();
    var data = doc.data()!;
    bool isP1 = data['player1Uid'] == myUid;

    var enemyLoadout = isP1 ? data['p2Loadout'] : data['p1Loadout'];
    var enemyName = isP1 ? data['player2Name'] : data['player1Name'];

    setState(() {
      _foundOpponent = {
        'name': enemyName,
        'loadout': enemyLoadout ?? {}, 
      };
    });

    for (int i = 3; i > 0; i--) {
      if (!mounted) return;
      setState(() => _countdown = i);
      await Future.delayed(const Duration(seconds: 1));
    }

    if (mounted) {
      setState(() {
        _isSearching = false;
        _foundOpponent = null;
        _countdown = 3;
      });
      Navigator.push(context, MaterialPageRoute(builder: (_) => GameScreen(matchId: matchId)));
    }
  }

  void _cancelSearch() {
    _matchService.cancelSearch(uid);
    setState(() {
      _isSearching = false;
      _foundOpponent = null;
      _radarController.stop();
    });
  }

  // ==========================================
  // 3. UI BUILDER (MODERN LAYOUT)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050010),
      body: StreamBuilder<UserModel>(
        stream: _firestoreService.getUserStream(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var myUser = snapshot.data!;

          return Container(
            decoration: const BoxDecoration(
              image: DecorationImage(image: AssetImage('assets/images/bg_stars.jpg'), fit: BoxFit.cover, opacity: 0.6),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // --- HEADER: STATS BAR ---
                  _buildTopStats(myUser),

                  // --- MAIN AREA: AVATAR BOXES ---
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // PLAYER BOX (KIRI)
                          Expanded(
                            child: _buildAvatarBox(
                              name: "KAMU",
                              loadout: myUser.equippedLoadout,
                              isEnemy: false,
                            ),
                          ),

                          // VS INDICATOR / RADAR
                          SizedBox(
                            width: 60,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_foundOpponent != null)
                                  Text("$_countdown", style: GoogleFonts.blackOpsOne(fontSize: 40, color: Colors.amber))
                                else if (_isSearching)
                                  RotationTransition(
                                    turns: _radarController,
                                    child: const Icon(Icons.incomplete_circle, color: Colors.cyanAccent, size: 40),
                                  )
                                else
                                  Text("VS", style: GoogleFonts.blackOpsOne(fontSize: 30, color: Colors.white24)),
                              ],
                            ),
                          ),

                          // ENEMY BOX (KANAN)
                          Expanded(
                            child: _foundOpponent != null
                                ? _buildAvatarBox(
                                    name: _foundOpponent!['name'],
                                    loadout: _foundOpponent!['loadout'],
                                    isEnemy: true,
                                  )
                                : _buildEmptyBox(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- BOTTOM: CONTROLS ---
                  _buildBottomControls(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildTopStats(UserModel user) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withOpacity(0.8), // Semi-transparent dark blue
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // KIRI: MMR
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 22),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("RANK MMR", style: GoogleFonts.orbitron(color: Colors.white38, fontSize: 9, letterSpacing: 1)),
                  Text("${user.mmr}", style: GoogleFonts.orbitron(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          
          Container(width: 1, height: 25, color: Colors.white10),

          // KANAN: STATS
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("WIN / LOSS", style: GoogleFonts.orbitron(color: Colors.white38, fontSize: 9, letterSpacing: 1)),
                  Text("${user.winCount} - ${user.lossCount}", style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(width: 10),
              const Icon(Icons.pie_chart, color: Colors.cyanAccent, size: 22),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarBox({required String name, required Map<String, dynamic> loadout, required bool isEnemy}) {
    String charPath = _getCharFilename(loadout);
    Color themeColor = isEnemy ? const Color(0xFFFF3D3D) : const Color(0xFF00E5FF); // Neon Red vs Neon Cyan

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeColor.withOpacity(0.6), width: 2),
        boxShadow: [
          BoxShadow(color: themeColor.withOpacity(0.15), blurRadius: 15, spreadRadius: 1)
        ]
      ),
      child: Column(
        children: [
          // Name Tag
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              border: Border(bottom: BorderSide(color: themeColor.withOpacity(0.3))),
            ),
            child: Text(
              name.toUpperCase(),
              textAlign: TextAlign.center,
              style: GoogleFonts.orbitron(
                color: themeColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // 3D Model View
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
              child: ModelViewer(
                // Key unik agar force refresh saat loadout berubah
                key: ValueKey("char_${isEnemy ? 'enemy' : 'me'}_$charPath"), 
                src: charPath,
                animationName: 'stay', 
                autoPlay: true,
                autoRotate: false,
                cameraControls: false,
                backgroundColor: Colors.transparent,
                disableZoom: true,
                exposure: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBox() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10, width: 2),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Text("WAITING...", textAlign: TextAlign.center, style: GoogleFonts.orbitron(color: Colors.white30, fontSize: 12)),
          ),
          const Expanded(
            child: Center(
              child: Icon(Icons.question_mark_rounded, size: 40, color: Colors.white12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 1. HISTORY BUTTON
          _buildMenuBtn(
            icon: Icons.history, 
            label: "LOGS",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
          ),

          // 2. SEARCH BUTTON (CENTER - BIG)
          GestureDetector(
            onTap: _onTapSearch,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isSearching 
                      ? [const Color(0xFFFF512F), const Color(0xFFDD2476)] // Red/Pink Gradient
                      : [const Color(0xFF4FACFE), const Color(0xFF00F2FE)], // Blue/Cyan Gradient
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: _isSearching ? Colors.redAccent.withOpacity(0.4) : Colors.cyan.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Text(
                _isSearching ? "CANCEL" : "BATTLE",
                style: GoogleFonts.blackOpsOne(color: Colors.white, fontSize: 18, letterSpacing: 2),
              ),
            ),
          ),

          // 3. LEADERBOARD BUTTON
          _buildMenuBtn(
            icon: Icons.leaderboard_rounded, 
            label: "RANK",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuBtn({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: Icon(icon, color: Colors.white70, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.orbitron(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}