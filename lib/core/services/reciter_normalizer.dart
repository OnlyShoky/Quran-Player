/// Utility for normalizing, deduplicating, and standardizing Quran reciter names.
class ReciterNormalizer {
  /// Clean honorifics, titles, brackets, and extra descriptions from raw reciter names.
  static String cleanRawName(String raw) {
    var name = raw;

    // Remove text inside parentheses / brackets if it's metadata
    name = name.replaceAll(RegExp(r'\s*[\(\[].*?[\)\]]', caseSensitive: false), ' ');

    // Remove titles & honorifics
    final titlePattern = RegExp(
      r'^(Dr\.|Dr|Sheikh|Shaykh|Shaikh|Qari|Imam|Ustadz|Ustadh|Al-Qari|Al-Shaykh|Reciter)\s+',
      caseSensitive: false,
    );
    name = name.replaceAll(titlePattern, '').trim();

    // Remove special apostrophes, backticks, quotes
    name = name.replaceAll('`', '');
    name = name.replaceAll("'", '');
    name = name.replaceAll('"', '');

    // Replace multiple spaces with a single space
    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();
    return name;
  }

  /// Generates a normalized match key for deduplication and matching across APIs.
  static String getMatchKey(String rawName) {
    var clean = cleanRawName(rawName).toLowerCase();

    // Remove diacritics/accents
    clean = _removeDiacritics(clean);

    // Replace numbers and symbols
    clean = clean.replaceAll('3', 'a');
    clean = clean.replaceAll('-', ' ');
    clean = clean.replaceAll('_', ' ');

    // Split concatenated Arabic articles: e.g. "alsudaes" -> "sudaes", "aldosari" -> "dosari"
    clean = clean.replaceAllMapped(
      RegExp(r'\b(al|el|ash|as|at|az|an|ar|ad|ath)([a-z]{3,})\b'),
      (m) => m[2]!,
    );
    clean = clean.replaceAll(RegExp(r'\b(ash|al|as|at|az|an|el|ar|ad|ath)\b'), '');

    // Split concatenated "abdul" e.g. "abdulrahman" -> "abdul rahman"
    clean = clean.replaceAllMapped(
      RegExp(r'\b(abdel|abdur|abdul)([a-z]{3,})\b'),
      (m) => 'abdul ${m[2]!}',
    );
    clean = clean.replaceAll(RegExp(r'\babdel\b|\babdur\b|\babdul\b'), 'abdul');

    // Standardize known key variations
    clean = clean.replaceAll(RegExp(r'sudaes|sudais'), 'sudais');
    clean = clean.replaceAll(RegExp(r'shuraim|shuraym'), 'shuraim');
    clean = clean.replaceAll(RegExp(r'afasy|afasi'), 'afasy');
    clean = clean.replaceAll(RegExp(r'minshawi|minshawy|menshawy'), 'minshawi');
    clean = clean.replaceAll(RegExp(r'husary|husari|hussary'), 'husary');
    clean = clean.replaceAll(RegExp(r'ghamdi|ghamidi'), 'ghamdi');
    clean = clean.replaceAll(RegExp(r'ajmi|ajami|ajamy'), 'ajmi');
    clean = clean.replaceAll(RegExp(r'dosari|dossari|dussary'), 'dosari');
    clean = clean.replaceAll(RegExp(r'juhani|juhanee|juhaynee'), 'juhani');
    clean = clean.replaceAll(RegExp(r'basfar|basfer'), 'basfar');
    clean = clean.replaceAll(RegExp(r'hudhaify|huthaify'), 'hudhaify');
    clean = clean.replaceAll(RegExp(r'tablawi|tablawy'), 'tablawi');

    // Phonetic vowel normalizations
    clean = clean.replaceAll(RegExp(r'ee|ey|ei|ae|ai|y'), 'i');
    clean = clean.replaceAll(RegExp(r'oo|ou|o'), 'u');
    clean = clean.replaceAll('e', 'i');

    // Keep only lowercase letters
    clean = clean.replaceAll(RegExp(r'[^a-z]'), '');

    // Deduplicate repeated consecutive consonants (e.g. ss -> s, dd -> d, mm -> m)
    clean = clean.replaceAllMapped(RegExp(r'([a-z])\1+'), (m) => m[1]!);

    return clean;
  }

  /// Canonical definitions mapped by their normalized match keys
  static final Map<String, String> _canonicalMap = _buildCanonicalMap();

