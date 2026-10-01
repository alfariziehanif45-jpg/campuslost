import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<DocumentSnapshot<Map<String, dynamic>>?> getProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return null;
    }

    return FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  }

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
        future: getProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data();

          if (data == null) {
            return const Center(child: Text('Data profile tidak ditemukan.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.person, size: 50),
                ),

                const SizedBox(height: 14),

                Text(
                  data['name']?.toString() ?? 'Mahasiswa',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  data['email']?.toString() ?? '-',
                  style: const TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 25),

                _info(
                  Icons.badge_outlined,
                  'NIM',
                  data['nim']?.toString() ?? '-',
                ),

                _info(
                  Icons.account_balance_outlined,
                  'Fakultas',
                  data['fakultas']?.toString() ?? '-',
                ),

                _info(
                  Icons.school_outlined,
                  'Program Studi',
                  data['prodi']?.toString() ?? '-',
                ),

                _info(
                  Icons.person_outline,
                  'Role',
                  data['role']?.toString() ?? 'mahasiswa',
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
      ),
    );
  }

  Widget _info(IconData icon, String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}
