import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget{const RegisterScreen({super.key});@override State<RegisterScreen> createState()=>_RegisterScreenState();}
class _RegisterScreenState extends State<RegisterScreen>{
 final name=TextEditingController(),nim=TextEditingController(),fakultas=TextEditingController(),prodi=TextEditingController(),email=TextEditingController(),password=TextEditingController();
 bool loading=false,obscure=true;
 void msg(String s){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));}
 Future<void> register()async{
  final values=[name.text.trim(),nim.text.trim(),fakultas.text.trim(),prodi.text.trim(),email.text.trim(),password.text];
  if(values.any((x)=>x.isEmpty)){msg('Semua data wajib diisi.');return;}
  if(password.text.length<6){msg('Password minimal 6 karakter.');return;}
  setState(()=>loading=true);
  try{
   final c=await FirebaseAuth.instance.createUserWithEmailAndPassword(email:email.text.trim(),password:password.text);
   final u=c.user!; await FirebaseFirestore.instance.collection('users').doc(u.uid).set({
    'uid':u.uid,'name':name.text.trim(),'nim':nim.text.trim(),'fakultas':fakultas.text.trim(),
    'prodi':prodi.text.trim(),'email':email.text.trim(),'role':'mahasiswa','createdAt':FieldValue.serverTimestamp(),
   });
   await u.updateDisplayName(name.text.trim()); await FirebaseAuth.instance.signOut();
   if(mounted){msg('Registrasi berhasil. Silakan login.');Navigator.pop(context);}
  }on FirebaseAuthException catch(e){msg(e.code=='email-already-in-use'?'Email sudah digunakan.':e.message??'Registrasi gagal.');}
  catch(e){msg('Terjadi kesalahan: $e');}
  finally{if(mounted)setState(()=>loading=false);}
 }
 @override void dispose(){for(final c in[name,nim,fakultas,prodi,email,password]){c.dispose();}super.dispose();}
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Daftar CampusLost')),body:SingleChildScrollView(padding:const EdgeInsets.all(24),child:Column(children:[
  const Icon(Icons.person_add_alt_1,size:70),const SizedBox(height:15),const Text('Buat Akun CampusLost',style:TextStyle(fontSize:25,fontWeight:FontWeight.bold)),const SizedBox(height:24),
  field(name,'Nama Lengkap',Icons.person_outline),field(nim,'NIM',Icons.badge_outlined,keyboard:TextInputType.number),field(fakultas,'Fakultas',Icons.account_balance_outlined),field(prodi,'Program Studi',Icons.school_outlined),field(email,'Email',Icons.email_outlined,keyboard:TextInputType.emailAddress),
  TextField(controller:password,obscureText:obscure,decoration:InputDecoration(labelText:'Password',prefixIcon:const Icon(Icons.lock_outline),suffixIcon:IconButton(onPressed:()=>setState(()=>obscure=!obscure),icon:Icon(obscure?Icons.visibility:Icons.visibility_off)))),
  const SizedBox(height:24),SizedBox(width:double.infinity,height:52,child:ElevatedButton(onPressed:loading?null:register,child:loading?const CircularProgressIndicator():const Text('DAFTAR')))
 ])));
 Widget field(TextEditingController c,String label,IconData icon,{TextInputType? keyboard})=>Padding(padding:const EdgeInsets.only(bottom:14),child:TextField(controller:c,keyboardType:keyboard,decoration:InputDecoration(labelText:label,prefixIcon:Icon(icon))));
}
