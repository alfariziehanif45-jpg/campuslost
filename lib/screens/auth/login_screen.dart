import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../home/home_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  // ==========================================
  // LOGIN
  // ==========================================

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      showMessage('Email dan password wajib diisi!');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // 1. LOGIN FIREBASE AUTHENTICATION

      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception('Pengguna tidak ditemukan.');
      }

      // 2. AMBIL DATA USER DARI FIRESTORE

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        await FirebaseAuth.instance.signOut();

        throw Exception('Data akun tidak ditemukan di Firestore.');
      }

      final data = userDoc.data()!;

      // 3. AMBIL ROLE USER

      final String role = (data['role'] ?? '').toString().trim().toLowerCase();

      // 4. CEK MOUNTED

      if (!mounted) return;

      // 5. JIKA ADMIN

      if (role == 'admin') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          (route) => false,
        );
      }
      // 6. JIKA MAHASISWA
      else if (role == 'mahasiswa') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
      // 7. JIKA ROLE TIDAK DIKENALI
      else {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        showMessage('Role akun tidak dikenali: $role');
      }
    }
    // ==========================================
    // FIREBASE AUTH ERROR
    // ==========================================
    on FirebaseAuthException catch (e) {
      String message = 'Login gagal.';

      if (e.code == 'user-not-found') {
        message = 'Email belum terdaftar.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Email atau password salah.';
      } else if (e.code == 'invalid-email') {
        message = 'Format email tidak valid.';
      } else if (e.code == 'user-disabled') {
        message = 'Akun telah dinonaktifkan.';
      } else if (e.code == 'network-request-failed') {
        message = 'Periksa koneksi internet Anda.';
      }

      showMessage(message);
    }
    // ==========================================
    // OTHER ERROR
    // ==========================================
    catch (e) {
      showMessage('Terjadi kesalahan: $e');
    }
    // ==========================================
    // LOADING SELESAI
    // ==========================================
    finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ==========================================
  // SNACKBAR
  // ==========================================

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ==========================================
  // DISPOSE
  // ==========================================

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ==========================================
  // BUILD UI
  // ==========================================

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF4358B8);

    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),

            child: Column(
              children: [
                const Icon(Icons.find_in_page, size: 110, color: primaryColor),

                const SizedBox(height: 20),

                const Text(
                  'CampusLost',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Temukan kembali barangmu di lingkungan kampus',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),

                const SizedBox(height: 50),

                // EMAIL
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isLoading,

                  decoration: InputDecoration(
                    labelText: 'Email',

                    prefixIcon: const Icon(Icons.email_outlined),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // PASSWORD
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  enabled: !isLoading,

                  decoration: InputDecoration(
                    labelText: 'Password',

                    prefixIcon: const Icon(Icons.lock_outline),

                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),

                      onPressed: isLoading
                          ? null
                          : () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // BUTTON LOGIN
                SizedBox(
                  width: double.infinity,
                  height: 56,

                  child: ElevatedButton(
                    onPressed: isLoading ? null : login,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),

                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'LOGIN',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // REGISTER
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    const Text('Belum punya akun?'),

                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },

                      child: const Text(
                        'Daftar',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
