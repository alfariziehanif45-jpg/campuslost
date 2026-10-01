import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';

class ReportScreen extends StatefulWidget {
  final String type;

  const ReportScreen({super.key, required this.type});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final FirestoreService firestoreService = FirestoreService();

  final StorageService storageService = StorageService();

  final ImagePicker imagePicker = ImagePicker();

  final TextEditingController titleController = TextEditingController();

  final TextEditingController colorController = TextEditingController();

  final TextEditingController locationController = TextEditingController();

  final TextEditingController descriptionController = TextEditingController();

  final List<String> categories = [
    'Elektronik',
    'Dompet',
    'Kunci',
    'Dokumen',
    'Tas',
    'Pakaian',
    'Aksesoris',
    'Lainnya',
  ];

  String? selectedCategory;

  File? selectedImage;

  bool isLoading = false;

  // ============================================================
  // PILIH GAMBAR
  // ============================================================

  Future<void> pickImage() async {
    try {
      final XFile? image = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) {
        return;
      }

      setState(() {
        selectedImage = File(image.path);
      });
    } catch (e) {
      showMessage('Gagal memilih gambar: $e');
    }
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<void> submit() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage('Silakan login terlebih dahulu.');
      return;
    }

    if (titleController.text.trim().isEmpty) {
      showMessage('Nama barang wajib diisi.');
      return;
    }

    if (selectedCategory == null) {
      showMessage('Kategori barang wajib dipilih.');
      return;
    }

    if (colorController.text.trim().isEmpty) {
      showMessage('Warna barang wajib diisi.');
      return;
    }

    if (locationController.text.trim().isEmpty) {
      showMessage('Lokasi wajib diisi.');
      return;
    }

    if (descriptionController.text.trim().isEmpty) {
      showMessage('Deskripsi wajib diisi.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String imageUrl = '';

      // Upload gambar jika user memilih gambar
      if (selectedImage != null) {
        imageUrl = await storageService.uploadItemImage(
          selectedImage!,
          user.uid,
        );
      }

      // Simpan data barang ke Firestore
      await firestoreService.createItem(
        title: titleController.text.trim(),
        type: widget.type,
        category: selectedCategory!,
        color: colorController.text.trim(),
        description: descriptionController.text.trim(),
        location: locationController.text.trim(),
        userId: user.uid,
        imageUrl: imageUrl,
      );

      if (!mounted) return;

      showMessage(
        widget.type == 'LOST'
            ? 'Laporan barang hilang berhasil dibuat.'
            : 'Laporan barang ditemukan berhasil dibuat.',
        success: true,
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      showMessage('Gagal menyimpan laporan: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void showMessage(String message, {bool success = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    titleController.dispose();
    colorController.dispose();
    locationController.dispose();
    descriptionController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool isLost = widget.type == 'LOST';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isLost ? 'Laporkan Barang Hilang' : 'Laporkan Barang Ditemukan',
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------
            // JUDUL
            // --------------------------------------------------
            Text(
              isLost ? 'Laporan Barang Hilang' : 'Laporan Barang Ditemukan',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              isLost
                  ? 'Masukkan informasi barang yang hilang.'
                  : 'Masukkan informasi barang yang kamu temukan.',
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 25),

            // --------------------------------------------------
            // GAMBAR
            // --------------------------------------------------
            GestureDetector(
              onTap: pickImage,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: selectedImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_a_photo_outlined, size: 50),
                          SizedBox(height: 10),
                          Text('Tambahkan Foto Barang'),
                          SizedBox(height: 5),
                          Text(
                            'Ketuk untuk memilih foto',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          selectedImage!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 25),

            // --------------------------------------------------
            // NAMA BARANG
            // --------------------------------------------------
            TextField(
              controller: titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nama Barang',
                hintText: 'Contoh: Dompet kulit hitam',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // KATEGORI
            // --------------------------------------------------
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // WARNA
            // --------------------------------------------------
            TextField(
              controller: colorController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Warna',
                hintText: 'Contoh: Hitam',
                prefixIcon: Icon(Icons.palette_outlined),
              ),
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // LOKASI
            // --------------------------------------------------
            TextField(
              controller: locationController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Lokasi',
                hintText: 'Contoh: Gedung A lantai 2',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // DESKRIPSI
            // --------------------------------------------------
            TextField(
              controller: descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                hintText: 'Jelaskan ciri-ciri barang secara lengkap...',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.description_outlined),
              ),
            ),

            const SizedBox(height: 25),

            // --------------------------------------------------
            // BUTTON SUBMIT
            // --------------------------------------------------
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : submit,
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
                  isLoading ? 'MENYIMPAN...' : 'KIRIM LAPORAN',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              'Pastikan informasi barang yang kamu masukkan sudah benar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
