import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..tryAutoLogin()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: 'Ping',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;

    switch (status) {
      case AuthStatus.unknown:
        return const SplashScreen();
      case AuthStatus.authenticated:
        return const HomeScreen();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
