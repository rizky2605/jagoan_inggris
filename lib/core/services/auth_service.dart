import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get currentUid => _auth.currentUser?.uid;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // --- FUNGSI DAFTAR (SIGN UP) ---
  Future<User?> signUp(String email, String password, String username) async {
    try {
      // 1. Buat akun di Firebase Authentication
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;

      if (user != null) {
        // 2. Siapkan data profil LENGKAP sesuai UserModel terbaru
        // Penting: Inisialisasi MMR dan Stats di sini agar tidak error null nanti
        UserModel newUser = UserModel(
          uid: user.uid,
          username: username,
          email: email,
          lastLogin: DateTime.now(),
          
          // Ekonomi & Level Awal
          gold: 500,
          level: 1,
          currentXp: 0,
          maxXp: 1000,
          
          // Statistik Matchmaking (WAJIB ADA)
          mmr: 1000,         // Modal awal MMR (biasanya 1000 atau 0)
          rankName: 'Bronze I',
          winCount: 0,
          lossCount: 0,
          
          // Statistik Harian
          dailyWordTarget: 10,
          streakCount: 0,
        );

        // 3. Simpan ke Firestore (Fire and Forget)
        // Kita tidak menggunakan 'await' agar UI langsung pindah (Cepat),
        // tapi data tetap dikirim di background.
        _db.collection('users').doc(user.uid).set(newUser.toMap())
            .catchError((e) {
              debugPrint("FATAL: Gagal membuat data user di Firestore: $e");
              // Opsional: Bisa tambahkan log ke Crashlytics di sini
            });
      }
      
      return user; 
      
    } catch (e) {
      debugPrint("Error saat pendaftaran: $e");
      // Tips: Anda bisa me-rethrow error ini jika ingin menampilkan snackbar di UI
      // throw e; 
      return null;
    }
  }

  // --- FUNGSI LOGIN ---
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      
      // Update last_login (Fire and Forget)
      if (result.user != null) {
        _db.collection('users').doc(result.user!.uid).update({
          'last_login': FieldValue.serverTimestamp(),
        }).catchError((e) {
            // Jika error (misal doc tidak ada), abaikan atau buat doc baru (self-healing)
            debugPrint("Warning: Gagal update last_login: $e");
        });
      }

      return result.user;
    } catch (e) {
      debugPrint("Error saat login: $e");
      return null;
    }
  }

  // --- FUNGSI LOGOUT ---
  Future<void> signOut() async {
    await _auth.signOut();
  }
}