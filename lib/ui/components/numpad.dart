import 'package:flutter/material.dart';

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
          const SizedBox(height: 16),
        ],
        _buildNumberGrid(context),
      ],
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
            onTap: canUndo ? onUndoTap : null,
            isActive: false,
            color: Theme.of(context).colorScheme.primary,
          ),

        // Redo Button
        if (onRedoTap != null)
          _buildToolButton(
            context,
            icon: Icons.redo_rounded,
            label: 'Redo',
            onTap: canRedo ? onRedoTap : null,
            isActive: false,
            color: Theme.of(context).colorScheme.primary,
          ),

        // Erase Button
        _buildToolButton(
          context,
          icon: Icons.backspace_rounded,
          label: 'Erase',
          onTap: onEraseTap,
          isActive: false,
          color: Theme.of(context).colorScheme.error,
        ),

        // Notes Mode Button
        if (onNotesTap != null)
          _buildToolButton(
            context,
            icon: notesModeActive ? Icons.edit_rounded : Icons.edit_off_rounded,
            label: 'Notes',
            onTap: onNotesTap,
            isActive: notesModeActive,
            color: Theme.of(context).colorScheme.secondary,
          ),

        // Hint Button
        if (onHintTap != null)
          _buildToolButton(
            context,
            icon: Icons.lightbulb_rounded,
            label: 'Hint',
            onTap: onHintTap,
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
              onTap: () => onNumberTap(number),
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
