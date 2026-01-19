import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';

// [PENTING] Import MainScreen agar bisa pindah halaman setelah login/daftar
import '../home/main_screen.dart'; 

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  bool _isLogin = true; 
  bool _isLoading = false; 
  bool _isObscure = true; 
  bool _isConfirmObscure = true; 

  // --- FUNGSI UTAMA (DIPERBAIKI) ---
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    String message = "";
    bool success = false; // Flag untuk menandai keberhasilan

    try {
      if (_isLogin) {
        // --- LOGIKA LOGIN ---
        final user = await _auth.signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        if (user != null) {
          message = "Selamat datang kembali!";
          success = true; // Tandai sukses
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
          success = true; // Tandai sukses
        } else {
          message = "Pendaftaran gagal. Email mungkin sudah dipakai.";
        }
      }
    } catch (e) {
      message = "Terjadi kesalahan sistem: $e";
    }

    setState(() => _isLoading = false);

    // Tampilkan pesan
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? Colors.green : Colors.redAccent,
        ),
      );

      // [FIX UTAMA DISINI]
      // Jika login/daftar BERHASIL, pindah ke MainScreen
      if (success) {
        // Beri sedikit jeda agar user sempat membaca pesan sukses
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
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
                        BoxShadow(color: primaryColor.withOpacity(0.5), blurRadius: 20)
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isLogin ? "Lanjutkan Petualanganmu" : "Mulai Perjalanan Baru",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 40),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        if (!_isLogin) ...[
                          _buildTextField(
                            controller: _usernameController,
                            icon: Icons.person_outline,
                            label: "Username",
                            validator: (val) => val!.isEmpty ? "Username wajib diisi" : null,
                          ),
                          const SizedBox(height: 15),
                        ],

                        _buildTextField(
                          controller: _emailController,
                          icon: Icons.email_outlined,
                          label: "Email",
                          validator: (val) => !val!.contains("@") ? "Email tidak valid" : null,
                        ),
                        const SizedBox(height: 15),

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

                        if (!_isLogin) ...[
                          const SizedBox(height: 15),
                          _buildTextField(
                            controller: _confirmPasswordController,
                            icon: Icons.lock_reset,
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
                              shadowColor: secondaryColor.withOpacity(0.5),
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

                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin; 
                        _formKey.currentState?.reset();
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
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
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