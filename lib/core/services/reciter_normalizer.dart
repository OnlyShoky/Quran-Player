/// Utility for normalizing, deduplicating, and standardizing Quran reciter names.
class ReciterNormalizer {
  /// Clean honorifics, titles, brackets, and extra descriptions from raw reciter names.
  static String cleanRawName(String raw) {
    var name = raw;

    // Remove text inside parentheses / brackets if it's metadata
    name = name.replaceAll(RegExp(r'\s*\(.*?\)', caseSensitive: false), ' ');
    name = name.replaceAll(RegExp(r'\s*\[.*?\]', caseSensitive: false), ' ');

    // Remove titles & honorifics
    final titlePattern = RegExp(
      r'^(Dr\.|Dr|Sheikh|Shaykh|Shaikh|Qari|Imam|Ustadz|Ustadh|Al-Qari|Al-Shaykh|Reciter)\s+',
      caseSensitive: false,
    );
    name = name.replaceAll(titlePattern, '').trim();

    // Replace special apostrophes or backticks
    name = name.replaceAll('`', '');
    name = name.replaceAll("'", '');

    // Replace multiple spaces with a single space
    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();
    return name;
  }

  /// Generates a normalized match key for deduplication and matching across APIs.
  static String getMatchKey(String rawName) {
    var clean = cleanRawName(rawName).toLowerCase();

    // Remove diacritics/accents
    clean = _removeDiacritics(clean);

    // Replace numbers and special transliteration symbols
    clean = clean.replaceAll('3', 'a');
    clean = clean.replaceAll('`', '');
    clean = clean.replaceAll("'", '');
    clean = clean.replaceAll('"', '');
    clean = clean.replaceAll('-', ' ');
    clean = clean.replaceAll('_', ' ');

    // Normalize standard word variants
    clean = clean.replaceAll(RegExp(r'\babdel\b|\babdur\b|\babdul\b'), 'abdul');
    clean = clean.replaceAll(RegExp(r'\bash\b|\bal\b|\bas\b|\bat\b|\baz\b|\ban\b|\bel\b|\bar\b|\bad\b|\bath\b'), '');

    // Phonetic standardizations
    clean = clean.replaceAll('y', 'i');
    clean = clean.replaceAll('ee', 'i');
    clean = clean.replaceAll('oo', 'u');
    clean = clean.replaceAll('ou', 'u');
    clean = clean.replaceAll('aa', 'a');

    // Keep only lowercase letters
    clean = clean.replaceAll(RegExp(r'[^a-z]'), '');

    // Deduplicate repeated consecutive consonants (e.g. ss -> s, dd -> d, mm -> m)
    clean = clean.replaceAll(RegExp(r'([a-z])\1+'), r'$1');

    return clean;
  }

  /// Canonical definitions mapped by their normalized match keys
  static final Map<String, String> _canonicalMap = _buildCanonicalMap();

