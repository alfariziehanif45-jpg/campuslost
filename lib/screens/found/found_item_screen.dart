import 'package:flutter/material.dart';

import '../../models/item_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/item_card.dart';

class FoundItemScreen extends StatelessWidget {
  const FoundItemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barang Ditemukan'),
      ),
      body: StreamBuilder<List<ItemModel>>(
        stream: FirestoreService().getFoundItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Gagal memuat data.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final items = snapshot.data ?? <ItemModel>[];

          if (items.isEmpty) {
            return const Center(
              child: Text('Belum ada barang ditemukan.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return ItemCard(
                item: items[index],
              );
            },
          );
        },
      ),
    );
  }
}
