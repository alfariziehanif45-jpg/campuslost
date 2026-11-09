import 'package:cloud_firestore/cloud_firestore.dart';

class ClaimModel {
  final String id;
  final String itemId;
  final String userId;
  final String answer;
  final String status; // PENDING, APPROVED, REJECTED
  final DateTime? createdAt;

  ClaimModel({
    required this.id,
    required this.itemId,
    required this.userId,
    required this.answer,
    required this.status,
    this.createdAt,
  });

  // Konstruktor tambahan untuk mempermudah pembuatan objek baru
  factory ClaimModel.fromFirestore(DocumentSnapshot doc) {
    // Ambil data dan pastikan tipenya Map<String, dynamic>
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ClaimModel(
      id: doc.id,
      itemId: data['itemId'] as String? ?? data['item_id'] as String? ?? '',
      userId:
          data['userId'] as String? ??
          data['claimant_user_id'] as String? ??
          '',
      answer:
          data['answer'] as String? ?? data['proof_answer'] as String? ?? '',
      status:
          (data['status'] as String? ??
                  data['claim_status'] as String? ??
                  'PENDING')
              .toUpperCase(),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : null,
    );
  }

  // Getter untuk mempermudah cek status di UI
  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';
}