  static Map<String, String> _buildCanonicalMap() {
    final definitions = <String, List<String>>{
      'Abdul Rahman Al-Sudais': [
        'Abdul Rahman Al-Sudais',
        'Abdur-Rahman as-Sudais',
        'Abdulrahman Al-Sudais',
        'Abdel Rahman as-Sudais',
        'Al Sudais',
        'Sudais',
      ],
      'Saud Al-Shuraim': [
        'Saud Al-Shuraim',
        'Sa`ud ash-Shuraym',
        'Saood ash-Shuraym',
        'Saood Ash-Shuraym',
        'Shuraim',
        'Shuraym',
      ],
      'Mishary Rashid Alafasy': [
        'Mishary Rashid Alafasy',
        'Mishari Rashid al-`Afasy',
        'Mishaari Raashid Al-Afaasee',
        'Mishari Alafasy',
        'Mishary Alafasy',
        'Alafasy',
      ],
      'Abdul Basit Abdul Samad': [
        'Abdul Basit Abdul Samad',
        'Abdul Basit Abdus-Samad',
        'AbdulBaset AbdulSamad',
        'Abdelbasset Abdelsamad',
        'Abdul Basit',
        'Abdul Samad',
      ],
      'Mahmoud Khalil Al-Husary': [
        'Mahmoud Khalil Al-Husary',
        'Mahmoud Khalil Al-Husari',
        'Mahmoud Al-Husary',
        'Khalil Al-Husary',
        'Al-Husari',
        'Al-Husary',
        'Husary',
        'Husari',
        'Hussary',
      ],
      'Mohamed Siddiq Al-Minshawi': [
        'Mohamed Siddiq Al-Minshawi',
        'Muhammad Siddiq al-Minshawi',
        'Mohamed Siddiq el-Minshawi',
        'Siddiq Al-Minshawi',
        'Minshawi',
        'Minshawy',
      ],
      'Ahmed Al-Ajmi': [
        'Ahmed Al-Ajmi',
        'Ahmed al-Ajami',
        'Ahmed ibn Ali al-Ajamy',
        'Ahmed al-Ajmy',
        'Ajmi',
        'Ajami',
        'Ajamy',
      ],
      'Saad Al-Ghamdi': [
        'Saad Al-Ghamdi',
        'Saad el-Ghamidi',
        'Saad Ghamdi',
        'Ghamdi',
        'Ghamidi',
      ],
      'Maher Al-Muaiqly': [
        'Maher Al-Muaiqly',
        'Maher al-Meaqli',
        'Maher Muaiqly',
        'Al-Muaiqly',
        'Muaiqly',
      ],
      'Abu Bakr Al-Shatri': [
        'Abu Bakr Al-Shatri',
        'Abu Bakr ash-Shaatree',
        'Abu Bakr Shaatree',
        'Shatri',
        'Shaatree',
      ],
      'Yasser Al-Dosari': [
        'Yasser Al-Dosari',
        'Yasser ad-Dossari',
        'Yasser ad-Dussary',
        'Yasser Dossari',
      ],
      'Abdullah Awad Al-Juhani': [
        'Abdullah Awad Al-Juhani',
        'Abdullah Awad al-Juhanee',
        'Abdullaah 3awwaad al-Juhaynee',
        'Abdullah al-Juhani',
        'Al-Juhani',
        'Juhani',
      ],
      'Abdullah Basfar': [
        'Abdullah Basfar',
        'Abdullaah Basfar',
        'Basfar',
      ],
      'Ali Al-Hudhaify': [
        'Ali Al-Hudhaify',
        'Ali Abdur-Rahman al-Huthaify',
        'Ali al-Huthaify',
        'Ali Huthaify',
        'Al-Hudhaify',
        'Al-Huthaify',
        'Hudhaify',
        'Huthaify',
      ],
      'Hani Al-Rifai': [
        'Hani Al-Rifai',
        'Hani ar-Rifai',
        'Hani Rifai',
        'Al-Rifai',
      ],
      'Nasser Al-Qatami': [
        'Nasser Al-Qatami',
        'Nasser al-Qatamy',
        'Qatami',
      ],
      'Salah Al-Budair': [
        'Salah Al-Budair',
        'Salah al-Bedair',
        'Budair',
      ],
      'Mohamed Al-Tablawi': [
        'Mohamed Al-Tablawi',
        'Mohamed Tablawi',
        'Tablawi',
      ],
      'Mahmoud Ali Al-Banna': [
        'Mahmoud Ali Al-Banna',
        'Mahmoud el-Banna',
        'Al-Banna',
        'Banna',
      ],
      'Muhammad Ayyub': [
        'Muhammad Ayyub',
        'Muhammad Ayyoub',
        'Mohamed Ayoub',
        'Ayyub',
      ],
      'Muhammad Jibreel': [
        'Muhammad Jibreel',
        'Mohamed Jibreel',
        'Jibreel',
      ],
      'Idrees Abkar': [
        'Idrees Abkar',
        'Idris Abkar',
      ],
      'Khalid Al-Jalil': [
        'Khalid Al-Jalil',
        'Khaled al-Jaleel',
      ],
      'Fares Abbad': [
        'Fares Abbad',
        'Faris Abbad',
      ],
      'Bandar Baleela': [
        'Bandar Baleela',
        'Bandar Balila',
      ],
      'Ibrahim Al-Akhdar': [
        'Ibrahim Al-Akhdar',
        'Ibrahim Akhdar',
      ],
      'Muhammad Al-Luhaidan': [
        'Muhammad Al-Luhaidan',
        'Muhammad Luhaidan',
      ],
      'Abdul Aziz Al-Zahrani': [
        'Abdul Aziz az-Zahrani',
        'Abdul Aziz Al-Zahrani',
      ],
      'Abdullah Al-Matrood': [
        'Abdullah Al-Matrood',
        'Abdullah Matrood',
      ],
      'Abdullah Al-Khulaifi': [
        'Abdullah Al-Khulaifi',
        'Abdullah Khulaifi',
      ],
      'Abdur-Rasheed Sufi': [
        'Abdur-Rasheed Sufi',
        'Abdul Rasheed Sufi',
      ],
    };

    final map = <String, String>{};
    for (final entry in definitions.entries) {
      final canonical = entry.key;
      for (final variant in entry.value) {
        final k = getMatchKey(variant);
        if (k.isNotEmpty) {
          map[k] = canonical;
        }
      }
    }
    return map;
  }

