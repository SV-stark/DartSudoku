import 'package:flutter/material.dart';
import '../theme.dart';

/// A custom input keyboard and tool panel.
class SudokuNumpad extends StatelessWidget {
  final Function(int number) onNumberTap;
  final VoidCallback onEraseTap;

  // Optional parameters for play mode controls
  final VoidCallback? onUndoTap;
  final VoidCallback? onNotesTap;
  final VoidCallback? onHintTap;
  final bool notesModeActive;
  final bool canUndo;

  const SudokuNumpad({
    super.key,
    required this.onNumberTap,
    required this.onEraseTap,
    this.onUndoTap,
    this.onNotesTap,
    this.onHintTap,
    this.notesModeActive = false,
    this.canUndo = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasExtraTools =
        onUndoTap != null || onNotesTap != null || onHintTap != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasExtraTools) ...[_buildToolRow(), const SizedBox(height: 20)],
        _buildNumberGrid(),
      ],
    );
  }

  Widget _buildToolRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Undo Button
        if (onUndoTap != null)
          _buildToolButton(
            icon: Icons.undo_rounded,
            label: 'Undo',
            onTap: canUndo ? onUndoTap : null,
            isActive: false,
            color: canUndo ? AppTheme.neonCyan : Colors.white.withOpacity(0.2),
          ),

        // Erase Button
        _buildToolButton(
          icon: Icons.backspace_rounded,
          label: 'Erase',
          onTap: onEraseTap,
          isActive: false,
          color: AppTheme.neonRed,
        ),

        // Notes Mode Button
        if (onNotesTap != null)
          _buildToolButton(
            icon: notesModeActive ? Icons.edit_rounded : Icons.edit_off_rounded,
            label: 'Notes',
            onTap: onNotesTap,
            isActive: notesModeActive,
            color: AppTheme.neonViolet,
          ),

        // Hint Button
        if (onHintTap != null)
          _buildToolButton(
            icon: Icons.lightbulb_rounded,
            label: 'Hint',
            onTap: onHintTap,
            isActive: false,
            color: AppTheme.neonAmber,
          ),
      ],
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required bool isActive,
    required Color color,
  }) {
    final Color buttonColor = isActive ? color : color.withOpacity(0.15);
    final Color iconColor = isActive ? AppTheme.backgroundColor : color;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: buttonColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: onTap != null ? color : Colors.white.withOpacity(0.1),
                width: 1.5,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Icon(icon, size: 24, color: iconColor),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: onTap != null
                ? Colors.white.withOpacity(0.8)
                : Colors.white.withOpacity(0.3),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildNumberGrid() {
    // Laying out 1 to 9 in a row structure or grid structure
    // Standard layouts: 1-9 in a 3x3 layout or a row
    // Let's do a 3x3 grid but stylized as glassmorphic keys!
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
        return GestureDetector(
          onTap: () => onNumberTap(number),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceGlassColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.neonIndigo.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
