import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Layar admin untuk memverifikasi klaim barang (hilang/temuan).
/// Admin dapat melihat bukti pengklaim + detail barang + data user,
/// lalu menyetujui (APPROVED) atau menolak (REJECTED).
class AdminClaimsScreen extends StatefulWidget {
  const AdminClaimsScreen({super.key});

  @override
  State<AdminClaimsScreen> createState() => _AdminClaimsScreenState();
}

class _AdminClaimsScreenState extends State<AdminClaimsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('Verifikasi Klaim Barang'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF26345F),
        elevation: 0,
        bottom: TabBar(
          controller: _tabs,
          labelColor: const Color(0xFF4358B8),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF4358B8),
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          // ⚠️ Sesuaikan nilai status di bawah dengan yang dipakai di DB Anda.
          // Kalau di DB Anda lowercase (pending/approved/rejected), ganti ke lowercase.
          _ClaimList(status: 'PENDING'),
          _ClaimList(status: 'APPROVED'),
          _ClaimList(status: 'REJECTED'),
        ],
      ),
    );
  }
}

class _ClaimList extends StatefulWidget {
  final String status;
  const _ClaimList({required this.status});

  @override
  State<_ClaimList> createState() => _ClaimListState();
}

class _ClaimListState extends State<_ClaimList> {
  final _cache = <String, Future<Map<String, dynamic>?>>{};

  Future<Map<String, dynamic>?> _fetchDoc(String collection, String id) {
    if (id.isEmpty) return Future.value(null);
    return _cache.putIfAbsent('$collection/$id', () async {
      final doc = await FirebaseFirestore.instance
          .collection(collection)
          .doc(id)
          .get();
      return doc.data();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('claims')
          .where('status', isEqualTo: widget.status)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Error: ${snapshot.error}\n\n'
                'Jika ini error composite index Firestore, buka link di log untuk membuatnya.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inbox_outlined, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Tidak ada klaim ${widget.status.toLowerCase()}.',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            final itemId = (data['itemId'] ?? '').toString();
            final userId = (data['userId'] ?? '').toString();

            // ⚠️ Kalau itemId Anda mengarah ke 'lost_reports' bukan 'found_items',
            // ubah collection di bawah.
            return _ClaimCard(
              data: data,
              itemFuture: _fetchDoc('found_items', itemId),
              userFuture: _fetchDoc('users', userId),
              onApprove: widget.status == 'PENDING'
                  ? () => _handleUpdate(doc.id, 'APPROVED', data)
                  : null,
              onReject: widget.status == 'PENDING'
                  ? () => _handleUpdate(doc.id, 'REJECTED', data)
                  : null,
            );
          },
        );
      },
    );
  }

  Future<void> _handleUpdate(
    String claimId,
    String newStatus,
    Map<String, dynamic> data,
  ) async {
    final admin = FirebaseAuth.instance.currentUser;
    if (admin == null) return;

    final isApprove = newStatus == 'APPROVED';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isApprove ? 'Setujui Klaim?' : 'Tolak Klaim?'),
        content: Text(
          isApprove
              ? 'Klaim akan disetujui dan pengguna bisa melihat barang ini di menu "Barang Disetujui".'
              : 'Klaim akan ditolak. Pengguna tidak bisa melihat barang ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: isApprove ? const Color(0xFF4358B8) : Colors.red,
            ),
            child: Text(isApprove ? 'Setujui' : 'Tolak'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      // 1) Update status klaim
      await FirebaseFirestore.instance
          .collection('claims')
          .doc(claimId)
          .update({
            'status': newStatus,
            'verifiedAt': FieldValue.serverTimestamp(),
            'verifiedBy': admin.uid,
          });

      // 2) Kalau disetujui, tandai barang temuan sebagai CLAIMED (opsional)
      if (isApprove) {
        final itemId = (data['itemId'] ?? '').toString();
        if (itemId.isNotEmpty) {
          try {
            await FirebaseFirestore.instance
                .collection('found_items')
                .doc(itemId)
                .update({'status': 'CLAIMED'});
          } catch (_) {
            // Abaikan jika field/collection tidak ada
          }
        }
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(isApprove ? '✅ Klaim disetujui.' : '❌ Klaim ditolak.'),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }
}

class _ClaimCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Future<Map<String, dynamic>?> itemFuture;
  final Future<Map<String, dynamic>?> userFuture;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _ClaimCard({
    required this.data,
    required this.itemFuture,
    required this.userFuture,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final itemName = (data['itemName'] ?? 'Barang ID: ${data['itemId'] ?? '-'}')
        .toString();
    final answer = (data['answer'] ?? 'Tidak ada bukti').toString();
    final status = (data['status'] ?? '-').toString().toUpperCase();

    String dateStr = '-';
    if (data['createdAt'] is Timestamp) {
      final dt = (data['createdAt'] as Timestamp).toDate();
      dateStr = DateFormat('dd MMM yyyy • HH:mm').format(dt);
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE7E9F4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    itemName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  dateStr,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Bukti / jawaban dari pengklaim
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF4358B8).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BUKTI / JAWABAN PENGKLAIM',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4358B8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(answer),
                ],
              ),
            ),
            const Divider(height: 20),

            // Detail barang temuan
            FutureBuilder<Map<String, dynamic>?>(
              future: itemFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 40,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                final item = snapshot.data;
                if (item == null) {
                  return const Text(
                    'Data barang tidak ditemukan',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  );
                }
                return _InfoRow(
                  icon: Icons.inventory_2_outlined,
                  label: 'BARANG TEMUAN',
                  value: (item['title'] ?? item['name'] ?? '-').toString(),
                  sub:
                      (item['location'] ??
                              item['locationName'] ??
                              item['description'] ??
                              '')
                          .toString(),
                );
              },
            ),
            const SizedBox(height: 8),

            // Detail pengklaim
            FutureBuilder<Map<String, dynamic>?>(
              future: userFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 40,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                final user = snapshot.data;
                if (user == null) {
                  return const Text(
                    'Data pengguna tidak ditemukan',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  );
                }
                return _InfoRow(
                  icon: Icons.person_outline,
                  label: 'PENGKLAIM',
                  value: (user['name'] ?? user['nama'] ?? '-').toString(),
                  sub: (user['email'] ?? user['phone'] ?? '').toString(),
                );
              },
            ),

            // Tombol aksi (hanya muncul di tab Pending)
            if (onApprove != null && onReject != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Tolak'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Setujui'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4358B8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? sub;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (sub != null && sub!.isNotEmpty)
                Text(
                  sub!,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == 'APPROVED'
        ? Colors.green
        : status == 'REJECTED'
        ? Colors.red
        : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
