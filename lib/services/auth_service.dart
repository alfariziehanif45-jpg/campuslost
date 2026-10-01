import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth=FirebaseAuth.instance;
  final _db=FirebaseFirestore.instance;

  Future<UserCredential> register({required String email,required String password,required String name,required String nim,required String fakultas,required String prodi}) async {
    final c=await _auth.createUserWithEmailAndPassword(email:email.trim(),password:password);
    final u=c.user!;
    await _db.collection('users').doc(u.uid).set({
      'uid':u.uid,'name':name.trim(),'nim':nim.trim(),'email':email.trim(),
      'fakultas':fakultas.trim(),'prodi':prodi.trim(),'role':'mahasiswa',
      'createdAt':FieldValue.serverTimestamp(),
    });
    await u.updateDisplayName(name.trim());
    return c;
  }
  Future<UserCredential> login({required String email,required String password}) =>
      _auth.signInWithEmailAndPassword(email:email.trim(),password:password);
  Future<void> logout()=>_auth.signOut();
  User? get currentUser=>_auth.currentUser;
}
