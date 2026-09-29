import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/claim_model.dart';
import '../models/item_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _items =>
      _firestore.collection('items');

  CollectionReference<Map<String, dynamic>> get _claims =>
      _firestore.collection('claims');

  Future<UserModel?> getUser(String uid) async {
    final document = await _users.doc(uid).get();

    if (!document.exists || document.data() == null) {
      return null;
    }

    return UserModel.fromMap(document.data()!);
  }

  Stream<List<ItemModel>> streamItems() {
    return _items
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => ItemModel.fromDocument(doc)).toList(),
        );
  }

  Stream<List<ItemModel>> streamItemsByType(String type) {
    return _items
        .where('type', isEqualTo: type)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => ItemModel.fromDocument(doc)).toList(),
        );
  }

  Future<String> createItem({
    required String title,
    required String type,
    required String category,
    required String color,
    required String description,
    required String location,
    required String imageUrl,
    required String userId,
    required DateTime date,
  }) async {
    final document = await _items.add({
      'title': title,
      'type': type,
      'category': category,
      'color': color,
      'description': description,
      'location': location,
      'imageUrl': imageUrl,
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'status': 'ACTIVE',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  Future<ItemModel?> getItem(String itemId) async {
    final document = await _items.doc(itemId).get();

    if (!document.exists) {
      return null;
    }

    return ItemModel.fromDocument(document);
  }

  Future<void> updateItemStatus(String itemId, String status) async {
    await _items.doc(itemId).update({'status': status});
  }

  Future<String> createClaim({
    required String itemId,
    required String userId,
    required String answer,
  }) async {
    final document = await _claims.add({
      'itemId': itemId,
      'userId': userId,
      'answer': answer,
      'status': 'PENDING',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  Stream<List<ClaimModel>> streamMyClaims(String userId) {
    return _claims
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => ClaimModel.fromDocument(doc)).toList(),
        );
  }

  Future<void> updateProfile({
    required String uid,
    required String name,
    required String nim,
    required String fakultas,
    required String prodi,
  }) async {
    await _users.doc(uid).update({
      'name': name,
      'nim': nim,
      'fakultas': fakultas,
      'prodi': prodi,
    });
  }
}
