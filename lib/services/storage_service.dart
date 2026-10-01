import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final _storage=FirebaseStorage.instance;
  Future<String> uploadItemImage(File file,String userId) async {
    final name='${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
    final ref=_storage.ref().child('items').child(userId).child(name);
    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}
