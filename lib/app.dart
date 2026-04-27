import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hospital/screens/home/web_home_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/city/city_selection_screen.dart';
import 'screens/main/main_shell.dart';
import 'screens/main/web_dashboard_shell.dart';
import 'services/auth_service.dart';
import 'model/user_model.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartCare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
      ),
      home: StreamBuilder<User?>(
                stream: AuthService.authStateChanges,
                builder: (context, authSnapshot) {
                  // ── 1. Firebase still initialising ────────────────────────────────
                  if (authSnapshot.connectionState == ConnectionState.waiting) {
                    return const SplashScreen();
                  }

                  // ── 2. Not logged in ─────────────────────────────────────────────
                  if (!authSnapshot.hasData || authSnapshot.data == null) {
                    // Web → show premium landing page
                    // Mobile → show auth screen
                    return kIsWeb ? const WebHomeScreen() : const AuthScreen();
                  }

                  // ── 3. Logged in — fetch Firestore profile to check city ──────────
                  final uid = authSnapshot.data!.uid;
                  return FutureBuilder<UserModel?>(
                    future: AuthService.getUserData(uid),
                    builder: (context, userSnapshot) {
                      // Still fetching user data — show splash
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const SplashScreen();
                      }

                      final user = userSnapshot.data;

                      // City is already set → go straight to shell
                      if (user != null &&
                          user.city != null &&
                          user.city!.isNotEmpty) {
                        // Web → premium sidebar dashboard
                        // Mobile → bottom-nav shell
                        return kIsWeb
                            ? WebDashboardShell(selectedCity: user.city!)
                            : MainShell(selectedCity: user.city!);
                      }

                      // City not set yet → ask user to pick one (first-time)
                      return const CitySelectionScreen();
                    },
                  );
                },
              ),
    );
  }
}
