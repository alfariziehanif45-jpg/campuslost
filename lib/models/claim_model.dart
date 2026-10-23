import 'package:cloud_firestore/cloud_firestore.dart';

/// Model Klaim berdasarkan skema tabel CLAIMS pada ERD CampusLost
class ClaimModel {
  final String id; // claim_id (INT Auto-Increment / Document ID)
  final String itemId; // FK item_id
  final String claimantUserId; // FK claimant_user_id
  final String proofAnswer; // proof_answer TEXT Nullable
  final String? proofDocumentUrl; // proof_document_url VARCHAR(255) Nullable
  final String claimStatus; // claim_status ENUM['PENDING','APPROVED','REJECTED']
  final String? verifiedByOfficerId; // FK verified_by_officer_id INT Nullable
  final DateTime? resolvedAt; // resolved_at TIMESTAMP Nullable
  final DateTime? createdAt; // created_at TIMESTAMP

  // Getter kompatibilitas dengan kode yang sudah ada
  String get claimId => id;
  String get userId => claimantUserId;
  String get answer => proofAnswer;
  String get status => claimStatus;
  bool get isPending => claimStatus.toUpperCase() == 'PENDING';
  bool get isApproved => claimStatus.toUpperCase() == 'APPROVED';
  bool get isRejected => claimStatus.toUpperCase() == 'REJECTED';

  const ClaimModel({
    required this.id,
    required this.itemId,
    required this.claimantUserId,
    required this.proofAnswer,
    this.proofDocumentUrl,
    this.claimStatus = 'PENDING',
    this.verifiedByOfficerId,
    this.resolvedAt,
    this.createdAt,
  });

  factory ClaimModel.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is DateTime) {
        return value;
      }
      return null;
    }

    return ClaimModel(
      id: id ?? map['id']?.toString() ?? map['claim_id']?.toString() ?? '',
      itemId: map['itemId']?.toString() ?? map['item_id']?.toString() ?? '',
      claimantUserId: map['claimantUserId']?.toString() ??
          map['claimant_user_id']?.toString() ??
          map['userId']?.toString() ??
          map['user_id']?.toString() ??
          '',
      proofAnswer: map['proofAnswer']?.toString() ??
          map['proof_answer']?.toString() ??
          map['answer']?.toString() ??
          '',
      proofDocumentUrl: map['proofDocumentUrl']?.toString() ?? map['proof_document_url']?.toString(),
      claimStatus: (map['claimStatus'] ?? map['claim_status'] ?? map['status'] ?? 'PENDING')
          .toString()
          .toUpperCase(),
      verifiedByOfficerId: map['verifiedByOfficerId']?.toString() ?? map['verified_by_officer_id']?.toString(),
      resolvedAt: parseDate(map['resolvedAt'] ?? map['resolved_at']),
      createdAt: parseDate(map['createdAt'] ?? map['created_at']),
    );
  }

  factory ClaimModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return ClaimModel.fromMap(doc.data() ?? {}, id: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'claim_id': id,
      'item_id': itemId,
      'itemId': itemId,
      'claimant_user_id': claimantUserId,
      'userId': claimantUserId,
      'proof_answer': proofAnswer,
      'answer': proofAnswer,
      'proof_document_url': proofDocumentUrl,
      'claim_status': claimStatus,
      'status': claimStatus,
      'verified_by_officer_id': verifiedByOfficerId,
      'resolved_at': resolvedAt,
      'created_at': createdAt,
      'createdAt': createdAt,
    };
  }
}
