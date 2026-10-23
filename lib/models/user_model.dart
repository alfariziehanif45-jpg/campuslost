import 'package:cloud_firestore/cloud_firestore.dart';

/// Model User berdasarkan skema tabel USERS pada ERD CampusLost
class UserModel {
  final String userId; // user_id (Auto-Increment / UID Firestore)
  final String nim; // nim VARCHAR(20)
  final String fullName; // full_name VARCHAR(255)
  final String emailCampus; // email_campus VARCHAR(255)
  final String faculty; // faculty VARCHAR(100)
  final String prodi; // Program Studi
  final String phone; // phone VARCHAR(20)
  final int reputationScore; // reputation_score INT Default 0
  final String? fcmToken; // fcm_token VARCHAR(255) Nullable
  final String role; // role (mahasiswa, satpam, admin)
  final DateTime? createdAt; // created_at TIMESTAMP

  // Getter kompatibilitas kode lama
  String get uid => userId;
  String get name => fullName;
  String get email => emailCampus;
  String get fakultas => faculty;

  UserModel({
    required this.userId,
    required this.nim,
    required this.fullName,
    required this.emailCampus,
    required this.faculty,
    this.prodi = '',
    this.phone = '',
    this.reputationScore = 0,
    this.fcmToken,
    this.role = 'mahasiswa',
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final timestamp = map['createdAt'] ?? map['created_at'];

    return UserModel(
      userId:
          id ??
          map['userId']?.toString() ??
          map['uid']?.toString() ??
          map['user_id']?.toString() ??
          '',
      nim: map['nim']?.toString() ?? '',
      fullName:
          map['fullName']?.toString() ??
          map['full_name']?.toString() ??
          map['name']?.toString() ??
          '',
      emailCampus:
          map['emailCampus']?.toString() ??
          map['email_campus']?.toString() ??
          map['email']?.toString() ??
          '',
      faculty: map['faculty']?.toString() ?? map['fakultas']?.toString() ?? '',
      prodi: map['prodi']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      // Perbaikan parsing reputationScore agar aman dari error casting
      reputationScore:
          ((map['reputationScore'] ?? map['reputation_score'] ?? 0) as num)
              .toInt() ??
          0,
      fcmToken: map['fcmToken']?.toString() ?? map['fcm_token']?.toString(),
      role: map['role']?.toString() ?? 'mahasiswa',
      createdAt: timestamp is Timestamp
          ? timestamp.toDate()
          : (timestamp is DateTime ? timestamp : null),
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return UserModel.fromMap(doc.data() ?? {}, id: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'uid': userId,
      'nim': nim,
      'full_name': fullName,
      'name': fullName,
      'email_campus': emailCampus,
      'email': emailCampus,
      'faculty': faculty,
      'fakultas': faculty,
      'prodi': prodi,
      'phone': phone,
      'reputation_score': reputationScore,
      'fcm_token': fcmToken,
      'role': role,
      'created_at': createdAt,
      'createdAt': createdAt,
    };
  }

  UserModel copyWith({
    String? userId,
    String? nim,
    String? fullName,
    String? emailCampus,
    String? faculty,
    String? prodi,
    String? phone,
    int? reputationScore,
    String? fcmToken,
    String? role,
    DateTime? createdAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      nim: nim ?? this.nim,
      fullName: fullName ?? this.fullName,
      emailCampus: emailCampus ?? this.emailCampus,
      faculty: faculty ?? this.faculty,
      prodi: prodi ?? this.prodi,
      phone: phone ?? this.phone,
      reputationScore: reputationScore ?? this.reputationScore,
      fcmToken: fcmToken ?? this.fcmToken,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
