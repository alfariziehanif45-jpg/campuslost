import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String nim;
  final String email;
  final String fakultas;
  final String prodi;
  final String role;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.nim,
    required this.email,
    required this.fakultas,
    required this.prodi,
    required this.role,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final timestamp = map['createdAt'];

    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      nim: map['nim'] ?? '',
      email: map['email'] ?? '',
      fakultas: map['fakultas'] ?? '',
      prodi: map['prodi'] ?? '',
      role: map['role'] ?? 'mahasiswa',
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'nim': nim,
      'email': email,
      'fakultas': fakultas,
      'prodi': prodi,
      'role': role,
      'createdAt': createdAt,
    };
  }
}
