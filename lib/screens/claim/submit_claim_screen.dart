import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SubmitClaimScreen extends StatefulWidget {
  final String itemId;
  final String itemTitle;

  const SubmitClaimScreen({
    super.key,
    required this.itemId,
    required this.itemTitle,
  });

  @override
  State<SubmitClaimScreen> createState() => _SubmitClaimScreenState();
}

class _SubmitClaimScreenState extends State<SubmitClaimScreen> {
  final TextEditingController _proofController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitClaim() async {
    if (_proofController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bukti klaim tidak boleh kosong!')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Cek apakah sudah pernah klaim
      final existing = await FirebaseFirestore.instance
          .collection('claims')
          .where('itemId', isEqualTo: widget.itemId)
          .where('userId', isEqualTo: user.uid)
          .get();

      if (existing.docs.isNotEmpty) {
        throw 'Anda sudah mengajukan klaim untuk barang ini.';
      }

      // Simpan ke Firestore
      await FirebaseFirestore.instance.collection('claims').add({
        'itemId': widget.itemId,
        'userId': user.uid,
        'answer': _proofController.text.trim(),
        'status': 'PENDING',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Klaim berhasil diajukan! Menunggu verifikasi admin.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan Klaim')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Barang yang diklaim:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              widget.itemTitle,
              style: const TextStyle(fontSize: 18, color: Colors.blue),
            ),
            const SizedBox(height: 20),
            const Text(
              'Bukti Kepemilikan *',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Jelaskan ciri-ciri khusus barang (misal: goresan, isi dompet, atau kode unik) agar admin dapat memverifikasi.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _proofController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Tuliskan bukti kepemilikan Anda di sini...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitClaim,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Kirim Klaim',
                        style: TextStyle(
                          color: Colors.white,
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
