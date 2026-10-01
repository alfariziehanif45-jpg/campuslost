import 'package:flutter/material.dart';

import '../../models/item_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/item_card.dart';
import '../detail/item_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController searchController = TextEditingController();

  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cari Barang'), centerTitle: true),

      body: Column(
        children: [
          // ==============================
          // SEARCH FIELD
          // ==============================
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

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),

          // ==============================
          // DATA BARANG
          // ==============================
          Expanded(
            child: StreamBuilder<List<ItemModel>>(
              stream: FirestoreService().getItems(),

              builder: (context, snapshot) {
                // Loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Error
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Gagal memuat data:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                // Semua data
                final List<ItemModel> allItems = snapshot.data ?? [];

                // Filter data
                final List<ItemModel> items = allItems.where((item) {
                  if (searchQuery.isEmpty) {
                    return true;
                  }

                  final String title = item.title.toLowerCase();

                  final String category = item.category.toLowerCase();

                  final String color = item.color.toLowerCase();

                  final String location = item.location.toLowerCase();

                  final String description = item.description.toLowerCase();

                  final String type = item.type.toLowerCase();

                  return title.contains(searchQuery) ||
                      category.contains(searchQuery) ||
                      color.contains(searchQuery) ||
                      location.contains(searchQuery) ||
                      description.contains(searchQuery) ||
                      type.contains(searchQuery);
                }).toList();

                // Tidak ada data
                if (items.isEmpty) {
                  return _emptyResult();
                }

                // List data
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),

                  itemCount: items.length,

                  itemBuilder: (BuildContext context, int index) {
                    final ItemModel item = items[index];

                    return ItemCard(
                      title: item.title,
                      category: item.category,
                      location: item.location,
                      type: item.type,
                      imageUrl: item.imageUrl,

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) {
                              return ItemDetailScreen(
                                title: item.title,
                                category: item.category,
                                color: item.color,
                                location: item.location,
                                description: item.description,
                                type: item.type,
                                imageUrl: item.imageUrl,
                              );
                            },
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

  // ==============================
  // EMPTY RESULT
  // ==============================

  Widget _emptyResult() {
    if (searchQuery.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 70, color: Colors.grey),

            SizedBox(height: 15),

            Text(
              'Belum ada data barang.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 70, color: Colors.grey),

          const SizedBox(height: 15),

          const Text(
            'Data tidak ditemukan.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(
            'Tidak ada barang yang cocok dengan\n'
            '"$searchQuery"',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
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
