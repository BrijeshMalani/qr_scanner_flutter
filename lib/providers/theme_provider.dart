import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/colors.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  late SharedPreferences _prefs;
  bool _isDarkMode = false;

  ThemeProvider() {
    _loadThemeMode();
  }

  bool get isDarkMode => _isDarkMode;

  Future<void> _loadThemeMode() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }

  ThemeData get themeData {
    return _isDarkMode ? AppColors.getDarkTheme() : AppColors.getLightTheme();
  }
}
