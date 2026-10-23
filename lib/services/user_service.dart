import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Satu tempat untuk semua operasi dokumen user di Firestore.
class UserService {
  UserService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Referensi dokumen users/{uid}
  static DocumentReference<Map<String, dynamic>> userDoc(String uid) =>
      _db.collection('users').doc(uid);

  /// Dipakai saat REGISTER → simpan data lengkap pendaftaran.
  static Future<void> saveUserData(
    String uid,
    Map<String, dynamic> data,
  ) async {
    await userDoc(uid).set({
      'uid': uid,
      'user_id': uid,
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Dipakai saat LOGIN & saat membuka PROFILE.
  /// - Kalau dokumen belum ada → dibuat otomatis dari data Firebase Auth
  ///   (mis. registrasi dulu gagal simpan karena offline, atau akun dibuat
  ///   manual di Firebase Console).
  /// - Kalau sudah ada → update lastLoginAt & updatedAt saja.
  static Future<void> ensureUserDocument(User user) async {
    final ref = userDoc(user.uid);
    final snap = await ref.get();

    if (!snap.exists) {
      final displayName = (user.displayName ?? '').trim();
      final nama = displayName.isEmpty ? 'Mahasiswa' : displayName;

      await ref.set({
        'uid': user.uid,
        'user_id': user.uid,
        'name': nama,
        'full_name': nama,
        'email': user.email ?? '',
        'email_campus': user.email ?? '',
        'nim': '',
        'fakultas': 'Fakultas Ilmu Komputer',
        'faculty': 'Fakultas Ilmu Komputer',
        'prodi': 'Teknik Informatika',
        'role': 'mahasiswa',
        'reputation_score': 100,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.set({
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }
}
