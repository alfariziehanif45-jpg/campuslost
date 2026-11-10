import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/ai_match_model.dart';
import '../../services/matching_service.dart';

class AdminMatchingScreen extends StatefulWidget {
  const AdminMatchingScreen({super.key});

  @override
  State<AdminMatchingScreen> createState() => _AdminMatchingScreenState();
}

class _AdminMatchingScreenState extends State<AdminMatchingScreen>
    with SingleTickerProviderStateMixin {
  final _service = MatchingService();
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

  Future<void> _runMatching() async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Menjalankan pencocokan AI...')),
    );
    try {
      final count = await _service.generateAll();
      messenger.showSnackBar(
        SnackBar(content: Text('Selesai. $count kandidat match dibuat.')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('Pencocokan Barang'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF26345F),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Jalankan pencocokan',
            onPressed: _runMatching,
            icon: const Icon(Icons.auto_awesome),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: const Color(0xFF4358B8),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF4358B8),
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Verified'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _MatchList(status: 'pending'),
          _MatchList(status: 'verified'),
          _MatchList(status: 'rejected'),
        ],
      ),
    );
  }
}

class _MatchList extends StatefulWidget {
  final String status;
  const _MatchList({required this.status});

  @override
  State<_MatchList> createState() => _MatchListState();
}

class _MatchListState extends State<_MatchList> {
  final _service = MatchingService();
  final _cache = <String, Future<Map<String, dynamic>?>>{};

  Future<Map<String, dynamic>?> _fetch(String collection, String id) {
    return _cache.putIfAbsent(
      '$collection/$id',
      () async {
        final doc =
            await FirebaseFirestore.instance.collection(collection).doc(id).get();
        return doc.data();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AiMatchModel>>(
      stream: _service.watchMatches(status: widget.status),
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
        final matches = snapshot.data ?? const [];
        if (matches.isEmpty) {
          return const Center(child: Text('Tidak ada match.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: matches.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final m = matches[i];
            return _MatchCard(
              match: m,
              lostFuture: _fetch('lost_reports', m.lostItemId),
              foundFuture: _fetch('found_items', m.foundItemId),
              onVerify:
                  widget.status == 'pending' ? () => _verify(m) : null,
              onReject:
                  widget.status == 'pending' ? () => _reject(m) : null,
            );
          },
        );
      },
    );
  }

  Future<void> _verify(AiMatchModel m) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _service.verifyMatch(m, adminUid: uid);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Match diverifikasi.')),
    );
  }

  Future<void> _reject(AiMatchModel m) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _service.rejectMatch(m, adminUid: uid);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Match ditolak.')),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final AiMatchModel match;
  final Future<Map<String, dynamic>?> lostFuture;
  final Future<Map<String, dynamic>?> foundFuture;
  final VoidCallback? onVerify;
  final VoidCallback? onReject;

  const _MatchCard({
    required this.match,
    required this.lostFuture,
    required this.foundFuture,
    this.onVerify,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4358B8).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Skor ${match.similarityScorePercent.round()}%',
                    style: const TextStyle(
                      color: Color(0xFF4358B8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  match.status.toUpperCase(),
                  style: TextStyle(
                    color: match.status == 'verified'
                        ? Colors.green
                        : match.status == 'rejected'
                            ? Colors.red
                            : Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _scoreChip('Kategori', match.categoryScore, 30),
                _scoreChip('Warna', match.colorScore, 20),
                _scoreChip('Lokasi', match.locationScore, 30),
                _scoreChip('Waktu', match.timeScore, 7),
              ],
            ),
            const Divider(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _ItemPreview(
                    label: 'HILANG',
                    color: Colors.red,
                    future: lostFuture,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ItemPreview(
                    label: 'TEMUAN',
                    color: Colors.green,
                    future: foundFuture,
                  ),
                ),
              ],
            ),
            if (onVerify != null && onReject != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Tolak'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: onVerify,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4358B8),
                      ),
                      child: const Text('Verifikasi'),
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

  Widget _scoreChip(String label, int value, int max) {
    return Chip(
      label: Text('$label $value/$max', style: const TextStyle(fontSize: 11)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _ItemPreview extends StatelessWidget {
  final String label;
  final Color color;
  final Future<Map<String, dynamic>?> future;

  const _ItemPreview({
    required this.label,
    required this.color,
    required this.future,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final data = snapshot.data;
        if (data == null) {
          return const Text(
            'Data tidak ditemukan',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          );
        }
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                (data['title'] ?? '-').toString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                (data['location'] ?? data['locationName'] ?? '-').toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }
}