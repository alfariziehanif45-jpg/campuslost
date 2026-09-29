import 'package:cloud_firestore/cloud_firestore.dart';

class ClaimModel {
  final String id;
  final String itemId;
  final String userId;
  final String answer;
  final String status;
  final DateTime? createdAt;

  ClaimModel({
    required this.id,
    required this.itemId,
    required this.userId,
    required this.answer,
    required this.status,
    required this.createdAt,
  });

  factory ClaimModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    final timestamp = data['createdAt'];

    return ClaimModel(
      id: document.id,
      itemId: data['itemId'] ?? '',
      userId: data['userId'] ?? '',
      answer: data['answer'] ?? '',
      status: data['status'] ?? 'PENDING',
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'userId': userId,
      'answer': answer,
      'status': status,
      'createdAt': createdAt,
    };
  }
}
