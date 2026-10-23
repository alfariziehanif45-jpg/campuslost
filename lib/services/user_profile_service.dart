import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> createOrUpdateProfile({
    required User user,
    String? fullName,
    String? nim,
    String? faculty,
    String? prodi,
  }) async {
    try {
      final doc = _db.collection('users').doc(user.uid);

      final data = {
        'uid': user.uid,
        'user_id': user.uid,
        'name': fullName ?? user.displayName ?? 'Mahasiswa',
        'full_name': fullName ?? user.displayName ?? 'Mahasiswa',
        'nama': fullName ?? user.displayName ?? 'Mahasiswa',
        'email': user.email ?? '',
        'email_campus': user.email ?? '',
        'nim': nim ?? '',
        'faculty': faculty ?? '',
        'fakultas': faculty ?? '',
        'prodi': prodi ?? '',
        'role': 'mahasiswa',
        'reputation_score': 100,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final snapshot = await doc.get();
      if (!snapshot.exists) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }

      await doc.set(data, SetOptions(merge: true));
    } catch (e) {
      rethrow; // Lempar error ke UI
    }
  }
}
