import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/item_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/item_card.dart';
import '../detail/item_detail_screen.dart'; // ✅ Import yang benar

class FoundItemScreen extends StatefulWidget {
  const FoundItemScreen({super.key});

  @override
  State<FoundItemScreen> createState() => _FoundItemScreenState();
}

class _FoundItemScreenState extends State<FoundItemScreen> {
  String _filter =
      'Semua'; // 'Semua', 'Belum Diambil', 'Sudah Diterima Pemilik'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Barang Ditemukan'), elevation: 0),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabChip('Semua'),
                  const SizedBox(width: 8),
                  _buildTabChip('Belum Diambil'),
                  const SizedBox(width: 8),
                  _buildTabChip('Sudah Diterima Pemilik'),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.borderCard),

          // Daftar Barang Ditemukan
          Expanded(
            child: StreamBuilder<List<ItemModel>>(
              stream: FirestoreService().getFoundItems(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Gagal memuat data.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  );
                }

                List<ItemModel> items = snapshot.data ?? <ItemModel>[];

                // Terapkan filter status
                if (_filter == 'Belum Diambil') {
                  items = items.where((item) => !item.isReceived).toList();
                } else if (_filter == 'Sudah Diterima Pemilik') {
                  items = items.where((item) => item.isReceived).toList();
                }

                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Icon(
                              Icons.inventory_2_outlined,
                              size: 48,
                              color: AppColors.primaryContainer,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _filter == 'Sudah Diterima Pemilik'
                                ? 'Belum Ada Barang yang Telah Diterima'
                                : 'Belum Ada Barang Ditemukan',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Laporan barang yang ditemukan di kampus akan muncul di halaman ini.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ItemCard(
                      item: item,
                      onTap: () {
                        // ✅ PERBAIKAN: Arahkan ke ItemDetailScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ItemDetailScreen(item: item),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip(String label) {
    final bool isSelected = _filter == label;

    return InkWell(
      borderRadius: BorderRadius.circular(9999),
      onTap: () {
        setState(() {
          _filter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondary
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.borderCard,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}
