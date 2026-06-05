import 'package:flutter/material.dart';
import '../../providers/sudoku_provider.dart';

/// A premium, Material 3 bottom sheet to customize gameplay assistance settings.
class SettingsSheet extends StatelessWidget {
  final SudokuGameProvider provider;

  const SettingsSheet({super.key, required this.provider});

  static void show(BuildContext context, SudokuGameProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SettingsSheet(provider: provider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: AnimatedBuilder(
        animation: provider,
        builder: (context, _) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Indicator Bar
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.4,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Gameplay Settings',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Switch 1: Show Mistakes Instantly
                _buildSettingTile(
                  context,
                  icon: Icons.error_outline_rounded,
                  title: 'Show Mistakes Instantly',
                  description:
                      'Validate entries and mark wrong numbers in red immediately.',
                  value: provider.showMistakes,
                  onChanged: (val) =>
                      provider.updateSettings(showMistakes: val),
                ),
                const SizedBox(height: 16),

                // Switch 2: Highlight Conflicting Cells
                _buildSettingTile(
                  context,
                  icon: Icons.grid_view_rounded,
                  title: 'Highlight Conflicting Cells',
                  description:
                      'Highlight row, column, and box related to the selected cell.',
                  value: provider.highlightConflicts,
                  onChanged: (val) =>
                      provider.updateSettings(highlightConflicts: val),
                ),
                const SizedBox(height: 16),

                // Switch 3: Highlight Identical Numbers
                _buildSettingTile(
                  context,
                  icon: Icons.filter_9_plus_rounded,
                  title: 'Highlight Identical Numbers',
                  description:
                      'Highlight all cells displaying the same digit as the selected cell.',
                  value: provider.highlightIdentical,
                  onChanged: (val) =>
                      provider.updateSettings(highlightIdentical: val),
                ),
                const SizedBox(height: 16),

                // Switch 4: Endless Mode
                _buildSettingTile(
                  context,
                  icon: Icons.all_inclusive_rounded,
                  title: 'Endless Mode (No Mistakes Limit)',
                  description:
                      'Play without losing the game after committing 3 mistakes.',
                  value: provider.endlessMode,
                  onChanged: (val) => provider.updateSettings(endlessMode: val),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Switch.adaptive(value: value, onChanged: onChanged),
      ],
    );
  }
}
