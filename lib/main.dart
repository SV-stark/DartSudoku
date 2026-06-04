import 'package:flutter/material.dart';
import 'ui/screens/home_screen.dart';
import 'ui/theme.dart';

void main() {
  runApp(const DartSudokuApp());
}

/// The root widget of the DartSudoku application.
class DartSudokuApp extends StatelessWidget {
  const DartSudokuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DartSudoku',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primarySeed,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Inter',
      ),
      home: const HomeScreen(),
    );
  }
}
