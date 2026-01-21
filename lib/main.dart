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
    const primaryColor = Color(0xFF6366F1); // Indigo
    const secondaryColor = Color(0xFF8B5CF6); // Purple
    const tertiaryColor = Color(0xFF06B6D4); // Cyan
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: const BorderSide(width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 6,
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
