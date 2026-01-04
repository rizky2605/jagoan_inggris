import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final ThemeData appTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: const Color(0xFFBD00FF), // Warna Pink Neon dari Dashboard [cite: 111]
  scaffoldBackgroundColor: const Color(0xFF0F0025), // Background Ungu Gelap [cite: 87]
  
  // Menggunakan Google Fonts agar terlihat profesional
  textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
  
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFBD00FF),
    secondary: Color(0xFF00E5FF), // Warna Cyan Neon untuk tombol [cite: 111]
  ),
);