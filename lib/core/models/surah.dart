enum RevelationType { meccan, medinan }

/// Represents one of the 114 chapters of the Quran.
class Surah {
  final int id;
  final String nameAr;
  final String nameEn;
  final String nameEnTranslation;
  final int ayahCount;
  final RevelationType revelationType;

  const Surah({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.nameEnTranslation,
    required this.ayahCount,
    required this.revelationType,
  });
}
