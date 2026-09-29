import 'package:flutter/material.dart';

import '../../models/item_model.dart';
import '../claim/claim_screen.dart';

class ItemDetailScreen extends StatelessWidget {
  final ItemModel item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isLost = item.type == 'LOST';

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Barang')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (item.imageUrl.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 260,
                child: Image.network(
                  item.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.image_not_supported, size: 60),
                    );
                  },
                ),
              )
            else
              Container(
                height: 220,
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(Icons.inventory_2, size: 70, color: Colors.grey),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Chip(label: Text(isLost ? 'HILANG' : 'DITEMUKAN')),
                    ],
                  ),

                  const SizedBox(height: 20),

                  detailRow(Icons.category, 'Kategori', item.category),

                  detailRow(
                    Icons.palette,
                    'Warna',
                    item.color.isEmpty ? '-' : item.color,
                  ),

                  detailRow(Icons.location_on, 'Lokasi', item.location),

                  detailRow(
                    Icons.calendar_month,
                    'Tanggal',
                    item.date == null
                        ? '-'
                        : '${item.date!.day}/${item.date!.month}/${item.date!.year}',
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Deskripsi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  Text(item.description, style: const TextStyle(fontSize: 16)),

                  const SizedBox(height: 30),

                  if (item.status == 'ACTIVE')
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ClaimScreen(item: item),
                            ),
                          );
                        },
                        child: Text(
                          isLost
                              ? 'SAYA MENEMUKAN BARANG INI'
                              : 'INI BARANG SAYA',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget detailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.indigo),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
