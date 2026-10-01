import 'package:cloud_firestore/cloud_firestore.dart';

class ClaimModel {
  final String id;
  final String itemId;
  final String userId;
  final String answer;
  final String status;
  final DateTime? createdAt;

  const ClaimModel({
    required this.id,
    required this.itemId,
    required this.userId,
    required this.answer,
    required this.status,
    this.createdAt,
  });

  factory ClaimModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    DateTime? createdAt;

    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    }

    return ClaimModel(
      id: doc.id,
      itemId: data['itemId']?.toString() ?? '',
      userId: data['userId']?.toString() ?? '',
      answer: data['answer']?.toString() ?? '',
      status: data['status']?.toString() ?? 'PENDING',
      createdAt: createdAt,
    );
  }
}
