import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService extends ChangeNotifier {
  static const String _langKey = 'app_language';
  String _languageCode = 'vi'; // default Vietnamese

  String get languageCode => _languageCode;
  bool get isVietnamese => _languageCode == 'vi';

  LocaleService() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Auto-detect system language on first run
    String defaultLang = 'en';
    try {
      final systemLocale = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      if (systemLocale == 'vi') {
        defaultLang = 'vi';
      }
    } catch (e) {
      debugPrint('Error getting system locale: $e');
    }
    
    final saved = prefs.getString(_langKey) ?? defaultLang;
    _languageCode = saved;
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (_languageCode == code) return;
    _languageCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, code);
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    await setLanguage(_languageCode == 'vi' ? 'en' : 'vi');
  }
}
