import 'package:cloud_firestore/cloud_firestore.dart';

class ItemModel {
  final String id;
  final String title;
  final String type;
  final String category;
  final String color;
  final String description;
  final String location;
  final String imageUrl;
  final String userId;
  final DateTime? date;
  final String status;
  final DateTime? createdAt;

  ItemModel({
    required this.id,
    required this.title,
    required this.type,
    required this.category,
    required this.color,
    required this.description,
    required this.location,
    required this.imageUrl,
    required this.userId,
    required this.date,
    required this.status,
    required this.createdAt,
  });

  factory ItemModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    final dateTimestamp = data['date'];
    final createdTimestamp = data['createdAt'];

    return ItemModel(
      id: document.id,
      title: data['title'] ?? '',
      type: data['type'] ?? 'LOST',
      category: data['category'] ?? '',
      color: data['color'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      userId: data['userId'] ?? '',
      date: dateTimestamp is Timestamp ? dateTimestamp.toDate() : null,
      status: data['status'] ?? 'ACTIVE',
      createdAt: createdTimestamp is Timestamp
          ? createdTimestamp.toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'type': type,
      'category': category,
      'color': color,
      'description': description,
      'location': location,
      'imageUrl': imageUrl,
      'userId': userId,
      'date': date,
      'status': status,
      'createdAt': createdAt,
    };
  }
}
