import 'package:flutter/material.dart';

import '../../models/item_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class ClaimScreen extends StatefulWidget {
  final ItemModel item;

  const ClaimScreen({super.key, required this.item});

  @override
  State<ClaimScreen> createState() => _ClaimScreenState();
}

class _ClaimScreenState extends State<ClaimScreen> {
  final answerController = TextEditingController();

  final AuthService authService = AuthService();

  final FirestoreService firestoreService = FirestoreService();

  bool isLoading = false;

  Future<void> submitClaim() async {
    if (answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jawaban verifikasi wajib diisi.')),
      );

      return;
    }

    final user = authService.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await firestoreService.createClaim(
        itemId: widget.item.id,
        userId: user.uid,
        answer: answerController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Klaim berhasil dikirim.')));

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengirim klaim: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
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
            Text(
              widget.item.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            const Text(
              'Pertanyaan Verifikasi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              'Jelaskan ciri-ciri atau informasi khusus yang dapat membuktikan bahwa barang tersebut milik Anda.',
            ),

            const SizedBox(height: 16),

            TextField(
              controller: answerController,
              maxLines: 7,
              decoration: const InputDecoration(
                hintText:
                    'Contoh: terdapat stiker tertentu, isi tas, ciri khusus, dan sebagainya.',
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : submitClaim,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('KIRIM KLAIM'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
