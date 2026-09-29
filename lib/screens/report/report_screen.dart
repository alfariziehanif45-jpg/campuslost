import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';

class ReportScreen extends StatefulWidget {
  final String type;

  const ReportScreen({
    super.key,
    required this.type,
  });

  @override
  State<ReportScreen> createState() =>
      _ReportScreenState();
}

class _ReportScreenState
    extends State<ReportScreen> {
  final formKey =
      GlobalKey<FormState>();

  final titleController =
      TextEditingController();

  final colorController =
      TextEditingController();

  final descriptionController =
      TextEditingController();

  final locationController =
      TextEditingController();

  final AuthService authService =
      AuthService();

  final FirestoreService firestoreService =
      FirestoreService();

  final StorageService storageService =
      StorageService();

  final ImagePicker picker =
      ImagePicker();

  String selectedCategory =
      AppConstants.categories.first;

  DateTime selectedDate =
      DateTime.now();

  File? selectedImage;

  bool isLoading = false;

  Future<void> pickImage() async {
    final image =
        await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) return;

    setState(() {
      selectedImage =
          File(image.path);
    });
  }

  Future<void> selectDate() async {
    final result =
        await showDatePicker(
      context: context,
      firstDate:
          DateTime(2020),
      lastDate:
          DateTime.now(),
      initialDate:
          selectedDate,
    );

    if (result != null) {
      setState(() {
        selectedDate = result;
      });
    }
  }

  Future<void> submit() async {
    if (!formKey.currentState!
        .validate()) {
      return;
    }

    final user =
        authService.currentUser;

    if (user == null) {
      showMessage(
        'Silakan login terlebih dahulu.',
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String imageUrl = '';

      if (selectedImage != null) {
        imageUrl =
            await storageService
                .uploadItemImage(
          selectedImage!,
          user.uid,
        );
      }

      await firestoreService.createItem(
        title:
            titleController.text.trim(),
        type: widget.type,
        category:
            selectedCategory,
        color:
            colorController.text.trim(),
        description:
            descriptionController
                .text
                .trim(),
        location:
            locationController
                .text
                .trim(),
        imageUrl: imageUrl,
        userId: user.uid,
        date: selectedDate,
      );

      if (!mounted) return;

      showMessage(
        widget.type == 'LOST'
            ? 'Laporan barang hilang berhasil dibuat.'
            : 'Laporan barang ditemukan berhasil dibuat.',
      );

      Navigator.pop(context);
    } catch (e) {
      showMessage(
        'Gagal membuat laporan: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    colorController.dispose();
    descriptionController.dispose();
    locationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLost =
        widget.type == 'LOST';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isLost
              ? 'Laporkan Barang Hilang'
              : 'Laporkan Barang Ditemukan',
        ),
      ),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(20),
          child: Column(
            children: [
              GestureDetector(
                onTap: pickImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          Colors.grey.shade300,
                    ),
                  ),
                  child:
                      selectedImage != null
                          ? ClipRRect(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                16,
                              ),
                              child: Image.file(
                                selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Column(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,
                              children: [
                                Icon(
                                  Icons
                                      .add_a_photo,
                                  size: 50,
                                  color:
                                      Colors.grey,
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  'Tambahkan Foto',
                                ),
                              ],
                            ),
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller:
                    titleController,
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Nama barang wajib diisi';
                  }

                  return null;
                },
                decoration:
                    const InputDecoration(
                  labelText:
                      'Nama Barang',
                  prefixIcon:
                      Icon(Icons.inventory),
                ),
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue:
                    selectedCategory,
                decoration:
                    const InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon:
                      Icon(Icons.category),
                ),
                items: AppConstants
                    .categories
                    .map(
                      (category) =>
                          DropdownMenuItem(
                        value: category,
                        child:
                            Text(category),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    selectedCategory =
                        value;
                  });
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller:
                    colorController,
                decoration:
                    const InputDecoration(
                  labelText:
                      'Warna Barang',
                  prefixIcon:
                      Icon(Icons.palette),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller:
                    locationController,
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Lokasi wajib diisi';
                  }

                  return null;
                },
                decoration:
                    const InputDecoration(
                  labelText:
                      'Lokasi',
                  prefixIcon:
                      Icon(Icons.location_on),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller:
                    descriptionController,
                maxLines: 4,
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Deskripsi wajib diisi';
                  }

                  return null;
                },
                decoration:
                    const InputDecoration(
                  labelText:
                      'Deskripsi',
                  prefixIcon:
                      Icon(Icons.description),
                  alignLabelWithHint:
                      true,
                ),
              ),

              const SizedBox(height: 16),

              ListTile(
                tileColor: Colors.white,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                leading: const Icon(
                  Icons.calendar_month,
                ),
                title: const Text(
                  'Tanggal Kejadian',
                ),
                subtitle: Text(
                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                ),
                trailing:
                    const Icon(
                  Icons.chevron_right,
                ),
                onTap: selectDate,
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child:
                    ElevatedButton(
                  onPressed:
                      isLoading
                          ? null
                          : submit,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : Text(
                          isLost
                              ? 'KIRIM LAPORAN HILANG'
                              : 'KIRIM LAPORAN DITEMUKAN',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}