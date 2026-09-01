import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ViewMode { list, mosaic }

/// Manages the surah list view mode (list vs mosaic grid).
/// Persists the user's preference across app restarts.
class ViewModeProvider extends ChangeNotifier {
  static const _key = 'surah_view_mode';

  ViewMode _mode = ViewMode.list;
  ViewMode get mode => _mode;

  ViewModeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    if (stored == 'mosaic') {
      _mode = ViewMode.mosaic;
      notifyListeners();
    }
  }

  void toggle() {
    _mode = _mode == ViewMode.list ? ViewMode.mosaic : ViewMode.list;
    notifyListeners();
    _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _mode == ViewMode.mosaic ? 'mosaic' : 'list');
  }
}
