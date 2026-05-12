import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shared_preferences_provider.dart';

class AppSettings {
  final Locale locale;
  final ThemeMode themeMode;
  final DateTime? nextTestDate;

  const AppSettings({
    this.locale = const Locale('en'),
    this.themeMode = ThemeMode.system,
    this.nextTestDate,
  });

  AppSettings copyWith({
    Locale? locale,
    ThemeMode? themeMode,
    DateTime? nextTestDate,
    bool clearReminder = false,
  }) {
    return AppSettings(
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
      nextTestDate:
          clearReminder ? null : (nextTestDate ?? this.nextTestDate),
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SharedPreferences _prefs;

  SettingsNotifier(this._prefs)
      : super(AppSettings(
          locale: Locale(_prefs.getString('app_locale') ?? 'en'),
          themeMode: ThemeMode.values[
              (_prefs.getInt('app_theme_mode') ?? 0).clamp(0, 2)],
          nextTestDate: _prefs.getString('next_test_date') != null
              ? DateTime.tryParse(_prefs.getString('next_test_date')!)
              : null,
        ));

  Future<void> setLocale(Locale locale) async {
    state = state.copyWith(locale: locale);
    await _prefs.setString('app_locale', locale.languageCode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setInt('app_theme_mode', mode.index);
  }

  Future<void> setReminder(DateTime? date) async {
    state = state.copyWith(nextTestDate: date, clearReminder: date == null);
    if (date == null) {
      await _prefs.remove('next_test_date');
    } else {
      await _prefs.setString('next_test_date', date.toIso8601String());
    }
  }

  Future<void> clear() async {
    state = const AppSettings();
    await _prefs.remove('app_locale');
    await _prefs.remove('app_theme_mode');
    await _prefs.remove('next_test_date');
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) => SettingsNotifier(ref.watch(sharedPreferencesProvider)),
);
