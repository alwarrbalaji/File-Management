// lib/main.dart
// ---------------------------------------------------------------------------
// App entry point.
// Forces strict Light Mode with a clean Material 3 theme.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock the status bar to light content on a transparent background
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // dark icons on light bg
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Lock to portrait mode — common for a utility app
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) => runApp(const FileManagerApp()));
}

class FileManagerApp extends StatelessWidget {
  const FileManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Manager',
      debugShowCheckedModeBanner: false,

      // ── Force strict Light Mode ───────────────────────────────────────────
      themeMode: ThemeMode.light,

      // ── Material Design 3 Light Theme ────────────────────────────────────
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,

        // Seed color → generates the full Material 3 palette
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A6EE8), // Clean blue
          brightness: Brightness.light,
          surface: Colors.white,
          // Slight warm tint to the surface variant
          surfaceContainerHighest: const Color(0xFFF0F4FF),
        ),

        // ── Scaffold / background ─────────────────────────────────────────
        scaffoldBackgroundColor: Colors.white,

        // ── AppBar ────────────────────────────────────────────────────────
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1A1C1E),
          elevation: 0,
          scrolledUnderElevation: 2,
          centerTitle: false,
          titleSpacing: 16,
          toolbarHeight: 66,
        ),

        // ── Cards ────────────────────────────────────────────────────────
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),

        // ── FAB ──────────────────────────────────────────────────────────
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 4,
          shape: StadiumBorder(),
        ),

        // ── Text ─────────────────────────────────────────────────────────
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1C1E),
          ),
          titleMedium: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1C1E),
          ),
          bodyMedium: TextStyle(color: Color(0xFF44474E)),
          labelSmall: TextStyle(color: Color(0xFF73777F)),
        ),

        // ── Divider ──────────────────────────────────────────────────────
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE3E6EC),
          space: 1,
        ),

        // ── Filled Buttons ────────────────────────────────────────────────
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // ── Dialog ────────────────────────────────────────────────────────
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        // ── SnackBar ──────────────────────────────────────────────────────
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),

        // ── Progress Indicator ────────────────────────────────────────────
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          linearMinHeight: 5,
        ),
      ),

      // ── Dark theme is intentionally left unset to enforce light mode ──────
      darkTheme: null,

      home: const HomeScreen(),
    );
  }
}