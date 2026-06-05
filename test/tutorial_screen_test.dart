import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_sudoku/ui/screens/tutorial_screen.dart';

void main() {
  testWidgets('TutorialScreen renders lessons tab by default', (
    WidgetTester tester,
  ) async {
    // Set screen size to ensure scrollable views are readable and clickable
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: TutorialScreen()));

    // Verify header exists
    expect(find.text('Sudoku School'), findsOneWidget);

    // Verify tabs exist
    expect(find.text('LESSONS'), findsOneWidget);
    expect(find.text('MASTERY PRACTICE'), findsOneWidget);

    // Verify lesson title is visible (Basics: Scanning is Lesson 1)
    expect(find.text('Basics: Scanning'), findsOneWidget);

    // Verify pagination controls are shown
    expect(find.text('PREVIOUS'), findsOneWidget);
    expect(find.text('CONTINUE'), findsOneWidget);
  });

  testWidgets('TutorialScreen can open syllabus bottom sheet', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: TutorialScreen()));

    // Tap lesson selector title
    await tester.tap(find.text('Basics: Scanning'));
    await tester.pumpAndSettle();

    // Verify syllabus title in bottom sheet
    expect(find.text('Sudoku School Syllabus'), findsOneWidget);

    // Verify categories in syllabus
    expect(find.text('BASICS & SCANNING'), findsOneWidget);
    expect(find.text('HIDDEN TECHNIQUES'), findsOneWidget);
  });

  testWidgets('TutorialScreen can switch to Mastery Practice tab', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: TutorialScreen()));

    // Tap MASTERY PRACTICE tab
    await tester.tap(find.text('MASTERY PRACTICE'));
    await tester.pumpAndSettle();

    // Verify practice elements are rendered
    expect(find.text('PRACTICING TECHNIQUE'), findsOneWidget);
    expect(find.text('REVEAL HINT'), findsOneWidget);
    expect(find.text('CHANGE TECHNIQUE'), findsOneWidget);
    expect(find.text('NEW CHALLENGE'), findsOneWidget);
  });

  testWidgets('Mastery Practice reveal hint works', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: TutorialScreen()));

    // Switch to Mastery Practice tab
    await tester.tap(find.text('MASTERY PRACTICE'));
    await tester.pumpAndSettle();

    // Verify hint card is NOT present initially
    expect(find.byIcon(Icons.tips_and_updates_rounded), findsNothing);

    // Tap REVEAL HINT
    await tester.tap(find.text('REVEAL HINT'));
    await tester.pumpAndSettle();

    // Verify HIDE HINT button text and hint card are visible
    expect(find.text('HIDE HINT'), findsOneWidget);
    expect(find.byIcon(Icons.tips_and_updates_rounded), findsOneWidget);
  });
}
