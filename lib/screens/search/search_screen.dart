import 'package:flutter/material.dart';

import '../../models/item_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/item_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final searchController = TextEditingController();

  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cari Barang')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari nama, kategori, warna, lokasi...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          searchController.clear();

                          setState(() {
                            searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<ItemModel>>(
              stream: FirestoreService().getItems(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Gagal memuat data:\n${snapshot.error}'),
                  );
                }

                final allItems = snapshot.data ?? [];

                final items = allItems.where((item) {
                  if (searchQuery.isEmpty) {
                    return true;
                  }

                  return item.title.toLowerCase().contains(searchQuery) ||
                      item.category.toLowerCase().contains(searchQuery) ||
                      item.color.toLowerCase().contains(searchQuery) ||
                      item.location.toLowerCase().contains(searchQuery) ||
                      item.description.toLowerCase().contains(searchQuery);
                }).toList();

                if (items.isEmpty) {
                  return const Center(child: Text('Data tidak ditemukan.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return ItemCard(item: items[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