  static Map<String, String> _buildCanonicalMap() {
    final definitions = <String, List<String>>{
      'Abdul Rahman Al-Sudais': [
        'Abdul Rahman Al-Sudais',
        'Abdulrahman Alsudaes',
        'Abdur-Rahman as-Sudais',
        'Abdulrahman Al-Sudais',
        'Abdel Rahman as-Sudais',
        'Al Sudais',
        'Alsudaes',
        'Sudais',
        'Sudaes',
      ],
      'Saud Al-Shuraim': [
        'Saud Al-Shuraim',
        'Sa`ud ash-Shuraym',
        'Saood ash-Shuraym',
        'Saood Ash-Shuraym',
        'Saud Alshuraim',
        'Shuraim',
        'Shuraym',
      ],
      'Mishary Rashid Alafasy': [
        'Mishary Rashid Alafasy',
        'Mishari Rashid al-`Afasy',
        'Mishaari Raashid Al-Afaasee',
        'Mishari Alafasi',
        'Mishary Alafasi',
        'Mishari Alafasy',
        'Mishary Alafasy',
        'Alafasy',
        'Alafasi',
      ],
      'Abdul Basit Abdul Samad': [
        'Abdul Basit Abdul Samad',
        'Abdul Basit Abdus-Samad',
        'AbdulBaset AbdulSamad',
        'Abdulbasit Abdulsamad',
        'Abdelbasset Abdelsamad',
        'Abdul Basit',
        'Abdul Samad',
      ],
      'Mahmoud Khalil Al-Husary': [
        'Mahmoud Khalil Al-Husary',
        'Mahmoud Khalil Al-Husari',
        'Mahmoud Khaleel Al-Husary',
        'Mahmoud Khalil Al-Hussary',
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
        'Mohammed Siddiq Al-Minshawi',
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
        'Ahmed Alajmi',
        'Ajmi',
        'Ajami',
        'Ajamy',
      ],
      'Saad Al-Ghamdi': [
        'Saad Al-Ghamdi',
        'Saad el-Ghamidi',
        'Saad Ghamdi',
        'Saad Alghamdi',
        'Ghamdi',
        'Ghamidi',
      ],
      'Maher Al-Muaiqly': [
        'Maher Al-Muaiqly',
        'Maher al-Meaqli',
        'Maher Muaiqly',
        'Maher Almuaiqly',
        'Al-Muaiqly',
        'Muaiqly',
      ],
      'Abu Bakr Al-Shatri': [
        'Abu Bakr Al-Shatri',
        'Abu Bakr ash-Shaatree',
        'Abu Bakr Shaatree',
        'Shaik Abu Bakr Al Shatri',
        'Shatri',
        'Shaatree',
      ],
      'Yasser Al-Dosari': [
        'Yasser Al-Dosari',
        'Yasser ad-Dossari',
        'Yasser ad-Dussary',
        'Yasser Aldosari',
        'Yasser Dossari',
      ],
      'Abdullah Awad Al-Juhani': [
        'Abdullah Awad Al-Juhani',
        'Abdullah Awad al-Juhanee',
        'Abdullaah 3awwaad al-Juhaynee',
        'Abdullah al-Juhani',
        'Abdullah Aljuhani',
        'Al-Juhani',
        'Juhani',
      ],
      'Abdullah Basfar': [
        'Abdullah Basfar',
        'Abdullaah Basfar',
        'Abdullah Basfer',
        'Basfar',
        'Basfer',
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
        'Nasser Alqatami',
        'Qatami',
      ],
      'Salah Al-Budair': [
        'Salah Al-Budair',
        'Salah al-Bedair',
        'Salah Albudair',
        'Budair',
      ],
      'Mohamed Al-Tablawi': [
        'Mohamed Al-Tablawi',
        'Mohamed Tablawi',
        'Mohamed Altablawi',
        'Tablawi',
      ],
      'Mahmoud Ali Al-Banna': [
        'Mahmoud Ali Al-Banna',
        'Mahmood Ali Al-Bana',
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
        'Abdulaziz Az-Zahrani',
      ],
      'Abdullah Al-Matrood': [
        'Abdullah Al-Matrood',
        'Abdullah Matroud',
        'Abdullah Al-Mattrod',
      ],
      'Abdullah Al-Khulaifi': [
        'Abdullah Al-Khulaifi',
        'Abdullah Khulaifi',
      ],
      'Abdur-Rasheed Sufi': [
        'Abdur-Rasheed Sufi',
        'Abdul Rasheed Sufi',
        'Abdulrasheed Soufi',
        'Abdur-Rashid Sufi',
      ],
      'Abdul Bari Al-Thubaity': [
        'Abdul Bari ath-Thubaity',
        'AbdulBari ath-Thubaity',
        'Abdulbari Al-Thubaity',
      ],
      'Abdul Kareem Al-Hazmi': [
        'Abdul Kareem al-Hazmi',
        'AbdulKareem Al Hazmi',
        'Abdulkareem Al-Hazmi',
      ],
      'Abdul Mohsen Al-Harthy': [
        'Abdul Mohsen al-Harthy',
        'Abdulmohsin Al-Harthy',
      ],
      'Abdul Wadood Haneef': [
        'Abdul Wadood Haneef',
        'AbdulWadood Haneef',
        'AbdulWadud Haneef',
        'Abdulwadood Haneef',
      ],
      'Abdul Muhsin Al-Qasim': [
        'AbdulMuhsin al-Qasim',
        'Abdulmohsen Al-Qasim',
      ],
      'Abdullah Ali Jabir': [
        'Abdullah Ali Jabir',
        'Ali Jabir',
      ],
      'Abdullah Khayat': [
        'Abdullah Khayat',
        'Abdullah Khayyat',
      ],
      'Adil Al-Kalbani': [
        'Adil al-Kalbani',
        'Adel Kalbani',
      ],
      'Ahmad Al-Hawashi': [
        'Ahmad Al-Hawashi',
        'Ahmad al-Hawashy',
      ],
      'Ahmed Amir': [
        'Ahmed Amir',
        'Ahmed Amer',
      ],
      'Al-Hussayni Al-Azazi': [
        'Al-Hussayni Al-Azazi',
        'Alhusayni Al-Azazi',
      ],
      'Al-Ashry Omran': [
        'Al-Ashry Omran',
        'Alashri Omran',
      ],
      'Hasan Saleh': [
        'Hasan Saleh',
        'Hassan Saleh',
      ],
      'Ibrahim Al-Jibrin': [
        'Ibrahim Al-Jibrin',
        'Ibrahim Al-Jebreen',
      ],
      'Khalid Al-Qahtani': [
        'Khalid Al-Qahtani',
        'Khaled Al-Qahtani',
      ],
      'Khalid Abdul-Kafi': [
        'Khalid Abdul-Kafi',
        'Khalid Abdulkafi',
      ],
      'Maher Shakhashiro': [
        'Maher Shakhashiro',
        'Maher Shakhashero',
      ],
      'Mahmood Al-Rifai': [
        'Mahmood Al-Rifai',
        'Mahmoud al-Rifai',
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
    final key = getMatchKey(rawName);

    // 1. Direct match in canonical dictionary
    if (_canonicalMap.containsKey(key)) {
      return _canonicalMap[key]!;
    }

    // 2. Fallback: Clean and format with classical conventions
    return _formatClassicalName(cleanRawName(rawName));
  }

  /// Format an uncatalogued name using standard Islamic transliteration rules
  static String _formatClassicalName(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return s;

    // Split Abdul[X] -> Abdul [X]
    s = s.replaceAllMapped(
      RegExp(r'\b(abdel|abdur|abdul)([a-z]{3,})\b', caseSensitive: false),
      (m) => 'Abdul ${m[2]![0].toUpperCase()}${m[2]!.substring(1).toLowerCase()}',
    );

    // Split Al[X] -> Al-[X]
    s = s.replaceAllMapped(
      RegExp(r'\b(al|el)([a-z]{3,})\b', caseSensitive: false),
      (m) {
        final rest = m[2]!;
        if (rest.toLowerCase().startsWith('afas')) return 'Alafasy';
        if (rest.toLowerCase() == 'sudaes') return 'Al-Sudais';
        return 'Al-${rest[0].toUpperCase()}${rest.substring(1).toLowerCase()}';
      },
    );

    // Standard title casing
    final words = s.split(' ');
    final result = <String>[];

    for (var w in words) {
      if (w.isEmpty) continue;
      if (w.contains('-')) {
        final subParts = w.split('-');
        final formattedSubs = subParts.map((sub) {
          if (sub.isEmpty) return '';
          if (sub.toLowerCase() == 'al' || sub.toLowerCase() == 'as' || sub.toLowerCase() == 'el') {
            return 'Al';
          }
          return sub[0].toUpperCase() + sub.substring(1).toLowerCase();
        }).toList();
        result.add(formattedSubs.join('-'));
      } else {
        final lower = w.toLowerCase();
        if (lower == 'al' || lower == 'el') {
          result.add('Al');
        } else if (lower == 'bin' || lower == 'ibn') {
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
