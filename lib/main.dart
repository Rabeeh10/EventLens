import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

/// Entry point for the EventLens application.
/// 
/// Initializes Firebase services before running the Flutter app.
/// This async initialization ensures backend services are ready
/// before any Firebase-dependent features are accessed.
void main() async {
  // Ensures Flutter binding is initialized before async operations
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase SDK with platform-specific configuration
  await Firebase.initializeApp();
  
  runApp(const EventLensApp());
}

/// Root application widget for EventLens.
/// 
/// Configures the MaterialApp with global theme settings,
/// navigation, and the initial home screen.
class EventLensApp extends StatelessWidget {
  const EventLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EventLens',
      theme: _buildTheme(),
      home: const HomeScreen(),
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
