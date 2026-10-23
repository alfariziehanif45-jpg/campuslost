import 'package:cloud_firestore/cloud_firestore.dart';

/// Model Notifikasi berdasarkan skema tabel NOTIFICATIONS pada ERD CampusLost
class NotificationModel {
  final String id; // notification_id (Auto-Increment / Firestore Doc ID)
  final String userId; // FK user_id
  final String title; // title VARCHAR(255)
  final String messageBody; // message_body TEXT
  final String notificationType; // notification_type VARCHAR(50) (e.g., 'MATCH', 'CLAIM', 'STATUS')
  final bool isRead; // is_read BOOLEAN FALSE
  final DateTime? sentAt; // sent_at TIMESTAMP CURRENT_TIMESTAMP

  String get notificationId => id;
  String get message => messageBody;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.messageBody,
    required this.notificationType,
    this.isRead = false,
    this.sentAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is DateTime) {
        return value;
      }
      return null;
    }

    return NotificationModel(
      id: id ?? map['id']?.toString() ?? map['notification_id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? map['user_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      messageBody: map['messageBody']?.toString() ??
          map['message_body']?.toString() ??
          map['body']?.toString() ??
          map['message']?.toString() ??
          '',
      notificationType: map['notificationType']?.toString() ??
          map['notification_type']?.toString() ??
          'INFO',
      isRead: map['isRead'] == true || map['is_read'] == true,
      sentAt: parseDate(map['sentAt'] ?? map['sent_at'] ?? map['createdAt']),
    );
  }

  factory NotificationModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return NotificationModel.fromMap(doc.data() ?? {}, id: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'notification_id': id,
      'user_id': userId,
      'userId': userId,
      'title': title,
      'message_body': messageBody,
      'messageBody': messageBody,
      'notification_type': notificationType,
      'notificationType': notificationType,
      'is_read': isRead,
      'sent_at': sentAt,
    };
  }
}
