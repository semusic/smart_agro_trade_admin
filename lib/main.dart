import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/admin_login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_shell.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDJUKiJE_46VLMYUpQCNF9w4AEcndu7VkY",
      authDomain: "smartagroproject-3b12c.firebaseapp.com",
      projectId: "smartagroproject-3b12c",
      storageBucket: "smartagroproject-3b12c.firebasestorage.app",
      messagingSenderId: "512275992298",
      appId: "1:512275992298:web:f693d4cd5302dcb3fb5193",
    ),
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Admin Panel',
      initialRoute: '/gate',
      routes: {
        '/gate': (_) => const AdminGate(),
        '/login': (_) => const AdminLoginScreen(),
        '/dashboard': (_) => const AdminShell(),
      },
    );
  }
}

class AdminGate extends StatelessWidget {
  const AdminGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == null) {
          return const AdminLoginScreen();
        }

        return const AdminShell();
      },
    );
  }
}