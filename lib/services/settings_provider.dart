import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _darkModeKey = 'dark_mode';
  static const _textSizeKey = 'text_size';

  bool _isDarkMode = false;
  double _textSize = 1.0; // scale factor

  bool get isDarkMode => _isDarkMode;
  double get textSize => _textSize;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
    _textSize = prefs.getDouble(_textSizeKey) ?? 1.0;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }

  Future<void> setTextSize(double value) async {
    _textSize = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textSizeKey, value);
  }
}
