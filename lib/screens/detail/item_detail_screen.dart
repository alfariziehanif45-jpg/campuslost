import 'package:flutter/material.dart';

import '../../models/item_model.dart';

class ItemDetailScreen extends StatelessWidget {
  final ItemModel item;

  const ItemDetailScreen({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final bool lost = item.type == 'LOST';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Barang'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  item.imageUrl,
                  width: double.infinity,
                  height: 230,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox(
                      height: 230,
                      child: Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 60,
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  lost ? Icons.search : Icons.inventory_2,
                  size: 70,
                ),
              ),

            const SizedBox(height: 20),

            Text(
              item.title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Chip(
              label: Text(
                lost ? 'BARANG HILANG' : 'BARANG DITEMUKAN',
              ),
            ),

            const SizedBox(height: 18),

            detailRow(
              Icons.category_outlined,
              'Kategori',
              item.category,
            ),
            detailRow(
              Icons.palette_outlined,
              'Warna',
              item.color,
            ),
            detailRow(
              Icons.location_on_outlined,
              'Lokasi',
              item.location,
            ),
            detailRow(
              Icons.info_outline,
              'Status',
              item.status,
            ),

            const SizedBox(height: 18),

            const Text(
              'Deskripsi',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                item.description.isEmpty ? '-' : item.description,
              ),
            ),

            if (lost)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Fitur klaim akan ditambahkan berikutnya.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.handshake_outlined),
                    label: const Text('AJUKAN KLAIM'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget detailRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value.isEmpty ? '-' : value,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
