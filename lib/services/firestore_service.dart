import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/claim_model.dart';
import '../models/item_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============================================================
  // ITEM
  // ============================================================

  Future<String> createItem({
    required String title,
    required String type,
    required String category,
    required String color,
    required String description,
    required String location,
    required String userId,
    String imageUrl = '',
    String imageData = '',
    bool isSensitive = false,
    String? secretVerificationQuestion,
    int? floorLevel,
    double? latitude,
    double? longitude,
  }) async {
    final document = await _db.collection('items').add({
      'title': title.trim(),
      'type': type,
      'status_type': type,
      'category': category.trim(),
      'color': color.trim(),
      'description': description.trim(),
      'location': location.trim(),
      'location_name': location.trim(),
      'userId': userId,
      'user_id': userId,
      'imageUrl': imageUrl,
      'imageData': imageData,
      'is_sensitive': isSensitive,
      'secret_verification_question': secretVerificationQuestion,
      'floor_level': floorLevel,
      'latitude': latitude,
      'longitude': longitude,
      'status': 'OPEN',
      'is_received_by_owner': false,
      'date': Timestamp.now(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  // ============================================================
  // SEMUA ITEM
  // ============================================================

  Stream<List<ItemModel>> getItems() {
    return _db.collection('items').snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => ItemModel.fromFirestore(doc))
          .toList();

      items.sort((a, b) {
        final dateA = a.createdAt ?? a.date ?? DateTime(1970);
        final dateB = b.createdAt ?? b.date ?? DateTime(1970);

        return dateB.compareTo(dateA);
      });

      return items;
    });
  }

  // ============================================================
  // BARANG HILANG
  // ============================================================

  Stream<List<ItemModel>> getLostItems() {
    return _db.collection('items').snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => ItemModel.fromFirestore(doc))
          .where((item) => item.isLost)
          .toList();

      _sortItems(items);

      return items;
    });
  }

  // ============================================================
  // BARANG DITEMUKAN
  // ============================================================

  Stream<List<ItemModel>> getFoundItems() {
    return _db.collection('items').snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => ItemModel.fromFirestore(doc))
          .where((item) => item.isFound)
          .toList();

      _sortItems(items);

      return items;
    });
  }

  void _sortItems(List<ItemModel> items) {
    items.sort((a, b) {
      final dateA = a.createdAt ?? a.date ?? DateTime(1970);
      final dateB = b.createdAt ?? b.date ?? DateTime(1970);

      return dateB.compareTo(dateA);
    });
  }

  // ============================================================
  // DETAIL ITEM
  // ============================================================

  Future<ItemModel?> getItem(String itemId) async {
    final document = await _db.collection('items').doc(itemId).get();

    if (!document.exists) {
      return null;
    }

    return ItemModel.fromFirestore(document);
  }

  // ============================================================
  // UPDATE STATUS ITEM & KONFIRMASI DITERIMA PEMILIK
  // ============================================================

  Future<void> updateItemStatus(String itemId, String status) async {
    await _db.collection('items').doc(itemId).update({'status': status});
  }

  /// Konfirmasi bahwa barang temuan sudah berhasil diterima kembali oleh pemilik sahnya
  Future<void> confirmItemReceived(String itemId) async {
    await _db.collection('items').doc(itemId).update({
      'status': 'RECEIVED',
      'is_received_by_owner': true,
      'isReceivedByOwner': true,
      'receivedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // DELETE ITEM
  // ============================================================

  Future<void> deleteItem(String itemId) async {
    await _db.collection('items').doc(itemId).delete();
  }

  // ============================================================
  // USER PROFILE
  // ============================================================

  Stream<UserModel?> streamUserProfile(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  // ============================================================
  // CLAIM
  // ============================================================

  Future<String> createClaim({
    required String itemId,
    required String userId,
    required String answer,
  }) async {
    final document = await _db.collection('claims').add({
      'itemId': itemId,
      'item_id': itemId,
      'userId': userId,
      'claimant_user_id': userId,
      'answer': answer.trim(),
      'proof_answer': answer.trim(),
      'status': 'PENDING',
      'claim_status': 'PENDING',
      'createdAt': FieldValue.serverTimestamp(),
      'created_at': FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  // ============================================================
  // CEK CLAIM DUPLIKAT
  // ============================================================

  Future<bool> hasExistingClaim({
    required String itemId,
    required String userId,
  }) async {
    final snapshot = await _db
        .collection('claims')
        .where('itemId', isEqualTo: itemId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // ============================================================
  // CLAIM MILIK USER
  // ============================================================

  Stream<List<ClaimModel>> getMyClaims(String userId) {
    return _db
        .collection('claims')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final claims = snapshot.docs
              .map((doc) => ClaimModel.fromFirestore(doc))
              .toList();

          claims.sort((a, b) {
            final dateA = a.createdAt ?? DateTime(1970);
            final dateB = b.createdAt ?? DateTime(1970);

            return dateB.compareTo(dateA);
          });

          return claims;
        });
  }
}
