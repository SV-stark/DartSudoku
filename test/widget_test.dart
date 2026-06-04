import 'package:flutter_test/flutter_test.dart';
import 'package:dart_sudoku/main.dart';

void main() {
  testWidgets('App loads and displays Home screen elements', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DartSudokuApp());

    // Verify that the title text and elements are present.
    expect(find.text('DartSudoku'), findsOneWidget);
    expect(find.text('ELEGANT & INTELLIGENT'), findsOneWidget);

    // Verify that the game levels section is rendered
    expect(find.text('Select Game Level'), findsOneWidget);

    // Verify difficulty button texts exist
    expect(find.text('EASY'), findsOneWidget);
    expect(find.text('MEDIUM'), findsOneWidget);
    expect(find.text('HARD'), findsOneWidget);

    // Verify solver shortcut button text exists
    expect(find.text('Sudoku Solver'), findsOneWidget);
  });
}
