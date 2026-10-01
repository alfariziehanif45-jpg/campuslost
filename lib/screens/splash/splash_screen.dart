import 'dart:async';
import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
class SplashScreen extends StatefulWidget{const SplashScreen({super.key});@override State<SplashScreen> createState()=>_SplashScreenState();}
class _SplashScreenState extends State<SplashScreen>{@override void initState(){super.initState();Timer(const Duration(seconds:2),(){if(mounted)Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const LoginScreen()));});}@override Widget build(BuildContext c)=>const Scaffold(body:Center(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(Icons.find_in_page,size:90),SizedBox(height:18),Text('CampusLost',style:TextStyle(fontSize:30,fontWeight:FontWeight.bold)),Text('Lost & Found Kampus')])));}
