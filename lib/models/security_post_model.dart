import 'package:cloud_firestore/cloud_firestore.dart';

/// Model Pos Keamanan / Satpam berdasarkan skema tabel SECURITY_POSTS pada ERD CampusLost
class SecurityPostModel {
  final String postId; // post_id INT Auto-Increment
  final String postName; // post_name VARCHAR(100) (e.g., 'Pos Satpam Utama')
  final String facultyZone; // faculty_zone VARCHAR(100) (e.g., 'Fasilkom / Rektorat')
  final String buildingCode; // building_code VARCHAR(20) (e.g., 'GD-A')
  final bool is24h; // is_24h BOOLEAN FALSE
  final String? operationalHours; // operational_hours VARCHAR(50) Nullable
  final double latitude; // latitude DECIMAL(10, 8)
  final double longitude; // longitude DECIMAL(11, 8)

  const SecurityPostModel({
    required this.postId,
    required this.postName,
    required this.facultyZone,
    required this.buildingCode,
    this.is24h = false,
    this.operationalHours,
    required this.latitude,
    required this.longitude,
  });

  factory SecurityPostModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return SecurityPostModel(
      postId: id ?? map['postId']?.toString() ?? map['post_id']?.toString() ?? '',
      postName: map['postName']?.toString() ?? map['post_name']?.toString() ?? '',
      facultyZone: map['facultyZone']?.toString() ?? map['faculty_zone']?.toString() ?? '',
      buildingCode: map['buildingCode']?.toString() ?? map['building_code']?.toString() ?? '',
      is24h: map['is24h'] == true || map['is_24h'] == true,
      operationalHours: map['operationalHours']?.toString() ?? map['operational_hours']?.toString(),
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory SecurityPostModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return SecurityPostModel.fromMap(doc.data() ?? {}, id: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'post_id': postId,
      'postId': postId,
      'post_name': postName,
      'faculty_zone': facultyZone,
      'building_code': buildingCode,
      'is_24h': is24h,
      'operational_hours': operationalHours,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
