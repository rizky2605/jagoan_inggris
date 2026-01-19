import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../core/services/firestore_service.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    final String myUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF050010),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text("TOP JAGOAN", style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
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
        child: StreamBuilder<List<UserModel>>(
          stream: firestoreService.getLeaderboard(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("Belum ada data.", style: TextStyle(color: Colors.white)));
            }

            List<UserModel> users = snapshot.data!;

            return ListView.builder(
              itemCount: users.length,
              padding: const EdgeInsets.all(20),
              itemBuilder: (context, index) {
                UserModel user = users[index];
                bool isMe = user.uid == myUid;
                
                // Warna Ranking
                Color rankColor = Colors.white;
                if (index == 0) rankColor = const Color(0xFFFFD700); // Gold
                if (index == 1) rankColor = const Color(0xFFC0C0C0); // Silver
                if (index == 2) rankColor = const Color(0xFFCD7F32); // Bronze

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.cyanAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: isMe ? Colors.cyanAccent : Colors.white10),
                  ),
                  child: Row(
                    children: [
                      // Rank Number
                      SizedBox(
                        width: 40,
                        child: Text(
                          "#${index + 1}",
                          style: GoogleFonts.orbitron(color: rankColor, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Avatar (Circle)
                      CircleAvatar(
                        backgroundColor: Colors.white10,
                        backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                        child: user.photoUrl.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                      ),
                      const SizedBox(width: 15),
                      // Nama
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.username,
                              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "Level ${user.level}",
                              style: const TextStyle(color: Colors.white54, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      // MMR
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.withOpacity(0.5))
                        ),
                        child: Text(
                          "${user.mmr}",
                          style: GoogleFonts.orbitron(color: Colors.amber, fontWeight: FontWeight.bold),
                        ),
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