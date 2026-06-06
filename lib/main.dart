import 'package:flutter/material.dart';
import 'ui/screens/home_screen.dart';
import 'ui/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppTheme.initTheme();
  runApp(const DartSudokuApp());
}

/// The root widget of the DartSudoku application.
class DartSudokuApp extends StatelessWidget {
  const DartSudokuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'DartSudoku',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppTheme.primarySeed,
              brightness: Brightness.light,
            ),
            fontFamily: 'Inter',
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppTheme.primarySeed,
              brightness: Brightness.dark,
            ),
            fontFamily: 'Inter',
          ),
          builder: (context, child) {
            final mediaQueryData = MediaQuery.of(context);
            final clampedTextScaler = mediaQueryData.textScaler.clamp(
              minScaleFactor: 0.8,
              maxScaleFactor: 1.25,
            );
            return MediaQuery(
              data: mediaQueryData.copyWith(textScaler: clampedTextScaler),
              child: child!,
            );
          },
          home: const HomeScreen(),
        );
      },
    );
  }
}
