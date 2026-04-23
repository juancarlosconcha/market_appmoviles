import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

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
      title: 'Marketplace UA',
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        primaryColor: const Color(0xFFAF0303),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFAF0303)),
      ),
      home: const AuthWrapper(),
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
        
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF2C3E50),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFAF0303)),
            ),
          );
        }
        
        if (snapshot.hasData) {
          if (!snapshot.data!.emailVerified) {
             return const LoginScreen();
           }

          return const HomeScreen(); 
        }
        
        return const LoginScreen(); 
      },
    );
  }
}