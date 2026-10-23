import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/claim_model.dart';
import '../../models/item_model.dart';
import '../../services/firestore_service.dart';
import '../detail/item_detail_screen.dart';

class MyClaimScreen extends StatelessWidget {
  const MyClaimScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Silakan login terlebih dahulu.')),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Klaim Saya'),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: AppColors.primaryContainer,
            labelColor: AppColors.primaryContainer,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Klaim Temuan'),
              Tab(text: 'Hilang Ditemukan'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ClaimsList(userId: user.uid), // Tab 1: Menampilkan klaim penemu
            _ResolvedLostItemsList(
              userId: user.uid,
            ), // Tab 2: Menampilkan laporan hilang milik sendiri yang sudah kembali
          ],
        ),
      ),
    );
  }
}

// ==========================================
// TAB 1: DAFTAR KLAIM BARANG TEMUAN
// ==========================================
class _ClaimsList extends StatelessWidget {
  final String userId;
  const _ClaimsList({required this.userId});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return StreamBuilder<List<ClaimModel>>(
      stream: firestoreService.getMyClaims(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Gagal memuat klaim:\n${snapshot.error}'));
        }

        final List<ClaimModel> claims = snapshot.data ?? [];

        if (claims.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 70, color: Colors.grey),
                SizedBox(height: 15),
                Text(
                  'Belum ada klaim',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  'Barang yang berhasil kamu temukan akan muncul di sini.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: claims.length,
          itemBuilder: (context, index) {
            final ClaimModel claim = claims[index];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('items')
                  .doc(claim.itemId)
                  .get(),
              builder: (context, itemSnapshot) {
                String itemTitle = 'Memuat...';
                if (itemSnapshot.connectionState == ConnectionState.done) {
                  if (itemSnapshot.hasData && itemSnapshot.data!.exists) {
                    final itemData =
                        itemSnapshot.data!.data() as Map<String, dynamic>;
                    itemTitle = itemData['title'] ?? 'Barang Tanpa Judul';
                  } else {
                    itemTitle = 'Barang tidak ditemukan / dihapus';
                  }
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(
                        claim.status,
                      ).withValues(alpha: 0.2),
                      child: Icon(
                        _getStatusIcon(claim.status),
                        color: _getStatusColor(claim.status),
                      ),
                    ),
                    title: Text(
                      itemTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        'Status: ${claim.status}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    trailing: _StatusBadge(status: claim.status),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'APPROVED':
        return Icons.check;
      case 'REJECTED':
        return Icons.close;
      default:
        return Icons.hourglass_empty;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}

// ==========================================
// TAB 2: DAFTAR BARANG HILANG MILIK SENDIRI YANG SUDAH DITEMUKAN
// ==========================================
class _ResolvedLostItemsList extends StatelessWidget {
  final String userId;
  const _ResolvedLostItemsList({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('items')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Gagal memuat data:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        final List<ItemModel> resolvedItems = docs
            .map((doc) => ItemModel.fromFirestore(doc))
            .where((item) => item.isLost && item.isReceived)
            .toList();

        if (resolvedItems.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 70, color: Colors.grey),
                SizedBox(height: 15),
                Text(
                  'Belum ada barang ditemukan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  'Laporan kehilanganmu yang berhasil\nditemukan akan muncul di sini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: resolvedItems.length,
          itemBuilder: (context, index) {
            final item = resolvedItems[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.green.shade400, width: 1.5),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green.shade700,
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'Kategori: ${item.category}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ItemDetailScreen(item: item),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(60, 30),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      child: const Text(
                        'Lihat',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified, color: Colors.green, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Barang ini telah berhasil dikembalikan ke kamu',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ==========================================
// WIDGET BADGE STATUS
// ==========================================
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'APPROVED':
        color = Colors.green;
        break;
      case 'REJECTED':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
