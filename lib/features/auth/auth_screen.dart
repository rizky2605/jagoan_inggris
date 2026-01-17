import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  // Kontroller untuk input teks
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  // [BARU] Controller untuk konfirmasi password
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  // State untuk logika UI
  bool _isLogin = true; // True = Mode Login, False = Mode Daftar
  bool _isLoading = false; // Untuk menampilkan loading spinner
  bool _isObscure = true; // Untuk menyembunyikan password utama
  // [BARU] State untuk menyembunyikan password konfirmasi
  bool _isConfirmObscure = true; 

  // Fungsi Utama Login/Daftar
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    String message = "";

    try {
      if (_isLogin) {
        // --- LOGIKA LOGIN ---
        final user = await _auth.signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        if (user != null) {
          message = "Selamat datang kembali!";
        } else {
          message = "Login gagal. Periksa email/password Anda.";
        }
      } else {
        // --- LOGIKA DAFTAR ---
        final user = await _auth.signUp(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _usernameController.text.trim(),
        );
        if (user != null) {
          message = "Akun berhasil dibuat! Selamat bergabung.";
        } else {
          message = "Pendaftaran gagal. Email mungkin sudah dipakai.";
        }
      }
    } catch (e) {
      message = "Terjadi kesalahan sistem.";
    }

    setState(() => _isLoading = false);

    // Tampilkan pesan (Snackbar)
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: message.contains("gagal") ? Colors.redAccent : Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mengambil tema warna dari app_theme.dart (Cyan & Purple)
    final primaryColor = Theme.of(context).primaryColor;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      // Background gradient agar terlihat seperti angkasa
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0025), Color(0xFF2A0045)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- 1. LOGO & JUDUL ---
                  const Icon(Icons.rocket_launch_rounded, size: 80, color: Colors.cyanAccent),
                  const SizedBox(height: 20),
                  Text(
                    "JAGOAN INGGRIS",
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      shadows: [
                        BoxShadow(color: primaryColor.withValues(alpha: 0.5), blurRadius: 20)
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isLogin ? "Lanjutkan Petualanganmu" : "Mulai Perjalanan Baru",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 40),

                  // --- 2. INPUT FORM (Glassmorphism Style) ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      children: [
                        // Input Username (Hanya muncul saat Daftar)
                        if (!_isLogin) ...[
                          _buildTextField(
                            controller: _usernameController,
                            icon: Icons.person_outline,
                            label: "Username",
                            validator: (val) => val!.isEmpty ? "Username wajib diisi" : null,
                          ),
                          const SizedBox(height: 15),
                        ],

                        // Input Email
                        _buildTextField(
                          controller: _emailController,
                          icon: Icons.email_outlined,
                          label: "Email",
                          validator: (val) => !val!.contains("@") ? "Email tidak valid" : null,
                        ),
                        const SizedBox(height: 15),

                        // Input Password
                        _buildTextField(
                          controller: _passwordController,
                          icon: Icons.lock_outline,
                          label: "Password",
                          isPassword: true,
                          isObscure: _isObscure,
                          onVisibilityToggle: () {
                            setState(() => _isObscure = !_isObscure);
                          },
                          validator: (val) => val!.length < 6 ? "Minimal 6 karakter" : null,
                        ),

                        // [BARU] Input Konfirmasi Password (Hanya muncul saat Daftar)
                        if (!_isLogin) ...[
                          const SizedBox(height: 15),
                          _buildTextField(
                            controller: _confirmPasswordController,
                            icon: Icons.lock_reset, // Ikon berbeda untuk pembeda visual
                            label: "Konfirmasi Password",
                            isPassword: true,
                            isObscure: _isConfirmObscure,
                            onVisibilityToggle: () {
                              setState(() => _isConfirmObscure = !_isConfirmObscure);
                            },
                            validator: (val) {
                              if (val!.isEmpty) return "Konfirmasi password wajib diisi";
                              if (val != _passwordController.text) return "Password tidak sama";
                              return null;
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- 3. TOMBOL AKSI ---
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.cyanAccent)
                      : SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: secondaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 10,
                              shadowColor: secondaryColor.withValues(alpha: 0.5),
                            ),
                            child: Text(
                              _isLogin ? "MASUK SEKARANG" : "BUAT AKUN",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                  
                  const SizedBox(height: 20),

                  // --- 4. TOGGLE LOGIN/DAFTAR ---
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin; // Switch mode
                        _formKey.currentState?.reset(); // Reset pesan error
                        
                        // Opsional: Bersihkan field password saat ganti mode agar bersih
                        _passwordController.clear();
                        _confirmPasswordController.clear();
                      });
                    },
                    child: RichText(
                      text: TextSpan(
                        text: _isLogin ? "Belum punya akun? " : "Sudah punya akun? ",
                        style: const TextStyle(color: Colors.white60),
                        children: [
                          TextSpan(
                            text: _isLogin ? "Daftar di sini" : "Login di sini",
                            style: TextStyle(
                              color: secondaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Widget Helper untuk Text Field agar rapi ---
  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    bool isPassword = false,
    bool isObscure = false,
    VoidCallback? onVisibilityToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white54),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.cyanAccent),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isObscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white54,
                ),
                onPressed: onVisibilityToggle,
              )
            : null,
      ),
    );
  }
}