  /// Returns the cleaned, standardized canonical English name for a given raw name.
  static String getCanonicalName(String rawName) {
    final cleaned = cleanRawName(rawName);
    final key = getMatchKey(rawName);

    // 1. Direct match in canonical dictionary
    if (_canonicalMap.containsKey(key)) {
      return _canonicalMap[key]!;
    }

    // 2. Check if key contains canonical key or vice versa (for multi-part variants)
    for (final entry in _canonicalMap.entries) {
      if (entry.key.length >= 5) {
        if (key.contains(entry.key) || entry.key.contains(key)) {
          return entry.value;
        }
      }
    }

    // 3. Fallback: Format cleaned name with proper Title Case
    return _formatNameTitleCase(cleaned);
  }

  /// Capitalize words properly
  static String _formatNameTitleCase(String name) {
    if (name.isEmpty) return name;
    final words = name.split(' ');
    final result = <String>[];

    for (var w in words) {
      if (w.isEmpty) continue;
      if (w.contains('-')) {
        final subParts = w.split('-');
        final formattedSubs = subParts.map((s) {
          if (s.isEmpty) return '';
          if (s.toLowerCase() == 'al' || s.toLowerCase() == 'as' || s.toLowerCase() == 'el') {
            return 'Al';
          }
          return s[0].toUpperCase() + s.substring(1).toLowerCase();
        }).toList();
        result.add(formattedSubs.join('-'));
      } else {
        if (w.toLowerCase() == 'al' || w.toLowerCase() == 'el') {
          result.add('Al');
        } else if (w.toLowerCase() == 'bin' || w.toLowerCase() == 'ibn') {
          result.add('bin');
        } else {
          result.add(w[0].toUpperCase() + w.substring(1).toLowerCase());
        }
      }
    }

    return result.join(' ');
  }

  static String _removeDiacritics(String str) {
    var s = str;
    s = s.replaceAll(RegExp(r'[āáàâäã]'), 'a');
    s = s.replaceAll(RegExp(r'[ēéèêë]'), 'e');
    s = s.replaceAll(RegExp(r'[īíìîï]'), 'i');
    s = s.replaceAll(RegExp(r'[ōóòôöõ]'), 'o');
    s = s.replaceAll(RegExp(r'[ūúùûü]'), 'u');
    s = s.replaceAll(RegExp(r'[ţṯ]'), 't');
    s = s.replaceAll(RegExp(r'[şšś]'), 's');
    s = s.replaceAll(RegExp(r'[ḑđ]'), 'd');
    s = s.replaceAll(RegExp(r'[z̧żž]'), 'z');
    s = s.replaceAll(RegExp(r'[ḥẖ]'), 'h');
    return s;
  }
}
