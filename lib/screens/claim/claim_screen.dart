import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/item_model.dart';
import '../../services/firestore_service.dart';

class ClaimScreen extends StatefulWidget {
  final ItemModel item;

  const ClaimScreen({super.key, required this.item});

  @override
  State<ClaimScreen> createState() => _ClaimScreenState();
}

class _ClaimScreenState extends State<ClaimScreen> {
  final answerController = TextEditingController();
  final FirestoreService firestoreService = FirestoreService();
  bool isLoading = false;

  Future<void> submitClaim() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Silakan login terlebih dahulu.');
      return;
    }

    final answer = answerController.text.trim();

    if (answer.isEmpty) {
      _showMessage('Jawaban verifikasi wajib diisi.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final alreadyClaimed = await firestoreService.hasExistingClaim(
        itemId: widget.item.id,
        userId: user.uid,
      );

      if (alreadyClaimed) {
        _showMessage('Kamu sudah mengajukan klaim untuk barang ini.');
        return;
      }

      await firestoreService.createClaim(
        itemId: widget.item.id,
        userId: user.uid,
        answer: answer,
      );

      if (!mounted) return;

      // ✅ Tampilkan Dialog Sukses
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 60),
            title: const Text('Klaim Terkirim!', textAlign: TextAlign.center),
            content: const Text(
              'Klaim kamu sedang ditinjau oleh penemu barang. '
              'Jika disetujui, barang akan ditandai sebagai "Berhasil Diklaim oleh Pemilik".',
              textAlign: TextAlign.center,
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Tutup Dialog
                    Navigator.pop(context); // Kembali ke halaman sebelumnya
                  },
                  child: const Text('OKE, MENGERTI'),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      _showMessage('Gagal mengirim klaim: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan Klaim')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Klaim Barang',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // ✅ Card Info Barang yang akan diklaim
            Card(
              elevation: 0,
              color: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      color: Colors.indigo,
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Barang yang diklaim:',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            widget.item.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Jelaskan ciri-ciri khusus yang dapat '
                'membuktikan bahwa barang tersebut adalah '
                'milik Anda.',
                style: TextStyle(fontSize: 14),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: answerController,
              maxLines: 7,
              decoration: const InputDecoration(
                labelText: 'Jawaban Verifikasi',
                hintText:
                    'Contoh: ciri khusus barang, isi tas, '
                    'nomor seri, atau informasi lainnya.',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.verified_user_outlined),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : submitClaim,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  isLoading ? 'MENGIRIM...' : 'KIRIM KLAIM',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
