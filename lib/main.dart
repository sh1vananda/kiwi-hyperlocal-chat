import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hexa Chat',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/chat': (context) => const ChatScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          return user == null ? const LoginScreen() : const ChatScreen();
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
