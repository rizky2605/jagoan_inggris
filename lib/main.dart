import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'features/auth/auth_screen.dart';
import 'core/app_theme.dart';
import 'features/home/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const JagoanInggrisApp());
}

class JagoanInggrisApp extends StatelessWidget {
  const JagoanInggrisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jagoan Inggris',
      theme: appTheme, // Tema Neon yang kita buat sebelumnya
      debugShowCheckedModeBanner: false,
      // Menggunakan StreamBuilder untuk mengecek status login secara real-time
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Jika sudah ada data user (sudah login)
          if (snapshot.hasData) {
            // JIKA SUDAH LOGIN -> MASUK KE MAIN SCREEN
            return const MainScreen(); 
          }
          return const AuthScreen();
        },
      ),
    );
  }
}