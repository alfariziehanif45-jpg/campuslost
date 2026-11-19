import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// SERVICES
import 'services/notification_service.dart';

// SCREENS
import 'screens/auth/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inisialisasi Firebase
  await Firebase.initializeApp();

  // 2. Inisialisasi Notification Service
  await NotificationService().initialize();

  // 3. Akhiri sesi login sebelumnya.
  // Agar setiap aplikasi dibuka harus login kembali.
  await FirebaseAuth.instance.signOut();

  // 4. Jalankan aplikasi
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CampusLost',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4358B8)),
        useMaterial3: true,
      ),

      // SELALU MULAI DARI LOGIN
      home: const LoginScreen(),
    );
  }
}
