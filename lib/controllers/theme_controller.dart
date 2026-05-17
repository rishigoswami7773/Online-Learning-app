import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  ThemeController._private();
  static final ThemeController _instance = ThemeController._private();
  factory ThemeController() => _instance;

  final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);

  static const _key = 'theme_mode';

  Future<void> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == 'dark') {
      mode.value = ThemeMode.dark;
    } else if (saved == 'light') {
      mode.value = ThemeMode.light;
    } else {
      // No saved preference -> follow system by default
      mode.value = ThemeMode.system;
    }
  }

  ThemeMode get current => mode.value;

  void setMode(ThemeMode m) async {
    mode.value = m;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      m == ThemeMode.dark
          ? 'dark'
          : m == ThemeMode.light
          ? 'light'
          : 'system',
    );
  }

  void toggle() {
    if (mode.value == ThemeMode.light) {
      setMode(ThemeMode.dark);
    } else {
      setMode(ThemeMode.light);
    }
  }
}
