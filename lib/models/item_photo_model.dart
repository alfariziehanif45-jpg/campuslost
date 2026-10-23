import 'package:cloud_firestore/cloud_firestore.dart';

/// Model Foto Barang berdasarkan skema tabel ITEM_PHOTOS pada ERD CampusLost
class ItemPhotoModel {
  final String photoId; // photo_id INT Auto-Increment
  final String itemId; // FK item_id INT
  final String photoUrl; // photo_url VARCHAR(255)
  final bool isBlurredAuto; // is_blurred_auto BOOLEAN FALSE (Proteksi Privasi Otomatis)
  final DateTime? uploadDate; // upload_date TIMESTAMP CURRENT_TIMESTAMP

  const ItemPhotoModel({
    required this.photoId,
    required this.itemId,
    required this.photoUrl,
    this.isBlurredAuto = false,
    this.uploadDate,
  });

  factory ItemPhotoModel.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is DateTime) {
        return value;
      }
      return null;
    }

    return ItemPhotoModel(
      photoId: id ?? map['photoId']?.toString() ?? map['photo_id']?.toString() ?? '',
      itemId: map['itemId']?.toString() ?? map['item_id']?.toString() ?? '',
      photoUrl: map['photoUrl']?.toString() ?? map['photo_url']?.toString() ?? '',
      isBlurredAuto: map['isBlurredAuto'] == true || map['is_blurred_auto'] == true,
      uploadDate: parseDate(map['uploadDate'] ?? map['upload_date'] ?? map['createdAt']),
    );
  }

  factory ItemPhotoModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return ItemPhotoModel.fromMap(doc.data() ?? {}, id: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'photo_id': photoId,
      'photoId': photoId,
      'item_id': itemId,
      'itemId': itemId,
      'photo_url': photoUrl,
      'photoUrl': photoUrl,
      'is_blurred_auto': isBlurredAuto,
      'upload_date': uploadDate,
    };
  }
}
