import 'package:flutter/foundation.dart';
import '../../core/models/playlist_item.dart';
import '../../core/models/surah.dart';
import '../../core/data/mock_data.dart';

/// Manages the user's playlist in memory (Phase 1).
/// Phase 3 will add SharedPreferences persistence.
class PlaylistProvider extends ChangeNotifier {
  String _selectedReciterId = MockData.reciters.first.id;
  final List<PlaylistItem> _items = [];

  String get selectedReciterId => _selectedReciterId;
  List<PlaylistItem> get items => List.unmodifiable(_items);

  bool containsSurah(int surahId) =>
      _items.any((item) => item.surahId == surahId);

  void selectReciter(String reciterId) {
    _selectedReciterId = reciterId;
    notifyListeners();
  }

  void addSurah(int surahId) {
    if (!containsSurah(surahId)) {
      _items.add(PlaylistItem(
        surahId: surahId,
        reciterId: _selectedReciterId,
      ));
      notifyListeners();
    }
  }

  void addAllSurahs() {
    for (final surah in MockData.surahs) {
      if (!containsSurah(surah.id)) {
        _items.add(PlaylistItem(
          surahId: surah.id,
          reciterId: _selectedReciterId,
        ));
      }
    }
    notifyListeners();
  }

  /// Returns the removed item so callers can offer an undo.
  PlaylistItem? removeSurah(int surahId) {
    final index = _items.indexWhere((item) => item.surahId == surahId);
    if (index == -1) return null;
    final removed = _items.removeAt(index);
    notifyListeners();
    return removed;
  }

  /// Re-inserts a previously removed item at the given index.
  void undoRemove(PlaylistItem item, int index) {
    _items.insert(index.clamp(0, _items.length), item);
    notifyListeners();
  }

  int indexOfSurah(int surahId) =>
      _items.indexWhere((item) => item.surahId == surahId);

  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex--;
    final item = _items.removeAt(oldIndex);
    _items.insert(newIndex, item);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  Surah? surahById(int id) {
    try {
      return MockData.surahs.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}
