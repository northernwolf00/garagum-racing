import 'package:get/get.dart';
import 'package:flutter/material.dart';

import 'translations/en_us.dart';
import 'translations/ru_ru.dart';
import 'translations/tr_tr.dart';

/// GetX translations for the three supported languages:
/// English (default / fallback), Russian and Turkmen.
///
/// Turkmen uses the `tr` language code by project convention, but the strings
/// in [trTR] are Turkmen, not Turkish.
class TranslationService extends Translations {
  static const fallbackLocale = Locale('en', 'US');

  /// Display names shown in the language picker, aligned with [locales].
  static final langs = [
    'English',
    'Русский',
    'Türkmen',
  ];

  static final locales = [
    const Locale('en', 'US'),
    const Locale('ru', 'RU'),
    const Locale('tr', 'TR'),
  ];

  static Locale localeFromLanguageCode(String code) {
    final normalizedCode = code.toLowerCase();
    for (final locale in locales) {
      if (locale.languageCode.toLowerCase() == normalizedCode) {
        return locale;
      }
    }
    return fallbackLocale;
  }

  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': enUS,
        'en': enUS,
        'ru_RU': ruRU,
        'ru': ruRU,
        'tr_TR': trTR,
        'tr': trTR,
      };

  /// Change the active locale from a display name (one of [langs]).
  void changeLocale(String lang) {
    final locale = _getLocaleFromLanguage(lang);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.updateLocale(locale);
    });
  }

  Locale _getLocaleFromLanguage(String lang) {
    for (int i = 0; i < langs.length; i++) {
      if (lang == langs[i]) return locales[i];
    }
    return Get.locale ?? fallbackLocale;
  }
}
