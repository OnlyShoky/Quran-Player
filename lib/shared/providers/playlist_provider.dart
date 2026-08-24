import 'package:flutter/foundation.dart';
import '../../core/models/playlist_item.dart';
import '../../core/models/surah.dart';
import '../../core/models/reciter.dart';
import '../../core/data/mock_data.dart';
import '../../core/services/api_service.dart';

/// Manages the user's playlist and fetches reciters.
class PlaylistProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Reciter> _reciters = [];
  bool _isLoadingReciters = true;
  int? _selectedReciterId;

  final List<PlaylistItem> _items = [];

  List<Reciter> get reciters => List.unmodifiable(_reciters);
  bool get isLoadingReciters => _isLoadingReciters;
  int? get selectedReciterId => _selectedReciterId;
  List<PlaylistItem> get items => List.unmodifiable(_items);

  PlaylistProvider() {
    _fetchReciters();
  }

  Future<void> _fetchReciters() async {
    _isLoadingReciters = true;
    notifyListeners();

    _reciters = await _apiService.fetchReciters();

    if (_reciters.isNotEmpty) {
      _selectedReciterId = _reciters.first.id;
    }

    _isLoadingReciters = false;
    notifyListeners();
  }

  bool containsSurah(int surahId) =>
      _items.any((item) => item.surahId == surahId);

  void selectReciter(int reciterId) {
    _selectedReciterId = reciterId;
    notifyListeners();
  }

  void addSurah(int surahId) {
    if (_selectedReciterId == null) return;
    
    if (!containsSurah(surahId)) {
      _items.add(PlaylistItem(
        surahId: surahId,
        reciterId: _selectedReciterId!,
      ));
      notifyListeners();
    }
  }

  void addAllSurahs() {
    if (_selectedReciterId == null) return;

    for (final surah in MockData.surahs) {
      if (!containsSurah(surah.id)) {
        _items.add(PlaylistItem(
          surahId: surah.id,
          reciterId: _selectedReciterId!,
        ));
      }
    }
    notifyListeners();
  }

  PlaylistItem? removeSurah(int surahId) {
    final index = _items.indexWhere((item) => item.surahId == surahId);
    if (index == -1) return null;
    final removed = _items.removeAt(index);
    notifyListeners();
    return removed;
  }

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
