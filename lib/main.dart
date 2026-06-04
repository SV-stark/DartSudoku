import 'package:flutter/material.dart';
import 'ui/screens/home_screen.dart';
import 'ui/theme.dart';

void main() {
  runApp(const SudokuNexusApp());
}

/// The root widget of the Sudoku Nexus application.
class SudokuNexusApp extends StatelessWidget {
  const SudokuNexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sudoku Nexus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppTheme.backgroundColor,
        fontFamily: 'Inter', // Default system font fallback or standard Roboto/Inter
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.neonViolet,
          brightness: Brightness.dark,
          background: AppTheme.backgroundColor,
          surface: AppTheme.surfaceColor,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
