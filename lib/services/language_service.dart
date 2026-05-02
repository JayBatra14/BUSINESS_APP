import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class LanguageService {
  LanguageService._();

  static const _settingsBoxName = 'settings';
  static const _languageCodeKey = 'appLanguageCode';

  static final ValueNotifier<Locale> localeNotifier =
      ValueNotifier<Locale>(const Locale('en'));

  static Future<void> init() async {
    final box = Hive.box(_settingsBoxName);
    final code = (box.get(_languageCodeKey) as String?) ?? 'en';
    localeNotifier.value = Locale(code);
  }

  static Future<void> setLanguage(String languageCode) async {
    final box = Hive.box(_settingsBoxName);
    await box.put(_languageCodeKey, languageCode);
    localeNotifier.value = Locale(languageCode);
  }

  static bool isHindi() => localeNotifier.value.languageCode == 'hi';
}
