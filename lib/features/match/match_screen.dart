import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../models/user_model.dart';
import '../../core/services/firestore_service.dart';
import '../../core/utils/rank_helper.dart'; 
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
  final MatchService _matchService = MatchService();
  final FirestoreService _firestoreService = FirestoreService();
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  late AnimationController _radarController;
  late AnimationController _pulseController;
  
  bool _isSearching = false;
  Map<String, dynamic>? _foundOpponent; 
  int _countdown = 3;
  
  StreamSubscription? _matchSub;
  Timer? _heartbeat;

  final Color _playerThemeColor = Colors.cyanAccent;
  final Color _enemyThemeColor = const Color(0xFFFF0055); // Neon Red

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _matchService.syncUserStats(uid);
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
    _pulseController.dispose();
    _heartbeat?.cancel();
    _matchSub?.cancel();
    if (_isSearching) _matchService.cancelSearch(uid);
    super.dispose();
  }

  String _getCharFilename(Map<String, dynamic> loadout) {
    String body = loadout['body'] ?? 'avatar1'; 
    String head = loadout['head'] ?? 'none';    
    String wings = loadout['wings'] ?? 'none';  
    return 'assets/models/${body}_${head}_${wings}.glb';
  }

  // --- LOGIC SEARCH ---
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

    var enemyUid = isP1 ? data['player2Uid'] : data['player1Uid'];
    var enemyName = isP1 ? data['player2Name'] : data['player1Name'];
    var enemyLoadout = isP1 ? data['p2Loadout'] : data['p1Loadout'];

    int enemyMmr = 0;
    try {
      var enemyDoc = await FirebaseFirestore.instance.collection('users').doc(enemyUid).get();
      if (enemyDoc.exists) {
        enemyMmr = enemyDoc.data()?['mmr'] ?? 0;
      }
    } catch (e) {
      debugPrint("Gagal ambil mmr musuh: $e");
    }

    setState(() {
      _foundOpponent = {
        'name': enemyName,
        'loadout': enemyLoadout ?? {}, 
        'mmr': enemyMmr, 
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
  // UI BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    
    // [FIX] Memperbesar ukuran box agar lebih tinggi ke bawah
    double boxHeight = isLandscape ? 280 : 450; 

    return Scaffold(
      backgroundColor: const Color(0xFF050010),
      body: StreamBuilder<UserModel>(
        stream: _firestoreService.getUserStream(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: _playerThemeColor));
          var myUser = snapshot.data!;
          
          // Hitung Win Rate
          int totalGames = myUser.winCount + myUser.lossCount;
          String winRateStr = totalGames == 0 
              ? "0.0" 
              : ((myUser.winCount / totalGames) * 100).toStringAsFixed(1);

          var myRank = RankHelper.getRank(myUser.mmr);

          return Container(
            decoration: const BoxDecoration(
              image: DecorationImage(image: AssetImage('assets/images/bg_stars.jpg'), fit: BoxFit.cover, opacity: 0.5),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // 1. TOP STATS BAR (Kiri: MMR, Tengah: Rank, Kanan: WinRate)
                  _buildTopStatsBar(myUser.mmr, winRateStr, myRank),

                  const Spacer(),

                  // 2. ARENA UTAMA
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // --- PLAYER (KIRI) ---
                        Expanded(
                          flex: 4, 
                          child: _buildCharacterBox(
                            name: myUser.username,
                            loadout: myUser.equippedLoadout,
                            mmr: myUser.mmr, 
                            glowColor: _playerThemeColor,
                            isEnemy: false, // Player sendiri
                            boxHeight: boxHeight,
                          ),
                        ),

                        // --- CONTROLS (TENGAH) ---
                        Expanded(
                          flex: 3, 
                          child: _buildCenterControlPanel(myRank.color),
                        ),

                        // --- ENEMY (KANAN) ---
                        Expanded(
                          flex: 4,
                          child: _foundOpponent != null
                              ? _buildCharacterBox(
                                  name: _foundOpponent!['name'],
                                  loadout: _foundOpponent!['loadout'],
                                  mmr: _foundOpponent!['mmr'], 
                                  glowColor: _enemyThemeColor,
                                  isEnemy: true, // Musuh
                                  boxHeight: boxHeight,
                                )
                              : _buildSearchingPlaceholder(boxHeight),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- [FIX] TOP BAR SESUAI REQUEST ---
  Widget _buildTopStatsBar(int mmr, String winRate, RankInfo rank) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KIRI ATAS: MMR
          _buildInfoPill(
            icon: Icons.show_chart_rounded,
            label: "MMR",
            value: "$mmr",
            color: _playerThemeColor,
            alignLeft: true,
          ),

          // TENGAH ATAS: RANK (Gold, dll)
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: rank.color.withOpacity(0.5), blurRadius: 20, spreadRadius: 1)]
                ),
                child: Icon(rank.icon, size: 36, color: rank.color),
              ),
              const SizedBox(height: 4),
              Text(
                rank.name.toUpperCase(), 
                style: GoogleFonts.orbitron(color: rank.color, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
            ],
          ),

          // KANAN ATAS: BATTLE STAT (Win Rate)
          _buildInfoPill(
            icon: Icons.bolt, 
            label: "WIN RATE",
            value: "$winRate%",
            color: Colors.amber,
            alignLeft: false, // Align Right
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPill({required IconData icon, required String label, required String value, required Color color, required bool alignLeft}) {
    return Column(
      crossAxisAlignment: alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (alignLeft) Icon(icon, color: color, size: 14),
            if (alignLeft) const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
            if (!alignLeft) const SizedBox(width: 4),
            if (!alignLeft) Icon(icon, color: color, size: 14),
          ],
        ),
        Text(value, style: GoogleFonts.orbitron(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // --- PANEL TENGAH ---
  Widget _buildCenterControlPanel(Color rankColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 50,
          child: Center(child: _buildCenterIndicator()),
        ),
        const SizedBox(height: 15),
        GestureDetector(
          onTap: _onTapSearch,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              double scale = 1.0 + (_isSearching ? 0.05 * _pulseController.value : 0.0);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 130),
                  padding: const EdgeInsets.symmetric(vertical: 14), 
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isSearching 
                          ? [const Color(0xFFFF512F), const Color(0xFFDD2476)] 
                          : [const Color(0xFF00C6FF), const Color(0xFF0072FF)], 
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _isSearching ? _enemyThemeColor.withOpacity(0.6) : _playerThemeColor.withOpacity(0.6),
                        blurRadius: 15, spreadRadius: 1,
                      )
                    ],
                    border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5)
                  ),
                  child: Center(
                    child: Text(
                      _isSearching ? "CANCEL" : "BATTLE",
                      style: GoogleFonts.blackOpsOne(color: Colors.white, fontSize: 18, letterSpacing: 1.5),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMiniButton(Icons.history, "LOGS", Colors.white54, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()))),
            const SizedBox(width: 25),
            _buildMiniButton(Icons.emoji_events, "Leaderboard", rankColor, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen()))),
          ],
        )
      ],
    );
  }

  Widget _buildMiniButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.orbitron(color: Colors.white54, fontSize: 8)),
        ],
      ),
    );
  }

  // --- [FIX] WIDGET PROFIL KARAKTER (TALLER & CLEANER) ---
  Widget _buildCharacterBox({
    required String name, 
    required Map<String, dynamic> loadout, 
    required int mmr, 
    required Color glowColor, 
    required bool isEnemy,
    required double boxHeight,
  }) {
    var rankInfo = RankHelper.getRank(mmr);

    return Container(
      height: boxHeight, 
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [glowColor.withOpacity(0.15), Colors.transparent]
        ),
        border: Border.all(color: glowColor.withOpacity(0.5), width: 1.5),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.1),
            blurRadius: 20, spreadRadius: 1,
          )
        ]
      ),
      child: Column(
        children: [
          // 1. MODEL 3D (EXPANDED AGAR MENGISI RUANG)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ModelViewer(
                key: ValueKey("char_$name${_getCharFilename(loadout)}"), 
                src: _getCharFilename(loadout),
                animationName: isEnemy ? 'idle' : 'stay', 
                autoPlay: true,
                autoRotate: false,
                cameraControls: false,
                backgroundColor: Colors.transparent,
                disableZoom: true,
                exposure: 4.0, 
              ),
            ),
          ),

          // 2. INFO PANEL BAWAH
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
              border: Border(top: BorderSide(color: glowColor.withOpacity(0.3))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Username (Semua Punya)
                Text(
                  name.toUpperCase(),
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                
                // [FIX] Logic Tampilan Beda Player vs Enemy
                if (isEnemy) ...[
                  // Musuh: Tampilkan Rank (Tanpa MMR Angka)
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(rankInfo.icon, color: rankInfo.color, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        rankInfo.name, 
                        style: GoogleFonts.orbitron(color: rankInfo.color, fontSize: 10, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                ] else ...[
                  // Player: Hanya Username (MMR sudah di pojok kiri atas)
                  // Kosongkan agar bersih
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchingPlaceholder(double height) {
    return Container(
      height: height, 
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        border: Border.all(color: Colors.white12, width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RotationTransition(
            turns: _radarController,
            child: Icon(Icons.location_searching, color: Colors.white10, size: 60),
          ),
          const SizedBox(height: 20),
          Text(
            _isSearching ? "SCANNING..." : "WAITING", 
            style: GoogleFonts.orbitron(color: Colors.white24, fontSize: 12, letterSpacing: 2)
          ),
        ],
      ),
    );
  }

  Widget _buildCenterIndicator() {
    if (_foundOpponent != null) {
      return Text(
        "$_countdown", 
        style: GoogleFonts.blackOpsOne(
          fontSize: 40, 
          color: Colors.white, 
          shadows: [BoxShadow(color: Colors.redAccent.withOpacity(0.8), blurRadius: 30, spreadRadius: 10)]
        )
      );
    }
    if (_isSearching) {
      return const SizedBox(
        width: 30, height: 30,
        child: CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 3),
      );
    }
    return Text("VS", style: GoogleFonts.blackOpsOne(fontSize: 30, color: Colors.white10));
  }
}