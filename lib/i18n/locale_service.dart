import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/analytics_service.dart';
import 'translation_service.dart';

/// Loads and persists the player's chosen language across launches.
///
/// The stored value is a language code (`en`, `ru`, `tr`). When nothing has
/// been chosen yet the app starts in English (the fallback locale).
class LocaleService {
  LocaleService._();
  static final LocaleService instance = LocaleService._();

  static const _prefsKey = 'app_language_code';

  SharedPreferences? _prefs;
  Locale _locale = TranslationService.fallbackLocale;

  /// The locale to hand to [GetMaterialApp] at startup.
  Locale get locale => _locale;

  /// Load the saved language before the first frame. Safe to call once.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final code = _prefs?.getString(_prefsKey);
    if (code != null) {
      _locale = TranslationService.localeFromLanguageCode(code);
    }
  }

  /// Switch the active language and remember it. [code] is `en`, `ru` or `tr`.
  Future<void> setLanguage(String code) async {
    _locale = TranslationService.localeFromLanguageCode(code);
    await _prefs?.setString(_prefsKey, _locale.languageCode);
    Get.updateLocale(_locale);
    AnalyticsService.instance.logLanguageChanged(_locale.languageCode);
  }

  /// The currently active language code (`en`, `ru`, `tr`).
  String get currentCode => (Get.locale ?? _locale).languageCode;
}
