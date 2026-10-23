import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/item_model.dart';
import '../screens/detail/item_detail_screen.dart'; // ✅ Import dirapikan (hanya 1)

class ItemCard extends StatelessWidget {
  final ItemModel item;
  final VoidCallback? onTap;

  const ItemCard({super.key, required this.item, this.onTap});

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Baru saja';
    final diff = DateTime.now().difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Baru saja';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    } else if (diff.inDays == 1) {
      return 'Kemarin';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari lalu';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Widget _buildThumbnail() {
    Widget imageWidget;

    if (item.imageData.isNotEmpty) {
      try {
        final decodedBytes = base64Decode(item.imageData);
        imageWidget = Image.memory(
          decodedBytes,
          width: 82,
          height: 82,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        );
      } catch (_) {
        imageWidget = _buildPlaceholder();
      }
    } else if (item.imageUrl.isNotEmpty) {
      imageWidget = Image.network(
        item.imageUrl,
        width: 82,
        height: 82,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    } else {
      imageWidget = _buildPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          imageWidget,
          if (item.isSensitive)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                color: Colors.black.withValues(alpha: 0.65),
                child: const Text(
                  'Privasi Dilindungi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        item.isFound ? Icons.inventory_2_outlined : Icons.search_outlined,
        color: AppColors.primaryContainer,
        size: 32,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isFound = item.isFound;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderCard, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.04),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap:
              onTap ??
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // ✅ PERBAIKAN DI SINI: LostDetailScreen diubah menjadi ItemDetailScreen
                    builder: (_) => ItemDetailScreen(item: item),
                  ),
                );
              },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildThumbnail(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badge & Timestamp
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: item.isReceived
                                  ? AppColors.foundBg
                                  : (isFound
                                        ? AppColors.foundBg
                                        : AppColors.lostBg),
                              borderRadius: BorderRadius.circular(9999),
                              border: Border.all(
                                color: item.isReceived
                                    ? AppColors.foundBorder
                                    : (isFound
                                          ? AppColors.foundBorder
                                          : AppColors.lostBorder),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: (item.isReceived || isFound)
                                        ? AppColors.foundText
                                        : AppColors.lostText,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item.isReceived
                                      ? 'SUDAH DITERIMA'
                                      : (isFound ? 'DITEMUKAN' : 'HILANG'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: (item.isReceived || isFound)
                                        ? AppColors.foundText
                                        : AppColors.lostText,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatTimeAgo(item.createdAt ?? item.date),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Title
                      Text(
                        item.title.isNotEmpty ? item.title : 'Tanpa Judul',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Location
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              item.locationName.isNotEmpty
                                  ? item.locationName
                                  : 'Lokasi tidak ditentukan',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Footer: Reporter and Claim Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isFound
                                    ? Icons.verified_user_outlined
                                    : Icons.person_outline,
                                size: 14,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isFound
                                    ? 'Penemu Terverifikasi'
                                    : 'Pelapor Kampus',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.isReceived
                                  ? 'Telah Diterima Pemilik'
                                  : (item.status == 'CLAIMED'
                                        ? 'Sudah Diklaim'
                                        : (isFound
                                              ? 'Belum Diklaim'
                                              : 'Pencarian Aktif')),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: item.isReceived
                                    ? AppColors.foundText
                                    : AppColors.primaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
