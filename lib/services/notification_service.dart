import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final _messaging=FirebaseMessaging.instance;
  Future<void> initialize() async {
    await _messaging.requestPermission(alert:true,badge:true,sound:true);
  }
  Future<String?> getToken()=>_messaging.getToken();
}
