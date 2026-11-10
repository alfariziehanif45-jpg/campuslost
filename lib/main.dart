import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Sesuaikan path import dengan struktur folder Anda
import 'services/notification_service.dart';
import 'screens/home/home_screen.dart';
import 'screens/auth/login_screen.dart'; // ✅ 1. BUKA COMMENT IMPORT INI

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
    // Pantau perubahan status login untuk simpan token FCM
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        await NotificationService().saveTokenToDatabase(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 2. GUNAKAN STREAMBUILDER AGAR UI OTOMATIS UPDATE SAAT LOGIN/LOGOUT
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Jika masih loading mengecek status login
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Jika user sudah login, lempar ke HomeScreen
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }

        // ✅ 3. JIKA BELUM LOGIN, TAMPILKAN HALAMAN LOGIN SCREEN (Bukan Text merah lagi)
        return const LoginScreen();
      },
    );
  }
}
