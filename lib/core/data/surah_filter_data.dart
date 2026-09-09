/// Static mapping of Juz (1-30) to the Surah IDs contained in each Juz.
/// A Surah may appear in multiple Juz if it spans across Juz boundaries,
/// but for filtering purposes we include a Surah if any part of it is in that Juz.
abstract class SurahFilterData {
  /// Maps Juz number (1-30) to list of Surah IDs that appear in that Juz.
  static const Map<int, List<int>> juzToSurahs = {
    1: [1, 2],
    2: [2],
    3: [2, 3],
    4: [3, 4],
    5: [4],
    6: [4, 5],
    7: [5, 6],
    8: [6, 7],
    9: [7, 8],
    10: [8, 9],
    11: [9, 10, 11],
    12: [11, 12],
    13: [12, 13, 14],
    14: [15, 16],
    15: [17, 18],
    16: [18, 19, 20],
    17: [21, 22],
    18: [23, 24, 25],
    19: [25, 26, 27],
    20: [27, 28, 29],
    21: [29, 30, 31, 32, 33],
    22: [33, 34, 35, 36],
    23: [36, 37, 38, 39],
    24: [39, 40, 41],
    25: [41, 42, 43, 44, 45],
    26: [46, 47, 48, 49, 50, 51],
    27: [51, 52, 53, 54, 55, 56, 57],
    28: [58, 59, 60, 61, 62, 63, 64, 65, 66],
    29: [67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77],
    30: [78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114],
  };

  /// Maps Hizb number (1-60) to list of Surah IDs that appear in that Hizb.
  static const Map<int, List<int>> hizbToSurahs = {
    1: [1, 2],
    2: [2],
    3: [2],
    4: [2],
    5: [2, 3],
    6: [3],
    7: [3],
    8: [3, 4],
    9: [4],
    10: [4],
    11: [4, 5],
    12: [5],
    13: [5, 6],
    14: [6],
    15: [6],
    16: [7],
    17: [7],
    18: [7, 8],
    19: [8, 9],
    20: [9],
    21: [9, 10],
    22: [10, 11],
    23: [11],
    24: [11, 12],
    25: [12, 13],
    26: [13, 14],
    27: [15, 16],
    28: [16],
    29: [17],
    30: [17, 18],
    31: [18, 19],
    32: [20],
    33: [21],
    34: [22],
    35: [23, 24],
    36: [24, 25],
    37: [25, 26],
    38: [26, 27],
    39: [27, 28],
    40: [28, 29],
    41: [29, 30, 31],
    42: [31, 32, 33],
    43: [33, 34],
    44: [34, 35, 36],
    45: [36, 37],
    46: [37, 38, 39],
    47: [39, 40],
    48: [40, 41],
    49: [41, 42, 43],
    50: [43, 44, 45],
    51: [46, 47, 48],
    52: [48, 49, 50, 51],
    53: [51, 52, 53, 54],
    54: [55, 56, 57],
    55: [58, 59, 60, 61],
    56: [62, 63, 64, 65, 66],
    57: [67, 68, 69, 70, 71],
    58: [72, 73, 74, 75, 76, 77],
    59: [78, 79, 80, 81, 82, 83, 84, 85, 86],
    60: [87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114],
  };

  /// Returns the set of Surah IDs for a given Juz number.
  /// Returns null if the Juz number is invalid.
  static Set<int>? surahIdsForJuz(int juz) {
    final list = juzToSurahs[juz];
    return list?.toSet();
  }

  /// Returns the set of Surah IDs for a given Hizb number.
  /// Returns null if the Hizb number is invalid.
  static Set<int>? surahIdsForHizb(int hizb) {
    final list = hizbToSurahs[hizb];
    return list?.toSet();
  }
}
