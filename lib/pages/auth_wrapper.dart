import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/user_database.dart';
import 'welcome_page.dart';
import 'home_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

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

        final user = snapshot.data;

        if (user == null) {
          return const WelcomePage();
        }

        return FutureBuilder<void>(
          future: UserDatabase.ensureUserDocument(user),
          builder: (context, ensureSnapshot) {
            if (ensureSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (ensureSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Gagal menyiapkan database user:\n${ensureSnapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }

            return const HomePage();
          },
        );
      },
    );
  }
}
