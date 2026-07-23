import 'package:flutter/services.dart';

/// Audio and Haptic feedback service for DartSudoku.
class AudioService {
  static bool soundEnabled = true;
  static bool hapticsEnabled = true;

  /// Plays a subtle haptic tap on numeric input or cell selection.
  static void playCellSelect() {
    if (hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
    _playSound(SystemSoundType.click);
  }

  /// Plays a distinct feedback sound when placing a valid number.
  static void playNumberEnter() {
    if (hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
    _playSound(SystemSoundType.click);
  }

  /// Plays a note toggle feedback.
  static void playNoteToggle() {
    if (hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  /// Plays an error alert when a mistake is made.
  static void playError() {
    if (hapticsEnabled) {
      HapticFeedback.vibrate();
    }
    _playSound(SystemSoundType.alert);
  }

  /// Plays a hint reveal cue.
  static void playHint() {
    if (hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
    _playSound(SystemSoundType.click);
  }

  /// Plays victory fanfare feedback on game completion.
  static void playVictory() {
    if (hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }
    _playSound(SystemSoundType.click);
  }

  static void _playSound(SystemSoundType soundType) {
    if (soundEnabled) {
      SystemSound.play(soundType);
    }
  }
}
