import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

/// Entry point for the EventLens application.
/// 
/// Initializes Firebase services before running the Flutter app.
/// This async initialization ensures backend services are ready
/// before any Firebase-dependent features are accessed.
void main() async {
  // Ensures Flutter binding is initialized before async operations
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase SDK with platform-specific configuration
  try {
    await Firebase.initializeApp(
      options: defaultTargetPlatform == TargetPlatform.android
          ? const FirebaseOptions(
              apiKey: 'AIzaSyCxXE1c1xrxk_iRHyjtmmuTENi-0YweMAk',
              appId: '1:221892336129:android:6e4245868f20e9202f7e00',
              messagingSenderId: '221892336129',
              projectId: 'eventlens-b3e72',
              storageBucket: 'eventlens-b3e72.firebasestorage.app',
            )
          : null,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  
  runApp(const EventLensApp());
}

/// Root application widget for EventLens.
/// 
/// Configures the MaterialApp with global theme settings,
/// navigation, and authentication-based routing.
class EventLensApp extends StatelessWidget {
  const EventLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EventLens',
      theme: _buildTheme(),
      home: const AuthStateHandler(),
    );
  }

  /// Builds the application-wide theme configuration.
  /// 
  /// TODO: Extract to lib/core/theme/app_theme.dart for better organization
  ThemeData _buildTheme() {
    const primaryColor = Color(0xFF1565C0);
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}

/// Authentication state handler widget.
/// 
/// Listens to Firebase authentication state and routes users accordingly:
/// - Not authenticated -> LoginScreen
/// - Authenticated -> HomeScreen
class AuthStateHandler extends StatelessWidget {
  const AuthStateHandler({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    
    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Route based on authentication state
        if (snapshot.hasData && snapshot.data != null) {
          // User is authenticated -> show HomeScreen
          return const HomeScreen();
        } else {
          // User is not authenticated -> show LoginScreen
          return const LoginScreen();
        }
      },
    );
  }
}
