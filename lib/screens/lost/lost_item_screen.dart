import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/item_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/item_card.dart';
import '../detail/item_detail_screen.dart'; // ✅ Perbaikan: Import yang benar

class LostItemScreen extends StatefulWidget {
  const LostItemScreen({super.key});

  @override
  State<LostItemScreen> createState() => _LostItemScreenState();
}

class _LostItemScreenState extends State<LostItemScreen> {
  String _selectedCategory = 'Semua';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Barang Hilang'), elevation: 0),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChip('Semua'),
                  const SizedBox(width: 8),
                  _buildChip('Elektronik'),
                  const SizedBox(width: 8),
                  _buildChip('Dokumen'),
                  const SizedBox(width: 8),
                  _buildChip('Dompet'),
                  const SizedBox(width: 8),
                  _buildChip('Kunci'),
                  const SizedBox(width: 8),
                  _buildChip('Tas'),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.borderCard),

          // Daftar Barang Hilang
          Expanded(
            child: StreamBuilder<List<ItemModel>>(
              stream: FirestoreService().getLostItems(),
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

                if (_selectedCategory != 'Semua') {
                  items = items
                      .where(
                        (item) => item.category.toLowerCase().contains(
                          _selectedCategory.toLowerCase(),
                        ),
                      )
                      .toList();
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
                              color: AppColors.lostBg,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Icon(
                              Icons.search_off,
                              size: 48,
                              color: AppColors.lostText,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Belum Ada Laporan Barang Hilang',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Laporan barang hilang yang dibuat mahasiswa akan muncul di sini.',
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

                    // ✅ Menambahkan badge jika barang sudah ditemukan
                    final bool isResolved = item.isReceived;

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: isResolved ? 22 : 0),
                          child: ItemCard(
                            item: item,
                            onTap: () {
                              // ✅ Perbaikan: Memanggil ItemDetailScreen dengan benar
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ItemDetailScreen(item: item),
                                ),
                              );
                            },
                          ),
                        ),
                        if (isResolved)
                          Positioned(
                            top: 0,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade600,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(10),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Telah Ditemukan',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
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

  Widget _buildChip(String label) {
    final bool isSelected = _selectedCategory == label;

    return InkWell(
      borderRadius: BorderRadius.circular(9999),
      onTap: () => setState(() => _selectedCategory = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.alertRed
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: isSelected ? AppColors.alertRed : AppColors.borderCard,
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
