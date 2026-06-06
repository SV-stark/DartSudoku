import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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

  testWidgets(
    'Mastery Practice advanced technique shows locate pattern stage',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: TutorialScreen()));

      // Switch to Mastery Practice tab
      await tester.tap(find.text('MASTERY PRACTICE'));
      await tester.pumpAndSettle();

      // Tap CHANGE TECHNIQUE
      await tester.tap(find.text('CHANGE TECHNIQUE'));
      await tester.pumpAndSettle();

      // Tap Hidden Pair to select it
      await tester.tap(find.text('Hidden Pair'));
      await tester.pumpAndSettle();

      // Verify LOCATE THE PATTERN CELLS panel is shown
      expect(find.text('LOCATE THE PATTERN CELLS'), findsOneWidget);
      expect(find.text('0 of 2 cells identified'), findsOneWidget);
    },
  );

  testWidgets('TutorialScreen renders TIME ATTACK tab and can start blitz', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: TutorialScreen()));

    // Verify Time Attack tab exists
    expect(find.text('TIME ATTACK'), findsOneWidget);

    // Tap TIME ATTACK tab
    await tester.tap(find.text('TIME ATTACK'));
    await tester.pumpAndSettle();

    // Verify Time Attack blitz lobby is rendered
    expect(find.text('TIME ATTACK BLITZ'), findsOneWidget);
    expect(find.text('START BLITZ CHALLENGE'), findsOneWidget);

    // Tap start button
    await tester.tap(find.text('START BLITZ CHALLENGE'));
    await tester.pumpAndSettle();

    // Verify game screen components are shown
    expect(find.textContaining('Score: 0'), findsOneWidget);
    expect(find.textContaining('Current Strategy:'), findsOneWidget);
  });

  testWidgets('TutorialScreen candidate filter chip toggles selected state', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: TutorialScreen()));

    // Verify candidate filter bar is displayed
    expect(find.text('CANDIDATE FILTER'), findsOneWidget);

    // Tap on digit chip '3'
    final chip3 = find.widgetWithText(ChoiceChip, '3');
    await tester.tap(chip3);
    await tester.pumpAndSettle();

    // Verify ChoiceChip '3' is selected
    final ChoiceChip choiceChip = tester.widget(chip3);
    expect(choiceChip.selected, isTrue);

    // Tap on digit chip '3' again to deselect
    await tester.tap(chip3);
    await tester.pumpAndSettle();

    final ChoiceChip choiceChipDeselected = tester.widget(chip3);
    expect(choiceChipDeselected.selected, isFalse);
  });

  testWidgets('TutorialScreen autoplay lessons plays and pauses slides', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: TutorialScreen()));

    // Verify Autoplay button exists and is in play state (shows play arrow)
    final autoplayButton = find.byTooltip('Autoplay Lessons');
    expect(autoplayButton, findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

    // Tap Autoplay button to start playback
    await tester.tap(autoplayButton);
    await tester.pump();

    // Verify icon switches to pause
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

    // Fast-forward time to let autoplay timer trigger (5 seconds lesson duration)
    // The first slide of Lesson 1 has no expectedValue, so _isSolved is true.
    // It should transition to Slide 2 which is unsolved.
    await tester.pump(const Duration(seconds: 6));

    // Verify slide transitioned to the second slide (Tap the cell and input 9.)
    expect(find.textContaining('Tap the cell and input 9.'), findsOneWidget);

    // If we wait another 6 seconds without solving the slide, it should pause and show snackbar
    await tester.pump(const Duration(seconds: 6));
    expect(
      find.textContaining(
        'Autoplay paused. Please solve the current step to proceed.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'TutorialScreen can open school analytics dashboard bottom sheet',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: TutorialScreen()));

      // Locate the school analytics icon button in the header
      final analyticsBtn = find.byTooltip('Syllabus & Analytics');
      expect(analyticsBtn, findsOneWidget);
      await tester.tap(analyticsBtn);
      await tester.pumpAndSettle();

      // Verify analytics sheet elements are visible
      expect(find.text('School Analytics'), findsOneWidget);
      expect(find.text('LESSONS'), findsNWidgets(2));
      expect(find.text('MISTAKES MADE'), findsOneWidget);
      expect(find.text('CURRICULUM TIERS PROGRESS'), findsOneWidget);
    },
  );

  testWidgets('TutorialScreen sequential path tracing in Stage 0', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Setup mock shared preferences to unlock all lessons/tiers
    SharedPreferences.setMockInitialValues({
      'completed_lessons': List.generate(45, (i) => i.toString()),
      'practice_counts': jsonEncode(
        Map.fromIterable(
          List.generate(45, (i) => i),
          key: (i) => i.toString(),
          value: (i) => 3,
        ),
      ),
    });

    await tester.pumpWidget(const MaterialApp(home: TutorialScreen()));

    // Switch to Mastery Practice tab
    await tester.tap(find.text('MASTERY PRACTICE'));
    await tester.pumpAndSettle();

    // Tap CHANGE TECHNIQUE
    await tester.tap(find.text('CHANGE TECHNIQUE'));
    await tester.pumpAndSettle();

    // Scroll until X-Wing is visible
    final xWingFinder = find.text('X-Wing');
    await tester.scrollUntilVisible(
      xWingFinder,
      100.0,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    // Tap X-Wing
    await tester.tap(xWingFinder);
    await tester.pumpAndSettle();

    // Verify we are at Stage 0 (Locating/tracing the pattern)
    // "Trace the X-Wing conjugate chain in sequence" should be shown in practice text
    expect(find.textContaining('conjugate chain in sequence'), findsOneWidget);

    // Correct path coordinates for X-Wing: (1,1) -> (1,6) -> (5,6) -> (5,1)
    // Let's test incorrect tap first: tapping (3,3) which is not part of the path
    final wrongCell = find.byKey(const Key('cell_3_3'));
    await tester.tap(wrongCell);
    await tester.pumpAndSettle();

    // Verify error message is shown
    expect(
      find.textContaining('does not continue the chain sequence'),
      findsOneWidget,
    );

    // Let's tap the correct sequence:
    // Cell (1,1) is starting endpoint
    final cell1_1 = find.byKey(const Key('cell_1_1'));
    await tester.tap(cell1_1);
    await tester.pumpAndSettle();

    // Verify remaining message count decreased (path length is 4, remaining is 3)
    expect(find.textContaining('Remaining: 3 cells to trace'), findsOneWidget);

    // Cell (1,6)
    final cell1_6 = find.byKey(const Key('cell_1_6'));
    await tester.tap(cell1_6);
    await tester.pumpAndSettle();
    expect(find.textContaining('Remaining: 2 cells to trace'), findsOneWidget);

    // Let's test backtracking: tap cell (1,6) again to untap it
    await tester.tap(cell1_6);
    await tester.pumpAndSettle();
    expect(find.textContaining('Remaining: 3 cells to trace'), findsOneWidget);

    // Re-tap cell (1,6) to proceed
    await tester.tap(cell1_6);
    await tester.pumpAndSettle();

    // Cell (5,6)
    final cell5_6 = find.byKey(const Key('cell_5_6'));
    await tester.tap(cell5_6);
    await tester.pumpAndSettle();
    expect(find.textContaining('Remaining: 1 cells to trace'), findsOneWidget);

    // Cell (5,1)
    final cell5_1 = find.byKey(const Key('cell_5_1'));
    await tester.tap(cell5_1);
    await tester.pumpAndSettle();

    // Now we should have transitioned to Stage 1 (eliminate candidate on target cell)
    expect(find.textContaining('Correct pattern identified!'), findsOneWidget);
  });
}
