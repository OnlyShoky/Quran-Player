import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static const supportedLocales = [
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ar'),
  ];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'Quran Player',
      'nav_surahs': 'Surahs',
      'nav_playlist': 'Playlist',
      'settings_title': 'Settings',
      'close': 'Close',
      'cancel': 'Cancel',
      'reset': 'Reset',
      'done': 'Done',
      'search_surahs': 'Search surahs…',
      'no_surahs_found': 'No surahs found',
      'reciter_label': 'Reciter',
      'change_reciter': 'Change',
      'tooltip_list_view': 'Switch to list view',
      'tooltip_mosaic_view': 'Switch to mosaic view',
      'tooltip_settings': 'Settings',
      'verses_count': '{count} Ayahs',
      'meccan': 'Meccan',
      'medinan': 'Medinan',
      'select_reciter': 'Select Reciter',
      'search_reciter': 'Search reciter…',
      'tab_all': 'All',
      'tab_favorites': 'Favorites',
      'tab_pinned': 'Pinned',
      'no_favorites': 'No favorite reciters yet',
      'no_pinned': 'No pinned reciters yet',
      'max_pins_reached': 'Maximum 3 pinned reciters allowed',
      'playlist_title': 'Playlist',
      'clear_all': 'Clear all',
      'playlist_empty_title': 'No surahs in playlist',
      'playlist_empty_subtitle': 'Add surahs to listen continuously',
      'surah_removed': 'Removed from playlist',
      'playlist_cleared': 'Playlist cleared',
      'surah_added': 'Added to playlist',
      'already_in_playlist': 'Already in playlist',
      'now_playing': 'Now Playing',
      'surah_of': 'Surah {current} of {total}',
      'error_loading_audio': 'Error loading audio',
      'play': 'Play',
      'pause': 'Pause',
      'stop': 'Stop',
      'previous': 'Previous',
      'next': 'Next',
      'tutorial_badge': '✨ VIEW TIP',
      'tutorial_title': 'Customize your view!',
      'tutorial_body_to_mosaic':
          'Tap here anytime to switch to an elegant Mosaic grid view of the Surahs.',
      'tutorial_body_to_list':
          'Tap here anytime to switch back to the classic List view.',
      'tutorial_try_mosaic': 'Try Mosaic Mode',
      'tutorial_try_list': 'Try List Mode',
      'tutorial_got_it': 'Got it!',
      'section_appearance': 'Appearance',
      'theme_mode': 'Theme Mode',
      'theme_system': 'System',
      'theme_light': 'Light',
      'theme_dark': 'Dark',
      'view_mode': 'Surah View',
      'view_list': 'List',
      'view_mosaic': 'Mosaic',
      'section_language': 'Language',
      'lang_system': 'System Default',
      'lang_en': 'English',
      'lang_es': 'Español',
      'lang_fr': 'Français',
      'lang_ar': 'العربية',
      'section_playback': 'Playback',
      'on_track_completion': 'When Surah Ends',
      'playback_next': 'Play Next Surah',
      'playback_repeat': 'Repeat Current Surah',
      'playback_stop': 'Stop Playback',
      'section_tutorial': 'Tutorial & Help',
      'reset_tutorial_title': 'Reset View Tutorial',
      'reset_tutorial_desc':
          'Show the interactive view mode coach mark again on the Surah list.',
      'reset_tutorial_success':
          'Tutorial reset! You will see it when you return to the surah list.',
      'section_about': 'About',
      'app_description': 'A minimalist, focused Holy Quran audio player.',
      'version': 'Version',
    },
    'es': {
      'app_title': 'Quran Player',
      'nav_surahs': 'Surahs',
      'nav_playlist': 'Lista',
      'settings_title': 'Configuración',
      'close': 'Cerrar',
      'cancel': 'Cancelar',
      'reset': 'Restablecer',
      'done': 'Listo',
      'search_surahs': 'Buscar surahs…',
      'no_surahs_found': 'No se encontraron surahs',
      'reciter_label': 'Recitador',
      'change_reciter': 'Cambiar',
      'tooltip_list_view': 'Cambiar a vista de lista',
      'tooltip_mosaic_view': 'Cambiar a vista de mosaico',
      'tooltip_settings': 'Configuración',
      'verses_count': '{count} aleyas',
      'meccan': 'Meca',
      'medinan': 'Medina',
      'select_reciter': 'Seleccionar recitador',
      'search_reciter': 'Buscar recitador…',
      'tab_all': 'Todos',
      'tab_favorites': 'Favoritos',
      'tab_pinned': 'Fijados',
      'no_favorites': 'Aún no tienes recitadores favoritos',
      'no_pinned': 'Sin recitadores fijados',
      'max_pins_reached': 'Máximo 3 recitadores fijados',
      'playlist_title': 'Lista de reproducción',
      'clear_all': 'Vaciar lista',
      'playlist_empty_title': 'Tu lista está vacía',
      'playlist_empty_subtitle': 'Añade surahs para reproducir en cadena',
      'surah_removed': 'Eliminada de la lista',
      'playlist_cleared': 'Lista vaciada',
      'surah_added': 'Añadida a la lista',
      'already_in_playlist': 'Ya está en la lista',
      'now_playing': 'Reproduciendo',
      'surah_of': 'Surah {current} de {total}',
      'error_loading_audio': 'Error al cargar el audio',
      'play': 'Reproducir',
      'pause': 'Pausar',
      'stop': 'Detener',
      'previous': 'Anterior',
      'next': 'Siguiente',
      'tutorial_badge': '✨ TIP DE VISTA',
      'tutorial_title': '¡Personaliza tu experiencia!',
      'tutorial_body_to_mosaic':
          'Toca aquí cuando quieras para cambiar a una elegante vista en Mosaico de las Surahs.',
      'tutorial_body_to_list':
          'Toca aquí cuando quieras para volver a la clásica vista en Lista.',
      'tutorial_try_mosaic': 'Probar modo Mosaico',
      'tutorial_try_list': 'Probar modo Lista',
      'tutorial_got_it': '¡Entendido!',
      'section_appearance': 'Apariencia',
      'theme_mode': 'Tema',
      'theme_system': 'Sistema',
      'theme_light': 'Claro',
      'theme_dark': 'Oscuro',
      'view_mode': 'Vista de surahs',
      'view_list': 'Lista',
      'view_mosaic': 'Mosaico',
      'section_language': 'Idioma',
      'lang_system': 'Predeterminado del sistema',
      'lang_en': 'English',
      'lang_es': 'Español',
      'lang_fr': 'Français',
      'lang_ar': 'العربية',
      'section_playback': 'Reproducción',
      'on_track_completion': 'Al terminar surah',
      'playback_next': 'Siguiente surah',
      'playback_repeat': 'Repetir surah actual',
      'playback_stop': 'Detener reproducción',
      'section_tutorial': 'Tutorial y ayuda',
      'reset_tutorial_title': 'Restablecer tutorial de vista',
      'reset_tutorial_desc':
          'Vuelve a mostrar la guía interactiva en la lista de surahs.',
      'reset_tutorial_success':
          '¡Tutorial restablecido! Lo verás al volver a la lista de surahs.',
      'section_about': 'Acerca de',
      'app_description':
          'Reproductor de audio minimalista y enfocado del Sagrado Corán.',
      'version': 'Versión',
    },
    'fr': {
      'app_title': 'Quran Player',
      'nav_surahs': 'Sourates',
      'nav_playlist': 'Liste',
      'settings_title': 'Paramètres',
      'close': 'Fermer',
      'cancel': 'Annuler',
      'reset': 'Réinitialiser',
      'done': 'Terminé',
      'search_surahs': 'Rechercher des sourates…',
      'no_surahs_found': 'Aucune sourate trouvée',
      'reciter_label': 'Récitateur',
      'change_reciter': 'Changer',
      'tooltip_list_view': 'Passer en vue liste',
      'tooltip_mosaic_view': 'Passer en vue mosaïque',
      'tooltip_settings': 'Paramètres',
      'verses_count': '{count} versets',
      'meccan': 'Mecquoise',
      'medinan': 'Médinoise',
      'select_reciter': 'Sélectionner un récitateur',
      'search_reciter': 'Rechercher un récitateur…',
      'tab_all': 'Tous',
      'tab_favorites': 'Favoris',
      'tab_pinned': 'Épinglés',
      'no_favorites': 'Pas encore de récitateurs favoris',
      'no_pinned': 'Aucun récitateur épinglé',
      'max_pins_reached': 'Maximum 3 récitateurs épinglés',
      'playlist_title': 'Liste de lecture',
      'clear_all': 'Tout effacer',
      'playlist_empty_title': 'Aucune sourate dans la liste',
      'playlist_empty_subtitle':
          'Ajoutez des sourates pour une écoute en continu',
      'surah_removed': 'Retirée de la liste',
      'playlist_cleared': 'Liste effacée',
      'surah_added': 'Ajoutée à la liste',
      'already_in_playlist': 'Déjà dans la liste',
      'now_playing': 'Lecture en cours',
      'surah_of': 'Sourate {current} sur {total}',
      'error_loading_audio': 'Erreur de chargement audio',
      'play': 'Lecture',
      'pause': 'Pause',
      'stop': 'Arrêter',
      'previous': 'Précédent',
      'next': 'Suivant',
      'tutorial_badge': '✨ ASTUCE D’AFFICHAGE',
      'tutorial_title': 'Personnalisez votre vue !',
      'tutorial_body_to_mosaic':
          'Appuyez ici à tout moment pour basculer vers une vue élégante en Mosaïque des sourates.',
      'tutorial_body_to_list':
          'Appuyez ici à tout moment pour revenir à la vue classique en Liste.',
      'tutorial_try_mosaic': 'Essayer le mode Mosaïque',
      'tutorial_try_list': 'Essayer le mode Liste',
      'tutorial_got_it': 'Compris !',
      'section_appearance': 'Apparence',
      'theme_mode': 'Thème',
      'theme_system': 'Système',
      'theme_light': 'Clair',
      'theme_dark': 'Sombre',
      'view_mode': 'Affichage des sourates',
      'view_list': 'Liste',
      'view_mosaic': 'Mosaïque',
      'section_language': 'Langue',
      'lang_system': 'Par défaut du système',
      'lang_en': 'English',
      'lang_es': 'Español',
      'lang_fr': 'Français',
      'lang_ar': 'العربية',
      'section_playback': 'Lecture',
      'on_track_completion': 'À la fin de la sourate',
      'playback_next': 'Sourate suivante',
      'playback_repeat': 'Répéter la sourate actuelle',
      'playback_stop': 'Arrêter la lecture',
      'section_tutorial': 'Tutoriel et aide',
      'reset_tutorial_title': 'Réinitialiser le tutoriel de vue',
      'reset_tutorial_desc':
          'Afficher à nouveau le guide visuel sur la liste des sourates.',
      'reset_tutorial_success':
          'Tutoriel réinitialisé ! Vous le verrez au prochain retour sur la liste.',
      'section_about': 'À propos',
      'app_description': 'Un lecteur audio minimaliste et épuré du Saint Coran.',
      'version': 'Version',
    },
    'ar': {
      'app_title': 'قارئ القرآن',
      'nav_surahs': 'السور',
      'nav_playlist': 'القائمة',
      'settings_title': 'الإعدادات',
      'close': 'إغلاق',
      'cancel': 'إلغاء',
      'reset': 'إعادة ضبط',
      'done': 'تم',
      'search_surahs': 'البحث عن سورة…',
      'no_surahs_found': 'لم يتم العثور على سور',
      'reciter_label': 'القارئ',
      'change_reciter': 'تغيير',
      'tooltip_list_view': 'التبديل إلى عرض القائمة',
      'tooltip_mosaic_view': 'التبديل إلى عرض الفسيفساء',
      'tooltip_settings': 'الإعدادات',
      'verses_count': '{count} آية',
      'meccan': 'مكية',
      'medinan': 'مدنية',
      'select_reciter': 'اختر القارئ',
      'search_reciter': 'البحث عن قارئ…',
      'tab_all': 'الكل',
      'tab_favorites': 'المفضلة',
      'tab_pinned': 'المثبتة',
      'no_favorites': 'لا يوجد قراء في المفضلة بعد',
      'no_pinned': 'لا يوجد قراء مثبتون',
      'max_pins_reached': 'الحد الأقصى ٣ قراء مثبتين',
      'playlist_title': 'قائمة التشغيل',
      'clear_all': 'مسح الكل',
      'playlist_empty_title': 'قائمة التشغيل فارغة',
      'playlist_empty_subtitle': 'أضف سوراً للاستماع إليها بتتابع متواصل',
      'surah_removed': 'تمت الإزالة من القائمة',
      'playlist_cleared': 'تم مسح قائمة التشغيل',
      'surah_added': 'تمت الإضافة إلى القائمة',
      'already_in_playlist': 'موجودة بالفعل في القائمة',
      'now_playing': 'قيد التشغيل الآن',
      'surah_of': 'سورة {current} من {total}',
      'error_loading_audio': 'خطأ في تحميل المقطع الصوتي',
      'play': 'تشغيل',
      'pause': 'إيقاف مؤقت',
      'stop': 'إيقاف',
      'previous': 'السابق',
      'next': 'التالي',
      'tutorial_badge': '✨ تلميح العرض',
      'tutorial_title': 'خصّص تجربة استماعك!',
      'tutorial_body_to_mosaic':
          'اضغط هنا في أي وقت للتبديل إلى عرض الفسيفساء الأنيق للسور.',
      'tutorial_body_to_list':
          'اضغط هنا في أي وقت للعودة إلى عرض القائمة التقليدي.',
      'tutorial_try_mosaic': 'تجربة عرض الفسيفساء',
      'tutorial_try_list': 'تجربة عرض القائمة',
      'tutorial_got_it': 'فهمت ذلك!',
      'section_appearance': 'المظهر',
      'theme_mode': 'السمة',
      'theme_system': 'تلقائي (النظام)',
      'theme_light': 'فاتح',
      'theme_dark': 'داكن',
      'view_mode': 'طريقة عرض السور',
      'view_list': 'قائمة',
      'view_mosaic': 'فسيفساء',
      'section_language': 'اللغة',
      'lang_system': 'لغة النظام الافتراضية',
      'lang_en': 'English',
      'lang_es': 'Español',
      'lang_fr': 'Français',
      'lang_ar': 'العربية',
      'section_playback': 'التشغيل',
      'on_track_completion': 'عند انتهاء السورة',
      'playback_next': 'تشغيل السورة التالية',
      'playback_repeat': 'إعادة تشغيل السورة الحالية',
      'playback_stop': 'إيقاف التشغيل',
      'section_tutorial': 'التعليمات والمساعدة',
      'reset_tutorial_title': 'إعادة ضبط تلميح العرض',
      'reset_tutorial_desc':
          'إظهار الإرشادات التوضيحية لزر تغيير العرض مجدداً في قائمة السور.',
      'reset_tutorial_success':
          'تمت إعادة التعيين! ستظهر الإرشادات عند عودتك لقائمة السور.',
      'section_about': 'حول التطبيق',
      'app_description': 'مشغل صوتي بسيط وأنيق للقرآن الكريم دون أي تشتيت.',
      'version': 'الإصدار',
    },
  };

  String translate(String key, [Map<String, String>? params]) {
    final langCode = locale.languageCode;
    final dict = _localizedValues[langCode] ?? _localizedValues['en']!;
    var value = dict[key] ?? _localizedValues['en']![key] ?? key;

    if (params != null) {
      params.forEach((k, v) {
        value = value.replaceAll('{$k}', v);
      });
    }

    return value;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'es', 'fr', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  String tr(String key, [Map<String, String>? params]) {
    return AppLocalizations.of(this).translate(key, params);
  }

  bool get isRtl {
    return Directionality.of(this) == TextDirection.rtl;
  }
}
