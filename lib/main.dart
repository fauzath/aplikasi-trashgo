import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'pages/splash_page.dart';
import 'pages/auth_wrapper.dart';
import 'pages/welcome_page.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/home_page.dart';
import 'pages/leaderboard_page.dart';
import 'pages/collection_page.dart';
import 'pages/streak_page.dart';
import 'pages/notification_page.dart';
import 'pages/daily_mission_page.dart';
import 'pages/scan_page.dart';
import 'pages/customize_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(const TrashGoApp());
}

class TrashGoApp extends StatelessWidget {
  const TrashGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trash Go',
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      theme: ThemeData(
        fontFamily: 'HankenGrotesk',
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme().apply(
          fontFamily: 'HankenGrotesk',
        ),
      ),
      routes: {
        '/splash': (context) => const SplashPage(),
        '/auth': (context) => const AuthWrapper(),
        '/welcome': (context) => const WelcomePage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const HomePage(),
        '/leaderboard': (context) => const LeaderboardPage(),
        '/collection': (context) => const CollectionPage(),
        '/streak': (context) => const StreakPage(),
        '/notification': (context) => const NotificationPage(),
        '/missions': (context) => const DailyMissionPage(),
        '/scan': (context) => const ScanPage(),
        '/customize': (context) => const CustomizePage(),
      },
    );
  }
}