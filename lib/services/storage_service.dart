import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadItemImage(File file, String userId) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

    final reference = _storage
        .ref()
        .child('items')
        .child(userId)
        .child(fileName);

    await reference.putFile(file);

    return await reference.getDownloadURL();
  }
}
