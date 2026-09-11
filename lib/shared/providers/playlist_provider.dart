import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/playlist_item.dart';
import '../../core/models/surah.dart';
import '../../core/models/reciter.dart';
import '../../core/models/audio_api_source.dart';
import '../../core/data/mock_data.dart';
import '../../core/services/api_service.dart';
import 'settings_provider.dart';

/// Manages the user's playlist and fetches reciters.
class PlaylistProvider extends ChangeNotifier {
  static const String _favPrefKey = 'favorite_reciter_ids';
  static const String _pinPrefKey = 'pinned_reciter_ids';

  final ApiService _apiService;

  List<Reciter> _reciters = [];
  bool _isLoadingReciters = false;
  int? _selectedReciterId;

  Set<int> _favoriteReciterIds = {};
  List<int> _pinnedReciterIds = [];

  final List<PlaylistItem> _items = [];
  Set<AudioApiSource>? _lastKnownSources;

  List<Reciter> get reciters => List.unmodifiable(_reciters);
  bool get isLoadingReciters => _isLoadingReciters;
  int? get selectedReciterId => _selectedReciterId;
  List<PlaylistItem> get items => List.unmodifiable(_items);

  Set<int> get favoriteReciterIds => Set.unmodifiable(_favoriteReciterIds);
  List<int> get pinnedReciterIds => List.unmodifiable(_pinnedReciterIds);

  List<Reciter> get pinnedReciters {
    final list = <Reciter>[];
    for (final id in _pinnedReciterIds) {
      try {
        final r = _reciters.firstWhere((element) => element.id == id);
        list.add(r);
      } catch (_) {}
    }
    return list;
  }

  bool isFavorite(int reciterId) => _favoriteReciterIds.contains(reciterId);
  bool isPinned(int reciterId) => _pinnedReciterIds.contains(reciterId);

  Reciter? get selectedReciter {
    if (_selectedReciterId == null || _reciters.isEmpty) return null;
    try {
      return _reciters.firstWhere((r) => r.id == _selectedReciterId);
    } catch (_) {
      return _reciters.first;
    }
  }

  PlaylistProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService() {
    _loadPreferences();
    // Note: _fetchReciters() is NOT called here.
    // It will be triggered by updateSettingsProvider() once settings are available,
    // ensuring disabled APIs are respected from the very first fetch.
  }

  void updateSettingsProvider(SettingsProvider settings) {
    // Wait until settings are loaded from SharedPreferences.
    // SettingsProvider.notifyListeners() is called once loaded, which
    // re-triggers this proxy update with the correct saved values.
    if (!settings.isLoaded) return;

    final newSources = settings.activeApiSources;
    if (_lastKnownSources == null ||
        !_setEquals(_lastKnownSources!, newSources)) {
      _lastKnownSources = Set.from(newSources);
      _fetchReciters(newSources);
    }
  }

  bool _setEquals<T>(Set<T> a, Set<T> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favList = prefs.getStringList(_favPrefKey) ?? [];
      final pinList = prefs.getStringList(_pinPrefKey) ?? [];

      _favoriteReciterIds = favList
          .map((e) => int.tryParse(e))
          .whereType<int>()
          .toSet();

      _pinnedReciterIds = pinList
          .map((e) => int.tryParse(e))
          .whereType<int>()
          .take(3)
          .toList();

      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggleFavoriteReciter(int reciterId) async {
    if (_favoriteReciterIds.contains(reciterId)) {
      _favoriteReciterIds.remove(reciterId);
    } else {
      _favoriteReciterIds.add(reciterId);
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _favPrefKey,
        _favoriteReciterIds.map((id) => id.toString()).toList(),
      );
    } catch (_) {}
  }

  Future<bool> togglePinReciter(int reciterId) async {
    if (_pinnedReciterIds.contains(reciterId)) {
      _pinnedReciterIds.remove(reciterId);
    } else {
      if (_pinnedReciterIds.length >= 3) {
        return false; // Reached limit of 3
      }
      _pinnedReciterIds.add(reciterId);
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _pinPrefKey,
        _pinnedReciterIds.map((id) => id.toString()).toList(),
      );
    } catch (_) {}

    return true;
  }

  Future<void> _fetchReciters([Set<AudioApiSource>? sources]) async {
    _isLoadingReciters = true;
    notifyListeners();

    _reciters = await _apiService.fetchReciters(enabledSources: sources);

    if (_reciters.isNotEmpty) {
      if (_selectedReciterId == null ||
          !_reciters.any((r) => r.id == _selectedReciterId)) {
        _selectedReciterId = _reciters.first.id;
      }
    } else {
      _selectedReciterId = null;
    }

    _isLoadingReciters = false;
    notifyListeners();
  }

  Future<void> refreshReciters() async {
    await _fetchReciters(_lastKnownSources);
  }

  bool containsSurah(int surahId) =>
      _items.any((item) => item.surahId == surahId);

  void selectReciter(int reciterId) {
    _selectedReciterId = reciterId;
    notifyListeners();
  }

  /// Ensures a surah is in the playlist. Returns the index of the surah in the playlist.
  int ensureSurahInPlaylist(int surahId) {
    if (_selectedReciterId == null) {
      if (_reciters.isNotEmpty) {
        _selectedReciterId = _reciters.first.id;
      } else {
        _selectedReciterId = 1;
      }
    }

    int existingIndex = indexOfSurah(surahId);
    if (existingIndex != -1) {
      return existingIndex;
    }

    _items.add(PlaylistItem(
      surahId: surahId,
      reciterId: _selectedReciterId!,
    ));
    notifyListeners();
    return _items.length - 1;
  }

  void addSurah(int surahId) {
    ensureSurahInPlaylist(surahId);
  }

  int addSurahs(Iterable<int> surahIds) {
    if (_selectedReciterId == null) {
      if (_reciters.isNotEmpty) {
        _selectedReciterId = _reciters.first.id;
      } else {
        _selectedReciterId = 1;
      }
    }

    int addedCount = 0;
    for (final id in surahIds) {
      if (!containsSurah(id)) {
        _items.add(PlaylistItem(
          surahId: id,
          reciterId: _selectedReciterId!,
        ));
        addedCount++;
      }
    }
    if (addedCount > 0) {
      notifyListeners();
    }
    return addedCount;
  }

  void addAllSurahs() {
    addSurahs(MockData.surahs.map((s) => s.id));
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
