import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Belum login')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const CircleAvatar(
                radius: 50,
                child: Icon(Icons.person, size: 50),
              ),

              const SizedBox(height: 20),

              Center(
                child: Text(
                  data?['name'] ?? user.displayName ?? 'Mahasiswa',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              _ProfileItem(
                icon: Icons.badge,
                title: 'NIM',
                value: data?['nim'] ?? '-',
              ),

              _ProfileItem(
                icon: Icons.email,
                title: 'Email',
                value: data?['email'] ?? user.email ?? '-',
              ),

              _ProfileItem(
                icon: Icons.school,
                title: 'Fakultas',
                value: data?['fakultas'] ?? '-',
              ),

              _ProfileItem(
                icon: Icons.menu_book,
                title: 'Program Studi',
                value: data?['prodi'] ?? '-',
              ),

              _ProfileItem(
                icon: Icons.admin_panel_settings,
                title: 'Role',
                value: data?['role'] ?? 'mahasiswa',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ProfileItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}
