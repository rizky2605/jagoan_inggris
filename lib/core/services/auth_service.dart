import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Mendapatkan ID user yang sedang login
  String? get currentUid => _auth.currentUser?.uid;

  // --- FUNGSI DAFTAR (SIGN UP) ---
  Future<User?> signUp(String email, String password, String username) async {
    try {
      // 1. Buat akun di Firebase Authentication
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;

      if (user != null) {
        // 2. Jika sukses, buat profil awal di Firestore menggunakan UserModel
        UserModel newUser = UserModel(
          uid: user.uid,
          username: username,
          email: email,
          // Data default lainnya sudah diatur di constructor UserModel
        );

        await _db.collection('users').doc(user.uid).set(newUser.toMap());
      }
      return user;
    } catch (e) {
      print("Error saat pendaftaran: $e");
      return null;
    }
  }

  // --- FUNGSI LOGIN ---
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } catch (e) {
      print("Error saat login: $e");
      return null;
    }
  }

  // --- FUNGSI LOGOUT ---
  Future<void> signOut() async {
    await _auth.signOut();
  }
}