import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/audio_service.dart';
import '../data/prefs_keys.dart';

/// Manages gameplay assistance settings and their persistence.
class SettingsProvider extends ChangeNotifier {
  static final SettingsProvider instance = SettingsProvider._();

  bool _showMistakes = true;
  bool _highlightConflicts = true;
  bool _highlightIdentical = true;
  bool _endlessMode = false;
  bool _autoRemoveNotes = true;
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;

  SettingsProvider._() {
    loadSettings();
  }

  // Getters
  bool get showMistakes => _showMistakes;
  bool get highlightConflicts => _highlightConflicts;
  bool get highlightIdentical => _highlightIdentical;
  bool get endlessMode => _endlessMode;
  bool get autoRemoveNotes => _autoRemoveNotes;
  bool get soundEnabled => _soundEnabled;
  bool get hapticsEnabled => _hapticsEnabled;

  /// Loads assistance settings from SharedPreferences.
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _showMistakes = prefs.getBool(PrefsKeys.showMistakes) ?? true;
      _highlightConflicts = prefs.getBool(PrefsKeys.highlightConflicts) ?? true;
      _highlightIdentical = prefs.getBool(PrefsKeys.highlightIdentical) ?? true;
      _endlessMode = prefs.getBool(PrefsKeys.endlessMode) ?? false;
      _autoRemoveNotes = prefs.getBool(PrefsKeys.autoRemoveNotes) ?? true;
      _soundEnabled = prefs.getBool(PrefsKeys.soundEnabled) ?? true;
      _hapticsEnabled = prefs.getBool(PrefsKeys.hapticsEnabled) ?? true;

      AudioService.soundEnabled = _soundEnabled;
      AudioService.hapticsEnabled = _hapticsEnabled;

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading settings in SettingsProvider: $e');
    }
  }

  /// Updates settings values and persists them in SharedPreferences.
  Future<void> updateSettings({
    bool? showMistakes,
    bool? highlightConflicts,
    bool? highlightIdentical,
    bool? endlessMode,
    bool? autoRemoveNotes,
    bool? soundEnabled,
    bool? hapticsEnabled,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (showMistakes != null) {
        _showMistakes = showMistakes;
        await prefs.setBool(PrefsKeys.showMistakes, showMistakes);
      }
      if (highlightConflicts != null) {
        _highlightConflicts = highlightConflicts;
        await prefs.setBool(PrefsKeys.highlightConflicts, highlightConflicts);
      }
      if (highlightIdentical != null) {
        _highlightIdentical = highlightIdentical;
        await prefs.setBool(PrefsKeys.highlightIdentical, highlightIdentical);
      }
      if (endlessMode != null) {
        _endlessMode = endlessMode;
        await prefs.setBool(PrefsKeys.endlessMode, endlessMode);
      }
      if (autoRemoveNotes != null) {
        _autoRemoveNotes = autoRemoveNotes;
        await prefs.setBool(PrefsKeys.autoRemoveNotes, autoRemoveNotes);
      }
      if (soundEnabled != null) {
        _soundEnabled = soundEnabled;
        AudioService.soundEnabled = soundEnabled;
        await prefs.setBool(PrefsKeys.soundEnabled, soundEnabled);
      }
      if (hapticsEnabled != null) {
        _hapticsEnabled = hapticsEnabled;
        AudioService.hapticsEnabled = hapticsEnabled;
        await prefs.setBool(PrefsKeys.hapticsEnabled, hapticsEnabled);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating settings in SettingsProvider: $e');
    }
  }
}
