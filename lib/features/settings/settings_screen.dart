import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/audio_manager.dart'; // [IMPORT INI]
import '../auth/auth_screen.dart';
import '../profile/profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Ambil instance AudioManager
  final AudioManager _audioManager = AudioManager();

  // State Toggle
  late bool _isMusicOn;
  late bool _isSfxOn;
  bool _isNotifOn = true;

  final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  void initState() {
    super.initState();
    // [PENTING] Ambil status terakhir dari AudioManager saat layar dibuka
    _isMusicOn = _audioManager.isMusicOn;
    _isSfxOn = _audioManager.isSfxOn;
  }

  // --- LOGIKA HAPUS AKUN (DANGER ZONE) ---
  Future<void> _deleteAccount() async {
     // ... (Kode delete account Anda tetap sama, tidak perlu diubah) ...
     // Salin saja logika _deleteAccount Anda sebelumnya ke sini
      bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A0045),
        title: const Text("Hapus Akun?", style: TextStyle(color: Colors.redAccent)),
        content: const Text(
          "Tindakan ini PERMANEN. Semua progress, level, dan item akan hilang selamanya.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus Permanen", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();
        await FirebaseAuth.instance.currentUser?.delete();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen()), 
          (route) => false,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
      }
    }
  }

  // --- LOGIKA LOGOUT ---
  void _handleLogout() async {
    // [OPSIONAL] Matikan musik saat logout jika diinginkan
    // await _audioManager.stopBgm(); 
    
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AuthScreen()), 
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0025),
      appBar: AppBar(
        title: Text("PENGATURAN", style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0025), Color(0xFF1E1E2C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // SECTION 1: UMUM
            _buildSectionHeader("UMUM"),
            
            // [UPDATE] Menggunakan logika AudioManager
            _buildSwitchTile(
              "Musik Latar", 
              Icons.music_note, 
              _isMusicOn, 
              (val) {
                setState(() => _isMusicOn = val);
                _audioManager.toggleMusic(val); // Panggil Manager
                if(val) _audioManager.playClick(); // Efek suara klik
              }
            ),

            _buildSwitchTile(
              "Efek Suara (SFX)", 
              Icons.volume_up, 
              _isSfxOn, 
              (val) {
                setState(() => _isSfxOn = val);
                _audioManager.toggleSfx(val); // Panggil Manager
                if(val) _audioManager.playClick(); // Test bunyi
              }
            ),

            _buildSwitchTile("Notifikasi Harian", Icons.notifications_active, _isNotifOn, (val) {
              setState(() => _isNotifOn = val);
              _audioManager.playClick();
            }),

            const SizedBox(height: 30),

            // SECTION 2: AKUN
            _buildSectionHeader("AKUN"),
            _buildActionTile("Edit Profil", Icons.edit, Colors.blueAccent, () {
              _audioManager.playClick();
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
            }),
            _buildActionTile("Tentang Aplikasi", Icons.info_outline, Colors.white70, () {
              _audioManager.playClick();
              _showAboutDialog();
            }),
            
            const Divider(color: Colors.white24, height: 40),

            // SECTION 3: ZONA BAHAYA
            _buildActionTile("Logout", Icons.logout, Colors.orangeAccent, _handleLogout),
            _buildActionTile("Hapus Akun", Icons.delete_forever, Colors.redAccent, _deleteAccount),
            
            const SizedBox(height: 20),
            Center(
              child: Text("Versi 1.0.0 Beta", style: GoogleFonts.poppins(color: Colors.white24, fontSize: 10)),
            ),
          ],
        ),
      ),
    );
  }

  // ... Widget Helpers (sama seperti kode Anda, tidak perlu diubah) ...
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.orbitron(color: Colors.purpleAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildSwitchTile(String title, IconData icon, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: SwitchListTile(
        activeColor: Colors.cyanAccent,
        inactiveTrackColor: Colors.black26,
        title: Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
        secondary: Icon(icon, color: value ? Colors.cyanAccent : Colors.grey),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text("Tentang Jagoan Inggris", style: TextStyle(color: Colors.cyanAccent)),
        content: const Text("Aplikasi belajar bahasa Inggris dengan konsep gamifikasi RPG.\n\nDeveloped by: Rizky", style: TextStyle(color: Colors.white70)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tutup"))],
      ),
    );
  }
}