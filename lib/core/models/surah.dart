import 'package:flutter/widgets.dart';
import '../data/surah_translations.dart';

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

  /// Returns the localized meaning of the Surah name according to the active [BuildContext]'s locale.
  String localizedTranslation(BuildContext context) {
    final langCode = Localizations.localeOf(context).languageCode;
    return localizedTranslationForLang(langCode);
  }

  /// Returns the localized meaning of the Surah name for a specific [langCode].
  String localizedTranslationForLang(String langCode) {
    if (langCode == 'ar') {
      return 'سورة $nameAr';
    }
    return SurahTranslations.getTranslation(id, langCode) ?? nameEnTranslation;
  }
}

