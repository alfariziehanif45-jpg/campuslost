import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../services/storage_service.dart';

import '../auth/login_screen.dart';

class ReportScreen extends StatefulWidget {
  final String type; // 'LOST' atau 'FOUND'

  const ReportScreen({super.key, required this.type});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final TextEditingController namaController = TextEditingController();
  final TextEditingController kategoriController = TextEditingController();
  final TextEditingController warnaController = TextEditingController();
  final TextEditingController lokasiController = TextEditingController();
  final TextEditingController deskripsiController = TextEditingController();

  Uint8List? imageBytes;
  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;

  @override
  void dispose() {
    namaController.dispose();
    kategoriController.dispose();
    warnaController.dispose();
    lokasiController.dispose();
    deskripsiController.dispose();
    super.dispose();
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pilih Sumber Foto',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: AppColors.primaryContainer),
                  title: const Text('Ambil dari Kamera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: AppColors.primaryContainer),
                  title: const Text('Pilih dari Galeri'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          imageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih gambar: $e')),
        );
      }
    }
  }

  Future<void> simpanLaporan() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Silakan Login Terlebih Dahulu'),
          content: const Text(
            'Anda perlu masuk ke akun terlebih dahulu sebelum dapat mempublikasikan laporan barang.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text('Login Sekarang', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    if (namaController.text.trim().isEmpty || lokasiController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi Nama Barang dan Lokasi!')),
      );
      return;
    }

    setState(() => isLoading = true);

    String imageUrl = '';
    String imageBase64 = '';

    try {
      if (imageBytes != null) {
        // 1. Coba upload ke Firebase Storage (mendukung foto resolusi penuh tanpa batas)
        try {
          imageUrl = await StorageService().uploadItemImageBytes(imageBytes!, user.uid);
        } catch (_) {
          // Jika Firebase Storage tidak tersedia, fallback ke penyimpanan Base64
        }

        // 2. Simpan sebagai Base64
        final encoded = base64Encode(imageBytes!);
        // Batas dokumen Firestore adalah 1.048.576 byte (~1MB)
        if (encoded.length < 980000) {
          imageBase64 = encoded;
        } else if (imageUrl.isEmpty) {
          imageBase64 = encoded;
        }
      }

      // Simpan data lengkap ke Firestore
      await FirebaseFirestore.instance.collection('items').add({
        'title': namaController.text.trim(),
        'category': kategoriController.text.trim().isNotEmpty
            ? kategoriController.text.trim()
            : 'Lainnya',
        'color': warnaController.text.trim(),
        'location': lokasiController.text.trim(),
        'location_name': lokasiController.text.trim(),
        'description': deskripsiController.text.trim(),
        'imageUrl': imageUrl,
        'imageData': imageBase64,
        'type': widget.type,
        'status_type': widget.type,
        'status': 'OPEN',
        'is_received_by_owner': false,
        'userId': user.uid,
        'user_id': user.uid,
        'date': Timestamp.now(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laporan berhasil disimpan!'),
            backgroundColor: AppColors.secondary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan laporan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLost = widget.type == 'LOST';
    final titleText = isLost ? 'Laporkan Barang Hilang' : 'Laporkan Barang Temuan';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(titleText),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview & Upload Foto
            const Text(
              'Foto Barang Bukti',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: imageBytes != null ? AppColors.primaryContainer : AppColors.borderCard,
                    width: imageBytes != null ? 2 : 1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(15, 23, 42, 0.04),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: imageBytes != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.memory(
                              imageBytes!,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit, color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'Ganti Foto',
                                    style: TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Icon(
                              Icons.add_a_photo,
                              size: 32,
                              color: AppColors.primaryContainer,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Ketuk untuk memilih foto (Resolusi Jernih & HD)',
                            style: TextStyle(
                              color: AppColors.primaryContainer,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Mendukung foto kamera & galeri ukuran berapa saja',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Form Fields
            _buildField(namaController, 'Nama Barang *', 'Contoh: Dompet Kulit Bifold Hitam, KTM'),
            const SizedBox(height: 14),
            _buildField(kategoriController, 'Kategori Barang', 'Contoh: Aksesoris, Elektronik, Dokumen'),
            const SizedBox(height: 14),
            _buildField(warnaController, 'Warna Barang', 'Contoh: Hitam, Biru Dongker'),
            const SizedBox(height: 14),
            _buildField(lokasiController, 'Lokasi Terakhir / Ditemukan *', 'Contoh: Gd. Fasilkom Lt. 2 (Lab Jaringan)'),
            const SizedBox(height: 14),
            _buildField(
              deskripsiController,
              'Deskripsi Detail',
              'Sebutkan ciri-ciri khusus, kondisi, atau detail lainnya...',
              maxLines: 3,
            ),
            const SizedBox(height: 28),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : simpanLaporan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLost ? AppColors.alertRed : AppColors.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'SIMPAN LAPORAN ${isLost ? "HILANG" : "TEMUAN"}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    String hint, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.outline),
          ),
        ),
      ],
    );
  }
}
