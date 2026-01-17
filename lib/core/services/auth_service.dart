import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get currentUid => _auth.currentUser?.uid;

  // --- FUNGSI DAFTAR (SIGN UP) ---
  Future<User?> signUp(String email, String password, String username) async {
    try {
      // 1. Buat akun di Firebase Authentication (Tunggu ini sampai selesai)
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;

      if (user != null) {
        // 2. Siapkan data profil
        UserModel newUser = UserModel(
          uid: user.uid,
          username: username,
          email: email,
          lastLogin: DateTime.now(),
          gold: 500,
          level: 1,
        );

        // 3. Simpan ke Firestore (FIRE AND FORGET)
        // PERUBAHAN UTAMA: Kita HAPUS 'await'.
        // Aplikasi akan langsung lanjut ke 'return user' tanpa menunggu database selesai.
        // Data akan dikirim di background.
        _db.collection('users').doc(user.uid).set(newUser.toMap())
           .catchError((e) {
             debugPrint("Gagal update data profil di background: $e");
           });
      }
      
      // Langsung kembalikan user agar MainScreen terbuka instan
      return user; 
      
    } catch (e) {
      debugPrint("Error saat pendaftaran: $e");
      return null;
    }
  }

  // --- FUNGSI LOGIN ---
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      
      // Update last login juga pakai Fire and Forget
      if (result.user != null) {
        _db.collection('users').doc(result.user!.uid).update({
          'last_login': FieldValue.serverTimestamp(),
        }).catchError((e) => debugPrint("Gagal update last_login: $e"));
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