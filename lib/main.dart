import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Sesuaikan path import dengan struktur folder Anda
import 'services/notification_service.dart';
import 'screens/home/home_screen.dart';
// import 'screens/auth/login_screen.dart'; // sesuaikan

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 1. Inisialisasi Notification Service
  await NotificationService().initialize();

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

// Wrapper untuk memantau status login dan menyimpan token FCM
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // 2. Pantau perubahan status login (setelah login, simpan token FCM ke Firestore)
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        await NotificationService().saveTokenToDatabase(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return const HomeScreen(); // Ganti dengan halaman utama Anda
    } else {
      return const Center(
        child: Text('Silakan Login'),
      ); // Ganti dengan LoginScreen
    }
  }
}
