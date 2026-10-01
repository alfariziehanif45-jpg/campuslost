import 'package:cloud_firestore/cloud_firestore.dart';

class ItemModel {
  final String id;
  final String title;
  final String type;
  final String category;
  final String color;
  final String description;
  final String location;
  final String userId;
  final String imageUrl;
  final String status;
  final DateTime? date;
  final DateTime? createdAt;

  const ItemModel({
    required this.id,
    required this.title,
    required this.type,
    required this.category,
    required this.color,
    required this.description,
    required this.location,
    required this.userId,
    required this.imageUrl,
    required this.status,
    this.date,
    this.createdAt,
  });

  factory ItemModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }

      if (value is DateTime) {
        return value;
      }

      return null;
    }

    return ItemModel(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      type: data['type']?.toString() ?? '',
      category: data['category']?.toString() ?? '',
      color: data['color']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      location: data['location']?.toString() ?? '',
      userId: data['userId']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      status: data['status']?.toString() ?? 'OPEN',
      date: parseDate(data['date']),
      createdAt: parseDate(data['createdAt']),
    );
  }
}
