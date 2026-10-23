import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth/login_screen.dart';
import 'package:campuslost/services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _creatingDoc = false;
  bool _createFailed = false;

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  /// Buat dokumen profil kalau belum ada
  Future<void> _createProfileDoc(User user) async {
    if (_creatingDoc) return;
    setState(() {
      _creatingDoc = true;
      _createFailed = false;
    });
    try {
      await UserService.ensureUserDocument(user);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _creatingDoc = false;
        _createFailed = true;
      });
      return;
    }
    if (mounted) setState(() => _creatingDoc = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnap) {
          if (authSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = authSnap.data;
          if (user == null) {
            return const Center(child: Text('Silakan login terlebih dahulu.'));
          }

          // ✅ Realtime: apapun yang tersimpan di Firestore langsung tampil
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: UserService.userDoc(user.uid).snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('Gagal memuat profil: ${snap.error}'),
                  ),
                );
              }

              final doc = snap.data;
              if (doc == null || !doc.exists) {
                // Dokumen belum ada → buat otomatis dari data Firebase Auth
                if (_createFailed) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Data profil belum tersedia.'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => _createProfileDoc(user),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }
                if (!_creatingDoc) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _createProfileDoc(user),
                  );
                }
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Menyiapkan data profil...'),
                    ],
                  ),
                );
              }

              final data = doc.data()!;

              return RefreshIndicator(
                onRefresh: () => UserService.ensureUserDocument(user),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: [
                    const SizedBox(height: 10),
                    const CircleAvatar(
                      radius: 50,
                      child: Icon(Icons.person, size: 50),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: Text(
                        data['name']?.toString() ?? 'Mahasiswa',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        data['email']?.toString() ?? '-',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 25),
                    _info(Icons.badge_outlined, 'NIM', data['nim']),
                    _info(
                      Icons.account_balance_outlined,
                      'Fakultas',
                      data['fakultas'] ?? data['faculty'],
                    ),
                    _info(
                      Icons.school_outlined,
                      'Program Studi',
                      data['prodi'],
                    ),
                    _info(
                      Icons.person_outline,
                      'Role',
                      data['role'] ?? 'mahasiswa',
                    ),
                    _info(
                      Icons.star_outline,
                      'Poin Reputasi',
                      data['reputation_score'],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () => logout(context),
                        icon: const Icon(Icons.logout),
                        label: const Text('LOGOUT'),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _info(IconData icon, String title, Object? value) {
    final v = value?.toString().trim() ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(v.isEmpty ? '-' : v),
      ),
    );
  }
}
