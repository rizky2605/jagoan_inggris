import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../models/match_model.dart';
import '../../models/user_model.dart';
import '../../core/services/firestore_service.dart';
import 'match_service.dart';
import 'leaderboard_screen.dart'; 
import 'history_screen.dart';
import 'game_screen.dart'; 

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> with TickerProviderStateMixin {
  late AnimationController _radarController;
  late AnimationController _shakeController;

  final MatchService _matchService = MatchService();
  final FirestoreService _firestoreService = FirestoreService();
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  // State Lobby
  bool _isSearching = false;
  Map<String, dynamic>? _foundOpponentData;
  int _startCount = 3;
  StreamSubscription? _matchSubscription;
  Timer? _heartbeatTimer;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _matchService.syncUserStats(uid);
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
    _shakeController.dispose();
    _heartbeatTimer?.cancel();
    _matchSubscription?.cancel();
    if (_isSearching) _matchService.cancelSearch(uid);
    super.dispose();
  }

  // --- LOGIKA LOBBY (CARI MUSUH) ---

  void _startMatchmaking() async {
    setState(() => _isSearching = true);
    _radarController.repeat();
    
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || !_isSearching || _foundOpponentData != null) {
        timer.cancel();
        return;
      }
      _matchService.updateHeartbeat(uid);
    });

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      UserModel user = UserModel.fromMap(userDoc.data() as Map<String, dynamic>, uid);
      
      String result = await _matchService.findMatch(user);
      if (!mounted || !_isSearching) return; 

      if (result == "WAITING") {
        _listenForQueueMatch(uid);
      } else if (result.isNotEmpty) {
        _handleMatchFound(result, user.uid);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tidak ada lawan."), backgroundColor: Colors.red));
        setState(() => _isSearching = false);
      }
    } catch (e) { debugPrint("UI Error: $e"); }
  }

  void _listenForQueueMatch(String myUid) {
    _matchSubscription?.cancel();
    _matchSubscription = FirebaseFirestore.instance.collection('matches')
        .where('player1Uid', isEqualTo: myUid).where('status', isEqualTo: 'playing')
        .snapshots().listen((snapshot) {
      if (snapshot.docs.isNotEmpty && mounted && _isSearching) {
        _matchSubscription?.cancel();
        _handleMatchFound(snapshot.docs.first.id, myUid);
      }
    });
  }

  void _handleMatchFound(String matchId, String myUid) async {
    _radarController.stop();
    _heartbeatTimer?.cancel();
    HapticFeedback.vibrate();

    var matchDoc = await FirebaseFirestore.instance.collection('matches').doc(matchId).get();
    if (!matchDoc.exists) return;
    var matchData = MatchModel.fromMap(matchDoc.data()!);
    bool isP1 = matchData.player1Uid == myUid;

    if (mounted) {
      setState(() {
        _foundOpponentData = {
          'name': isP1 ? matchData.player2Name : matchData.player1Name,
          'photoUrl': isP1 ? matchData.p2PhotoUrl : matchData.p1PhotoUrl,
          'avatarPath': isP1 ? matchData.p2Avatar : matchData.p1Avatar,
        };
      });
      _shakeController.forward(from: 0);

      for (int i = 3; i >= 1; i--) {
        if (!mounted || !_isSearching) return; 
        setState(() => _startCount = i);
        HapticFeedback.lightImpact();
        await Future.delayed(const Duration(seconds: 1));
      }
      
      if (mounted && _isSearching) {
        setState(() {
          _isSearching = false;
          _foundOpponentData = null; 
        });
        
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => GameScreen(matchId: matchId))
        ).then((_) {
          _matchService.syncUserStats(uid); 
        });
      }
    }
  }

  void _cancelSearch() {
    _matchService.cancelSearch(uid);
    setState(() {
      _isSearching = false;
      _foundOpponentData = null;
    });
  }

  // --- UI BUILDER (LOBBY) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/bg_stars.jpg'), fit: BoxFit.cover)),
        child: Container(
          decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFF050010).withOpacity(0.8), const Color(0xFF1A0038).withOpacity(0.9)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          child: StreamBuilder<UserModel>(
            stream: _firestoreService.getUserStream(uid),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              UserModel myUser = snapshot.data!;
              
              String myAvatarPath = 'assets/models/avatar1.glb'; 
              if (myUser.equippedLoadout['body'] == 'monster') myAvatarPath = 'assets/models/monster1.glb';
              if (myUser.equippedLoadout['body'] == 'teacher') myAvatarPath = 'assets/models/teacher.glb';

              return SafeArea(
                // [FIX OVERFLOW] Menggunakan LayoutBuilder + SingleChildScrollView
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        // Memaksa tinggi minimal setinggi layar agar layout tidak gepeng
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Column(
                          // [FIX] Gunakan spaceBetween untuk meratakan Atas-Tengah-Bawah
                          mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                          children: [
                            _buildHeader(myUser),
                            
                            // Konten Tengah (Avatar)
                            AnimatedBuilder(
                              animation: _shakeController,
                              builder: (context, child) {
                                final double offset = sin(_shakeController.value * pi * 10.0) * 5.0;
                                return Transform.translate(offset: Offset(offset, 0), child: child);
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(child: _buildAvatarCard("KAMU", myUser.username, myAvatarPath, myUser.photoUrl, isPlayer: true)),
                                  _buildCenterStatus(),
                                  Expanded(child: _buildAvatarCard(
                                    "LAWAN", 
                                    _foundOpponentData?['name'] ?? "???", 
                                    _foundOpponentData?['avatarPath'] ?? 'assets/models/avatar1.glb', 
                                    _foundOpponentData?['photoUrl'] ?? '', 
                                    isPlayer: false, isFound: _foundOpponentData != null
                                  )),
                                ],
                              ),
                            ),
                            
                            _buildBottomNav(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(UserModel user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), 
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber), 
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text("RANK MMR", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
                  Text("${user.mmr}", style: GoogleFonts.orbitron(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ]
              ),
            ],
          ),
          Container(height: 30, width: 1, color: Colors.white10),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("BATTLE STATS", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
                  Text("${user.winCount}W - ${user.lossCount}L", style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 14)),
                ],
              ),
              const SizedBox(width: 10),
              const Icon(Icons.bar_chart, color: Colors.cyanAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarCard(String label, String name, String avatar3d, String photoUrl, {required bool isPlayer, bool isFound = true}) {
    return Column(children: [
      Text(label, style: GoogleFonts.orbitron(color: isPlayer ? Colors.cyanAccent : (isFound ? Colors.redAccent : Colors.grey), fontSize: 12, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      Container(
        height: 240, width: 160,
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(20), border: Border.all(color: isPlayer ? Colors.cyanAccent.withOpacity(0.5) : (isFound ? Colors.redAccent.withOpacity(0.5) : Colors.white10), width: 2)),
        child: Stack(alignment: Alignment.bottomCenter, children: [
          if (isPlayer || isFound)
            Padding(
              padding: const EdgeInsets.only(bottom: 40), 
              child: ModelViewer(
                key: ValueKey('lobby_stay_$avatar3d'), 
                src: avatar3d, 
                animationName: 'stay', 
                autoPlay: true, 
                autoRotate: false, 
                cameraControls: false, 
                backgroundColor: Colors.transparent, 
                disableZoom: true,
                exposure: 8
              )
            )
          else const Center(child: Icon(Icons.person_off_rounded, size: 50, color: Colors.white12)),
          
          if (isPlayer || isFound) Container(width: double.infinity, padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.vertical(bottom: Radius.circular(18))), child: Text(name, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis))
        ]),
      ),
    ]);
  }

  Widget _buildCenterStatus() {
    if (_foundOpponentData != null) return Column(children: [Text("VS", style: GoogleFonts.blackOpsOne(fontSize: 40, color: Colors.white)), Text("$_startCount", style: GoogleFonts.orbitron(color: Colors.amber, fontSize: 30))]);
    if (_isSearching) return RotationTransition(turns: _radarController, child: Container(width: 70, height: 70, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.cyanAccent), gradient: SweepGradient(colors: [Colors.transparent, Colors.cyanAccent.withOpacity(0.8)])), child: const Center(child: Icon(Icons.search, color: Colors.white))));
    return const Text("VS", style: TextStyle(color: Colors.white12, fontSize: 30, fontWeight: FontWeight.bold));
  }

  Widget _buildBottomNav() {
    return Padding(padding: const EdgeInsets.all(30), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _btn(Icons.leaderboard, "RANK", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen()))),
      const SizedBox(width: 25),
      if (!_isSearching) GestureDetector(onTap: () { HapticFeedback.mediumImpact(); _startMatchmaking(); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.cyan, Colors.blueAccent]), borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.cyan.withOpacity(0.4), blurRadius: 15)]), child: Row(children: [const Icon(Icons.flash_on, color: Colors.white), const SizedBox(width: 10), Text("BATTLE", style: GoogleFonts.blackOpsOne(color: Colors.white, fontSize: 18))]),))
      else if (_foundOpponentData == null) _btn(Icons.close, "BATAL", _cancelSearch),
      const SizedBox(width: 25),
      _btn(Icons.history, "HISTORY", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()))),
    ]));
  }

  Widget _btn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Column(children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white10, shape: BoxShape.circle, border: Border.all(color: Colors.white10)), child: Icon(icon, color: Colors.white70)), const SizedBox(height: 8), Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10))]));
  }
}