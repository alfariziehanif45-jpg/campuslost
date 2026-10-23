import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadItemImage(File file, String userId) async {
    final name = '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
    final ref = _storage.ref().child('items').child(userId).child(name);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<String> uploadItemImageBytes(Uint8List bytes, String userId, {String extension = 'jpg'}) async {
    final name = '${DateTime.now().millisecondsSinceEpoch}.$extension';
    final ref = _storage.ref().child('items').child(userId).child(name);
    final metadata = SettableMetadata(contentType: 'image/jpeg');
    await ref.putData(bytes, metadata);
    return await ref.getDownloadURL();
  }
}
