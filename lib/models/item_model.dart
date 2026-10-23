import 'package:cloud_firestore/cloud_firestore.dart';

/// Model Barang berdasarkan skema tabel ITEMS pada ERD CampusLost
class ItemModel {
  final String id; // item_id (INT Auto-Increment / Document ID)
  final String userId; // FK user_id
  final String title; // title VARCHAR(255)
  final String category; // category VARCHAR(50)
  final String statusType; // status_type ENUM['LOST','FOUND']
  final String description; // description TEXT
  final bool isSensitive; // is_sensitive BOOLEAN Default FALSE
  final String? secretVerificationQuestion; // secret_verification_question TEXT Nullable
  final String locationName; // location_name VARCHAR(255)
  final int? floorLevel; // floor_level INT Nullable
  final double? latitude; // latitude DECIMAL(10, 8) Nullable
  final double? longitude; // longitude DECIMAL(11, 8) Nullable
  final DateTime? createdAt; // created_at TIMESTAMP CURRENT

  // Kompatibilitas dengan kode yang sudah ada
  final String color;
  final String imageUrl;
  final String imageData; // Dukungan Base64
  final String status; // 'OPEN', 'CLAIMED', 'RECEIVED', 'CLOSED'
  final DateTime? date;
  final bool isReceivedByOwner; // Konfirmasi bahwa barang sudah diterima pemilik

  // Getter kompatibilitas
  String get itemId => id;
  String get type => statusType;
  String get location => locationName;
  bool get isLost => statusType.toUpperCase() == 'LOST';
  bool get isFound => statusType.toUpperCase() == 'FOUND';
  bool get isReceived =>
      isReceivedByOwner ||
      status.toUpperCase() == 'RECEIVED' ||
      status.toUpperCase() == 'SELESAI';

  const ItemModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.statusType,
    required this.description,
    this.isSensitive = false,
    this.secretVerificationQuestion,
    required this.locationName,
    this.floorLevel,
    this.latitude,
    this.longitude,
    this.color = '',
    this.imageUrl = '',
    this.imageData = '',
    this.status = 'OPEN',
    this.date,
    this.createdAt,
    this.isReceivedByOwner = false,
  });

  factory ItemModel.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is DateTime) {
        return value;
      }
      return null;
    }

    final rawStatusType = map['status_type'] ?? map['statusType'] ?? map['type'] ?? 'LOST';
    final rawLocation = map['location_name'] ?? map['locationName'] ?? map['location'] ?? '';
    final rawStatus = (map['status'] ?? 'OPEN').toString().toUpperCase();

    final bool received = map['is_received_by_owner'] == true ||
        map['isReceivedByOwner'] == true ||
        rawStatus == 'RECEIVED' ||
        rawStatus == 'SELESAI';

    return ItemModel(
      id: id ?? map['id']?.toString() ?? map['item_id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? map['user_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      statusType: rawStatusType.toString().toUpperCase(),
      description: map['description']?.toString() ?? '',
      isSensitive: map['is_sensitive'] == true || map['isSensitive'] == true,
      secretVerificationQuestion: map['secret_verification_question']?.toString() ??
          map['secretVerificationQuestion']?.toString(),
      locationName: rawLocation.toString(),
      floorLevel: (map['floor_level'] ?? map['floorLevel'] as num?)?.toInt(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      color: map['color']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString() ?? map['photo_url']?.toString() ?? '',
      imageData: map['imageData']?.toString() ?? '',
      status: map['status']?.toString() ?? 'OPEN',
      date: parseDate(map['date']),
      createdAt: parseDate(map['createdAt'] ?? map['created_at']),
      isReceivedByOwner: received,
    );
  }

  factory ItemModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return ItemModel.fromMap(doc.data() ?? {}, id: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'item_id': id,
      'userId': userId,
      'user_id': userId,
      'title': title,
      'category': category,
      'status_type': statusType,
      'type': statusType,
      'description': description,
      'is_sensitive': isSensitive,
      'isSensitive': isSensitive,
      'secret_verification_question': secretVerificationQuestion,
      'location_name': locationName,
      'location': locationName,
      'floor_level': floorLevel,
      'latitude': latitude,
      'longitude': longitude,
      'color': color,
      'imageUrl': imageUrl,
      'imageData': imageData,
      'status': isReceived ? 'RECEIVED' : status,
      'is_received_by_owner': isReceived,
      'isReceivedByOwner': isReceived,
      'date': date,
      'created_at': createdAt,
      'createdAt': createdAt,
    };
  }

  ItemModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? category,
    String? statusType,
    String? description,
    bool? isSensitive,
    String? secretVerificationQuestion,
    String? locationName,
    int? floorLevel,
    double? latitude,
    double? longitude,
    String? color,
    String? imageUrl,
    String? imageData,
    String? status,
    DateTime? date,
    DateTime? createdAt,
    bool? isReceivedByOwner,
  }) {
    return ItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      category: category ?? this.category,
      statusType: statusType ?? this.statusType,
      description: description ?? this.description,
      isSensitive: isSensitive ?? this.isSensitive,
      secretVerificationQuestion: secretVerificationQuestion ?? this.secretVerificationQuestion,
      locationName: locationName ?? this.locationName,
      floorLevel: floorLevel ?? this.floorLevel,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      color: color ?? this.color,
      imageUrl: imageUrl ?? this.imageUrl,
      imageData: imageData ?? this.imageData,
      status: status ?? this.status,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      isReceivedByOwner: isReceivedByOwner ?? this.isReceivedByOwner,
    );
  }
}
