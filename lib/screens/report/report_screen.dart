import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Ganti Google Maps dengan Flutter Map (OpenStreetMap)
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// --- PERBAIKAN PATH IMPORT ---
import '../../core/constants/app_colors.dart';
import '../../services/storage_service.dart';
import '../auth/login_screen.dart';
import 'map_picker_screen.dart';

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

  double? latitude;
  double? longitude;

  @override
  void dispose() {
    namaController.dispose();
    kategoriController.dispose();
    warnaController.dispose();
    lokasiController.dispose();
    deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _pilihLokasiDiPeta() async {
    final result = await Navigator.push<MapLocationResult>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MapPickerScreen(initialLat: latitude, initialLng: longitude),
      ),
    );

    if (result != null) {
      setState(() {
        latitude = result.latitude;
        longitude = result.longitude;
        lokasiController.text = result.address;
      });
    }
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
        setState(() => imageBytes = bytes);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal gambar: $e')));
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> simpanLaporan() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Silakan Login'),
          content: const Text('Anda perlu masuk akun terlebih dahulu.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text('Login'),
            ),
          ],
        ),
      );
      return;
    }

    if (namaController.text.trim().isEmpty ||
        (lokasiController.text.trim().isEmpty && latitude == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama Barang dan Lokasi wajib diisi!')),
      );
      return;
    }

    setState(() => isLoading = true);
    String imageUrl = '';
    String imageBase64 = '';

    try {
      if (imageBytes != null) {
        try {
          imageUrl = await StorageService().uploadItemImageBytes(
            imageBytes!,
            user.uid,
          );
        } catch (_) {}
        final encoded = base64Encode(imageBytes!);
        if (encoded.length < 980000) imageBase64 = encoded;
      }

      GeoPoint? geoPoint;
      if (latitude != null && longitude != null) {
        geoPoint = GeoPoint(latitude!, longitude!);
      }

      final firestore = FirebaseFirestore.instance;
      final admins = await firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();
      final itemRef = firestore.collection('items').doc();
      final batch = firestore.batch();

      batch.set(itemRef, {
        'title': namaController.text.trim(),
        'category': kategoriController.text.trim().isNotEmpty
            ? kategoriController.text.trim()
            : 'Lainnya',
        'color': warnaController.text.trim(),
        'description': deskripsiController.text.trim(),

        'location': lokasiController.text.trim(),
        'latitude': latitude,
        'longitude': longitude,
        'geoPoint': geoPoint,

        'imageUrl': imageUrl,
        'imageData': imageBase64,
        'type': widget.type,
        'status_type': widget.type,
        'status': 'OPEN',
        'reviewStatus': 'PENDING',
        'is_received_by_owner': false,
        'userId': user.uid,
        'user_id': user.uid,
        'date': Timestamp.now(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      final isLost = widget.type == 'LOST';
      for (final admin in admins.docs) {
        final notificationRef = firestore.collection('notifications').doc();
        batch.set(notificationRef, {
          'userId': admin.id,
          'title': isLost ? 'Laporan barang hilang baru' : 'Laporan barang temuan baru',
          'message':
              '${namaController.text.trim()} menunggu konfirmasi admin.',
          'type': 'REPORT_SUBMITTED',
          'itemId': itemRef.id,
          'reporterId': user.uid,
          'reportType': widget.type,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              admins.docs.isEmpty
                  ? 'Laporan tersimpan, tetapi akun admin belum terdaftar untuk menerima notifikasi.'
                  : 'Laporan berhasil disimpan dan dikirim ke admin untuk ditinjau.',
            ),
            backgroundColor: admins.docs.isEmpty ? Colors.orange : Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLost = widget.type == 'LOST';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isLost ? 'Laporkan Barang Hilang' : 'Laporkan Barang Temuan',
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Foto Barang Bukti',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                    color: imageBytes != null
                        ? AppColors.primaryContainer
                        : Colors.grey.shade300,
                    width: imageBytes != null ? 2 : 1,
                  ),
                ),
                child: imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(imageBytes!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_a_photo,
                            size: 32,
                            color: AppColors.primaryContainer,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Ketuk untuk memilih foto',
                            style: TextStyle(
                              color: AppColors.primaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            _buildField(
              namaController,
              'Nama Barang *',
              'Contoh: Dompet Hitam',
            ),
            const SizedBox(height: 14),
            _buildField(
              kategoriController,
              'Kategori Barang',
              'Contoh: Aksesoris',
            ),
            const SizedBox(height: 14),
            _buildField(warnaController, 'Warna Barang', 'Contoh: Hitam'),

            const SizedBox(height: 14),
            _buildField(
              lokasiController,
              'Lokasi Terakhir / Ditemukan *',
              'Contoh: Gd. Fasilkom Lt. 2',
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pilihLokasiDiPeta,
              icon: const Icon(Icons.map_outlined),
              label: Text(
                latitude == null
                    ? 'Pilih Lokasi di Peta'
                    : 'Ubah Lokasi di Peta',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                foregroundColor: AppColors.primaryContainer,
                side: BorderSide(color: AppColors.primaryContainer),
              ),
            ),

            // --- PREVIEW PETA (OPENSTREETMAP) ---
            if (latitude != null && longitude != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 140,
                  child: AbsorbPointer(
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(latitude!, longitude!),
                        initialZoom: 16,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.campuslost',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(latitude!, longitude!),
                              width: 30,
                              height: 30,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 30,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 14),
            _buildField(
              deskripsiController,
              'Deskripsi Detail',
              'Sebutkan ciri-ciri khusus...',
              maxLines: 3,
            ),

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : simpanLaporan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLost
                      ? AppColors.alertRed
                      : AppColors.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'SIMPAN LAPORAN ${isLost ? "HILANG" : "TEMUAN"}',
                        style: const TextStyle(
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}
