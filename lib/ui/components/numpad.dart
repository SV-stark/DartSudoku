import 'package:flutter/material.dart';
import '../../core/services/audio_service.dart';

/// A custom input keyboard and tool panel designed with Material 3.
class SudokuNumpad extends StatelessWidget {
  final Function(int number) onNumberTap;
  final VoidCallback onEraseTap;

  // Optional parameters for play mode controls
  final VoidCallback? onUndoTap;
  final VoidCallback? onRedoTap;
  final VoidCallback? onNotesTap;
  final VoidCallback? onHintTap;
  final bool notesModeActive;
  final bool canUndo;
  final bool canRedo;
  final Map<int, int>? numberCounts;
  final int selectedColorIndex;
  final Function(int colorIndex)? onColorSelect;

  const SudokuNumpad({
    super.key,
    required this.onNumberTap,
    required this.onEraseTap,
    this.onUndoTap,
    this.onRedoTap,
    this.onNotesTap,
    this.onHintTap,
    this.notesModeActive = false,
    this.canUndo = false,
    this.canRedo = false,
    this.numberCounts,
    this.selectedColorIndex = 0,
    this.onColorSelect,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasExtraTools =
        onUndoTap != null || onNotesTap != null || onHintTap != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasExtraTools) ...[
          _buildToolRow(context),
          if (onColorSelect != null) ...[
            const SizedBox(height: 10),
            _buildColorPalette(context),
          ],
          const SizedBox(height: 14),
        ],
        _buildNumberGrid(context),
      ],
    );
  }

  Widget _buildColorPalette(BuildContext context) {
    final colors = [
      Colors.grey,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];
    final labels = ['Off', 'Blue', 'Green', 'Orange', 'Purple'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(colors.length, (idx) {
        final isSelected = selectedColorIndex == idx;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: InkWell(
            onTap: () {
              AudioService.playCellSelect();
              onColorSelect!(idx);
            },
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: Tooltip(
                message: 'Highlight ${labels[idx]}',
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: idx == 0
                        ? Theme.of(context).colorScheme.surfaceContainerHighest
                        : colors[idx],
                    shape: BoxShape.circle,
                  ),
                  child: idx == 0
                      ? Icon(
                          Icons.format_color_reset,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        )
                      : null,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }


  Widget _buildToolRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Undo Button
        if (onUndoTap != null)
          _buildToolButton(
            context,
            icon: Icons.undo_rounded,
            label: 'Undo',
            onTap: canUndo
                ? () {
                    AudioService.playCellSelect();
                    onUndoTap!();
                  }
                : null,
            isActive: false,
            color: Theme.of(context).colorScheme.primary,
          ),

        // Redo Button
        if (onRedoTap != null)
          _buildToolButton(
            context,
            icon: Icons.redo_rounded,
            label: 'Redo',
            onTap: canRedo
                ? () {
                    AudioService.playCellSelect();
                    onRedoTap!();
                  }
                : null,
            isActive: false,
            color: Theme.of(context).colorScheme.primary,
          ),

        // Erase Button
        _buildToolButton(
          context,
          icon: Icons.backspace_rounded,
          label: 'Erase',
          onTap: () {
            AudioService.playCellSelect();
            onEraseTap();
          },
          isActive: false,
          color: Theme.of(context).colorScheme.error,
        ),

        // Notes Mode Button
        if (onNotesTap != null)
          _buildToolButton(
            context,
            icon: notesModeActive ? Icons.edit_rounded : Icons.edit_off_rounded,
            label: 'Notes',
            onTap: () {
              AudioService.playNoteToggle();
              onNotesTap!();
            },
            isActive: notesModeActive,
            color: Theme.of(context).colorScheme.secondary,
          ),

        // Hint Button
        if (onHintTap != null)
          _buildToolButton(
            context,
            icon: Icons.lightbulb_rounded,
            label: 'Hint',
            onTap: () {
              AudioService.playHint();
              onHintTap!();
            },
            isActive: false,
            color: Theme.of(context).colorScheme.tertiary,
          ),
      ],
    );
  }

  Widget _buildToolButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required bool isActive,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final Color buttonColor = isActive
        ? theme.colorScheme.primaryContainer
        : (onTap != null
              ? color.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ));
    final Color iconColor = isActive
        ? theme.colorScheme.onPrimaryContainer
        : (onTap != null
              ? color
              : theme.colorScheme.onSurface.withValues(alpha: 0.3));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: label,
          button: true,
          enabled: onTap != null,
          selected: isActive,
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: buttonColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Icon(icon, size: 24, color: iconColor),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: onTap != null
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withValues(alpha: 0.35),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildNumberGrid(BuildContext context) {
    final theme = Theme.of(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        final int number = index + 1;
        final int remainingCount = numberCounts?[number] ?? 9;
        final bool isCompleted = remainingCount == 0;

        return Card(
          elevation: isCompleted ? 0 : 1,
          color: isCompleted
              ? theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                )
              : theme.colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Semantics(
            label:
                'Number $number, ${isCompleted ? "completed" : "$remainingCount remaining"}',
            button: true,
            child: InkWell(
              onTap: () {
                AudioService.playNumberEnter();
                onNumberTap(number);
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$number',
                    style: TextStyle(
                      color: isCompleted
                          ? theme.colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.25,
                            )
                          : theme.colorScheme.onSurfaceVariant,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isCompleted ? '✓' : '$remainingCount',
                    style: TextStyle(
                      color: isCompleted
                          ? Colors.green.withValues(alpha: 0.5)
                          : theme.colorScheme.primary.withValues(alpha: 0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
