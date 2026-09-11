import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/audio_api_source.dart';

enum PlaybackCompletionAction { next, repeat, stop }

class SettingsProvider extends ChangeNotifier {
  static const _themeKey = 'app_theme_mode';
  static const _localeKey = 'app_locale';
  static const _playbackKey = 'app_playback_completion';
  static const _activeSourcesKey = 'app_active_audio_sources';
  static const _showApiSourceInPlayerKey = 'show_api_source_in_player';

  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale; // null indicates system default
  PlaybackCompletionAction _playbackCompletion = PlaybackCompletionAction.next;
  Set<AudioApiSource> _activeApiSources = {
    AudioApiSource.mp3Quran,
    AudioApiSource.quranicAudio,
    AudioApiSource.alQuranCloud,
  };
  bool _showApiSourceInPlayer = true;
  bool _isLoaded = false;

  ThemeMode get themeMode => _themeMode;
  Locale? get locale => _locale;
  PlaybackCompletionAction get playbackCompletion => _playbackCompletion;
  Set<AudioApiSource> get activeApiSources => Set.unmodifiable(_activeApiSources);
  bool get showApiSourceInPlayer => _showApiSourceInPlayer;
  bool get isLoaded => _isLoaded;

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    // Theme Mode
    final themeStr = prefs.getString(_themeKey);
    if (themeStr == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeStr == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }

    // Locale
    final langStr = prefs.getString(_localeKey);
    if (langStr != null && langStr.isNotEmpty && langStr != 'system') {
      _locale = Locale(langStr);
    } else {
      _locale = null; // system default
    }

    // Playback completion
    final pbStr = prefs.getString(_playbackKey);
    if (pbStr == 'repeat') {
      _playbackCompletion = PlaybackCompletionAction.repeat;
    } else if (pbStr == 'stop') {
      _playbackCompletion = PlaybackCompletionAction.stop;
    } else {
      _playbackCompletion = PlaybackCompletionAction.next;
    }

    // Active Audio API Sources
    final sourcesList = prefs.getStringList(_activeSourcesKey);
    if (sourcesList != null && sourcesList.isNotEmpty) {
      final parsed = sourcesList
            .map((id) => AudioApiSource.fromId(id))
            .whereType<AudioApiSource>()
            .toSet();
      if (parsed.isNotEmpty) {
        _activeApiSources = parsed;
      }
    }

    // Show active API in player
    _showApiSourceInPlayer = prefs.getBool(_showApiSourceInPlayerKey) ?? true;

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    switch (mode) {
      case ThemeMode.light:
        await prefs.setString(_themeKey, 'light');
        break;
      case ThemeMode.dark:
        await prefs.setString(_themeKey, 'dark');
        break;
      case ThemeMode.system:
        await prefs.setString(_themeKey, 'system');
        break;
    }
  }

  Future<void> setLocale(Locale? newLocale) async {
    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (newLocale == null) {
      await prefs.setString(_localeKey, 'system');
    } else {
      await prefs.setString(_localeKey, newLocale.languageCode);
    }
  }

  Future<void> setPlaybackCompletion(PlaybackCompletionAction action) async {
    if (_playbackCompletion == action) return;
    _playbackCompletion = action;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_playbackKey, action.name);
  }

  bool isApiSourceEnabled(AudioApiSource source) =>
      _activeApiSources.contains(source);

  /// Toggle an audio API source. Returns false if attempting to disable the only active source.
  Future<bool> toggleApiSource(AudioApiSource source) async {
    if (_activeApiSources.contains(source)) {
      if (_activeApiSources.length <= 1) {
        return false; // Prevent disabling the last remaining API source
      }
      _activeApiSources.remove(source);
    } else {
      _activeApiSources.add(source);
    }

    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _activeSourcesKey,
        _activeApiSources.map((s) => s.id).toList(),
      );
    } catch (_) {}

    return true;
  }

  Future<void> setShowApiSourceInPlayer(bool value) async {
    if (_showApiSourceInPlayer == value) return;
    _showApiSourceInPlayer = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showApiSourceInPlayerKey, value);
  }
}
