import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final calibrationProvider = StateNotifierProvider<CalibrationNotifier, double?>((ref) {
  return CalibrationNotifier();
});

class CalibrationNotifier extends StateNotifier<double?> {
  CalibrationNotifier() : super(null) {
    _loadCalibration();
  }

  static const String _dpiKey = 'clinical_screen_dpi';

  Future<void> _loadCalibration() async {
    final prefs = await SharedPreferences.getInstance();
    final dpi = prefs.getDouble(_dpiKey);
    if (dpi != null && dpi > 0) {
      state = dpi;
    }
  }

  Future<void> saveCalibration(double dpi) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_dpiKey, dpi);
    state = dpi;
  }
}
