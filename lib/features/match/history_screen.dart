import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/match_model.dart';
import 'match_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MatchService matchService = MatchService();
    final String myUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF050010),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text("RIWAYAT", style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF050010), Color(0xFF1A0038)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<List<MatchModel>>(
          stream: matchService.getMatchHistory(myUid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("Belum ada riwayat pertandingan.", style: TextStyle(color: Colors.white54)));
            }

            // Urutkan manual karena query client-side filter
            List<MatchModel> matches = snapshot.data!;
            // matches.sort((a, b) => b.matchId.compareTo(a.matchId)); // Sort sederhana by ID jika timestamp blm ada

            return ListView.builder(
              itemCount: matches.length,
              padding: const EdgeInsets.all(20),
              itemBuilder: (context, index) {
                MatchModel match = matches[index];
                
                // Tentukan Posisi
                bool amIP1 = match.player1Uid == myUid;
                
                // Data Saya vs Lawan
                String oppName = amIP1 ? match.player2Name : match.player1Name;
                int myScore = amIP1 ? match.p1Score : match.p2Score;
                int oppScore = amIP1 ? match.p2Score : match.p1Score;
                int myHp = amIP1 ? match.p1Health : match.p2Health;
                int oppHp = amIP1 ? match.p2Health : match.p1Health;

                // Tentukan Menang/Kalah (Sesuai Logic Service)
                bool isWin = false;
                if (myHp > oppHp) isWin = true;
                else if (myHp == oppHp && myScore > oppScore) isWin = true;
                
                Color resultColor = isWin ? Colors.greenAccent : Colors.redAccent;

                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: resultColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Status (Menang/Kalah)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isWin ? "VICTORY" : "DEFEAT",
                            style: GoogleFonts.blackOpsOne(color: resultColor, fontSize: 18),
                          ),
                          const SizedBox(height: 5),
                          Text("vs $oppName", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                      
                      // Score
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "HP: $myHp - $oppHp",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Score: $myScore - $oppScore",
                            style: const TextStyle(color: Colors.white54, fontSize: 10),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            isWin ? "+25 MMR" : "-15 MMR",
                            style: TextStyle(color: resultColor, fontSize: 10, fontWeight: FontWeight.bold),
                          )
                        ],
                      )
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}