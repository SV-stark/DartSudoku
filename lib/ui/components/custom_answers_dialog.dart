import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/pdf_exporter.dart';
import '../../core/sudoku_analyzer.dart';
import '../../core/sudoku_logic.dart';
import '../../core/sudoku_ocr_scanner.dart';
import 'sudoku_grid.dart';

/// Modal dialog allowing users to inspect the full solution grid, step breakdown,
/// and answer key for any custom puzzle entered in Solver or Designer screen.
class CustomAnswersDialog extends StatefulWidget {
  final List<List<int>> board;

  const CustomAnswersDialog({super.key, required this.board});

  static void show(BuildContext context, List<List<int>> board) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CustomAnswersDialog(board: board),
    );
  }

  @override
  State<CustomAnswersDialog> createState() => _CustomAnswersDialogState();
}

class _CustomAnswersDialogState extends State<CustomAnswersDialog> {
  late final Future<CustomPuzzleSolveResult> _solveFuture;

  @override
  void initState() {
    super.initState();
    final copy = SudokuLogic.copyBoard(widget.board);
    _solveFuture = Isolate.run(() => SudokuAnalyzer.solveWithStepBreakdown(copy));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.rule_folder_rounded,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Custom Puzzle Answer Key',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<CustomPuzzleSolveResult>(
              future: _solveFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(strokeWidth: 3),
                        SizedBox(height: 16),
                        Text('Analyzing custom puzzle breakdown...'),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Failed to analyze puzzle: ${snapshot.error}',
                        style: TextStyle(color: theme.colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final solveResult = snapshot.data!;
                final sdkString = SudokuOCRScanner.exportSDKString(
                  solveResult.solvedBoard,
                );
                final isClue = List.generate(
                  9,
                  (r) => List.generate(9, (c) => widget.board[r][c] != 0),
                );

                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Validation status chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: solveResult.isValid
                                    ? Colors.green.withValues(alpha: 0.15)
                                    : Colors.red.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    solveResult.isValid
                                        ? Icons.check_circle_rounded
                                        : Icons.error_rounded,
                                    size: 18,
                                    color: solveResult.isValid
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    solveResult.isValid
                                        ? (solveResult.isUnique
                                            ? 'Guaranteed Unique Solution'
                                            : 'Multiple Valid Solutions')
                                        : 'Unsolvable / Conflicting Input',
                                    style: TextStyle(
                                      color: solveResult.isValid
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 9x9 Solved Solution Matrix
                            Text(
                              'Full Solution Grid',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            AspectRatio(
                              aspectRatio: 1.0,
                              child: SudokuGrid(
                                board: solveResult.solvedBoard,
                                selectedRow: -1,
                                selectedCol: -1,
                                isClue: isClue,
                                onCellTap: (_, _) {},
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Sequential Step Breakdown
                            Text(
                              'Logical Step-by-Step Breakdown (${solveResult.steps.length} steps)',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (solveResult.steps.isEmpty)
                              Text(
                                'No individual steps detected. Matrix resolved via direct search.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: solveResult.steps.length,
                                itemBuilder: (context, idx) {
                                  final step = solveResult.steps[idx];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        child: Text('${idx + 1}'),
                                      ),
                                      title: Text(step.strategyName),
                                      subtitle: Text(
                                        'Row ${step.row + 1}, Col ${step.col + 1} -> Digit ${step.value}',
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: sdkString),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Solution SDK string copied to clipboard!',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy_rounded),
                              label: const Text('COPY SDK'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                final html = PdfExporter.generatePrintableHtml(
                                  board: widget.board,
                                  solvedBoard: solveResult.solvedBoard,
                                  title: 'Custom Sudoku Answer Key Sheet',
                                  difficulty: 'Custom Matrix',
                                );
                                Clipboard.setData(ClipboardData(text: html));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Printable HTML worksheet copied to clipboard!',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.picture_as_pdf_rounded),
                              label: const Text('EXPORT WORKSHEET'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
