import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ViewMode { list, mosaic }

/// Manages the surah list view mode (list vs mosaic grid).
/// Persists the user's preference across app restarts.
class ViewModeProvider extends ChangeNotifier {
  static const _key = 'surah_view_mode';
  static const _tutorialKey = 'has_seen_view_mode_tutorial';

  ViewMode _mode = ViewMode.list;
  ViewMode get mode => _mode;

  bool _hasSeenTutorial = true; // default true until storage is checked
  bool _isTutorialLoaded = false;
  bool get shouldShowTutorial => _isTutorialLoaded && !_hasSeenTutorial;
  bool get hasSeenTutorial => _hasSeenTutorial;

  ViewModeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    if (stored == 'mosaic') {
      _mode = ViewMode.mosaic;
    }
    _hasSeenTutorial = prefs.getBool(_tutorialKey) ?? false;
    _isTutorialLoaded = true;
    notifyListeners();
  }

  void toggle() {
    _mode = _mode == ViewMode.list ? ViewMode.mosaic : ViewMode.list;
    notifyListeners();
    _save();
  }

  Future<void> completeTutorial() async {
    if (_hasSeenTutorial) return;
    _hasSeenTutorial = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialKey, true);
  }

  Future<void> resetTutorial() async {
    _hasSeenTutorial = false;
    _isTutorialLoaded = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tutorialKey);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _mode == ViewMode.mosaic ? 'mosaic' : 'list');
  }
}
