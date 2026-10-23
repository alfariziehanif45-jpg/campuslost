import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../home/home_screen.dart';
import 'package:campuslost/services/user_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController();
  final nim = TextEditingController();
  final fakultas = TextEditingController(text: 'Fakultas Ilmu Komputer');
  final prodi = TextEditingController(text: 'Teknik Informatika');
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false, obscure = true;

  void msg(String s, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s), backgroundColor: isError ? Colors.red : null),
    );
  }

  Future<void> register() async {
    if ([
      name,
      nim,
      fakultas,
      prodi,
      email,
      password,
    ].any((c) => c.text.trim().isEmpty)) {
      msg('Semua data wajib diisi.', isError: true);
      return;
    }
    if (password.text.length < 6) {
      msg('Password minimal 6 karakter.', isError: true);
      return;
    }

    setState(() => loading = true);
    User? createdUser;

    try {
      // 1. Buat akun di Firebase Auth
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text,
      );
      createdUser = cred.user;
      final u = createdUser!;

      // 2. Set nama di Auth
      await u.updateDisplayName(name.text.trim());

      // 3. Simpan data lengkap ke Firestore (users/{uid})
      await UserService.saveUserData(u.uid, {
        'name': name.text.trim(),
        'full_name': name.text.trim(),
        'email': email.text.trim(),
        'email_campus': email.text.trim(),
        'nim': nim.text.trim(),
        'fakultas': fakultas.text.trim(),
        'faculty': fakultas.text.trim(),
        'prodi': prodi.text.trim(),
        'role': 'mahasiswa',
        'reputation_score': 100,
      });

      if (mounted) {
        msg('Registrasi berhasil!');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      msg(switch (e.code) {
        'email-already-in-use' => 'Email sudah digunakan.',
        'invalid-email' => 'Format email tidak valid.',
        'weak-password' => 'Password terlalu lemah.',
        _ => e.message ?? 'Registrasi gagal.',
      }, isError: true);
    } catch (e) {
      // Akun Auth SUDAH dibuat tapi simpan Firestore gagal (mis. offline).
      // Jangan stuck: user tetap masuk, data disinkronkan otomatis saat login/buka profil.
      if (createdUser != null) {
        msg('Akun berhasil dibuat, data profil akan disinkronkan otomatis.');
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      } else {
        msg(
          'Registrasi gagal. Periksa koneksi internet. Detail: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    for (final c in [name, nim, fakultas, prodi, email, password]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Daftar CampusLost')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.person_add_alt_1, size: 70),
          const SizedBox(height: 15),
          const Text(
            'Buat Akun CampusLost',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          field(name, 'Nama Lengkap', Icons.person_outline),
          field(
            nim,
            'NIM',
            Icons.badge_outlined,
            keyboard: TextInputType.number,
          ),
          field(fakultas, 'Fakultas', Icons.account_balance_outlined),
          field(prodi, 'Program Studi', Icons.school_outlined),
          field(
            email,
            'Email',
            Icons.email_outlined,
            keyboard: TextInputType.emailAddress,
          ),
          TextField(
            controller: password,
            obscureText: obscure,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () => setState(() => obscure = !obscure),
                icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: loading ? null : register,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text('DAFTAR'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget field(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType? keyboard,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextField(
      controller: c,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    ),
  );
}
