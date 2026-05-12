import 'dart:math' as math;

/// ═══════════════════════════════════════════════════════════════════
/// LogMAR-based Tumbling E / Snellen Data — Clinical Grade
/// ═══════════════════════════════════════════════════════════════════
///
/// Key principles implemented:
/// 1. LogMAR progression (each line is 10^0.1 ≈ 1.2589x smaller)
/// 2. Proper Minimum Angle of Resolution (MAR) calculations
/// 3. Physical size computation via visual angle
/// 4. 5×5 grid optotype design ratio
/// 5. Metric (6/x) notation only — no American 20/x
/// ═══════════════════════════════════════════════════════════════════

class SnellenRow {
  final String acuity;       // e.g. '6/12' (metric only)
  final double logMAR;       // LogMAR value
  final double size;          // fallback display pt size (no calibration)
  final List<String> letters; // Snellen letters for this row
  final int eCount;           // number of E presentations per row

  const SnellenRow({
    required this.acuity,
    required this.logMAR,
    required this.size,
    required this.letters,
    this.eCount = 5,
  });

  double get denominator {
    final parts = acuity.split('/');
    return double.tryParse(parts[1]) ?? 6.0;
  }

  /// MAR (Minimum Angle of Resolution) in arcminutes
  double get mar => math.pow(10, logMAR).toDouble();

  /// Physical letter height in mm at a given viewing distance (in meters)
  /// Based on: h = 2 * d * tan(θ/2)
  /// where θ = 5 * MAR arcminutes (full optotype subtends 5× MAR)
  double physicalHeightMm(double distanceMeters) {
    final thetaArcmin = 5.0 * mar; // full optotype angle
    final thetaRad = thetaArcmin * (math.pi / (180.0 * 60.0));
    return 2.0 * distanceMeters * 1000.0 * math.tan(thetaRad / 2.0);
  }

  /// Physical stroke width (1/5 of letter height) in mm
  double strokeWidthMm(double distanceMeters) {
    return physicalHeightMm(distanceMeters) / 5.0;
  }

  /// Convert physical mm to device pixels given screen PPI
  double physicalHeightPixels(double distanceMeters, double screenPpi) {
    final mm = physicalHeightMm(distanceMeters);
    return mm * screenPpi / 25.4;
  }
}

/// ═══════════════════════════════════════════════════════════════════
/// LogMAR Row Table
/// ═══════════════════════════════════════════════════════════════════
///
/// LogMAR 1.0 = 6/60  (worst)
/// LogMAR 0.0 = 6/6   (normal)
/// LogMAR -0.1 = 6/4.8 (better than normal)
///
/// Each step: logMAR decreases by 0.1 → letter size shrinks by ×1.2589
///
/// Standard E-chart: 5 presentations per row (like ETDRS)
/// Snellen: variable letters per row (traditional)
/// ═══════════════════════════════════════════════════════════════════

const List<SnellenRow> snellenRows = [
  // LogMAR 1.0 — 6/60
  SnellenRow(
    acuity: '6/60',  logMAR: 1.0,
    size: 140.0, letters: ['E'], eCount: 5,
  ),
  // LogMAR 0.9 — 6/48
  SnellenRow(
    acuity: '6/48',  logMAR: 0.9,
    size: 112.0, letters: ['F', 'P'], eCount: 5,
  ),
  // LogMAR 0.8 — 6/38
  SnellenRow(
    acuity: '6/38',  logMAR: 0.8,
    size: 88.0, letters: ['T', 'O', 'Z'], eCount: 5,
  ),
  // LogMAR 0.7 — 6/30
  SnellenRow(
    acuity: '6/30',  logMAR: 0.7,
    size: 70.0, letters: ['L', 'P', 'E', 'D'], eCount: 5,
  ),
  // LogMAR 0.6 — 6/24
  SnellenRow(
    acuity: '6/24',  logMAR: 0.6,
    size: 56.0, letters: ['P', 'E', 'C', 'F', 'D'], eCount: 5,
  ),
  // LogMAR 0.5 — 6/18
  SnellenRow(
    acuity: '6/18',  logMAR: 0.5,
    size: 44.0, letters: ['E', 'D', 'F', 'C', 'Z', 'P'], eCount: 5,
  ),
  // LogMAR 0.4 — 6/15
  SnellenRow(
    acuity: '6/15',  logMAR: 0.4,
    size: 35.0, letters: ['F', 'E', 'L', 'O', 'P', 'Z', 'D'], eCount: 5,
  ),
  // LogMAR 0.3 — 6/12
  SnellenRow(
    acuity: '6/12',  logMAR: 0.3,
    size: 28.0, letters: ['D', 'E', 'F', 'P', 'O', 'T', 'E', 'C'], eCount: 5,
  ),
  // LogMAR 0.2 — 6/9.5
  SnellenRow(
    acuity: '6/9.5', logMAR: 0.2,
    size: 22.0, letters: ['L', 'E', 'F', 'O', 'D', 'P', 'C', 'T'], eCount: 5,
  ),
  // LogMAR 0.1 — 6/7.5
  SnellenRow(
    acuity: '6/7.5', logMAR: 0.1,
    size: 17.5, letters: ['F', 'D', 'P', 'L', 'T', 'C', 'E', 'O'], eCount: 5,
  ),
  // LogMAR 0.0 — 6/6 (normal vision)
  SnellenRow(
    acuity: '6/6',   logMAR: 0.0,
    size: 14.0, letters: ['P', 'E', 'Z', 'O', 'L', 'C', 'F', 'T', 'D'], eCount: 5,
  ),
];

/// ═══════════════════════════════════════════════════════════════════
/// LogMAR Score Calculation (per-letter scoring)
/// ═══════════════════════════════════════════════════════════════════
///
/// In LogMAR systems, each letter has a score:
///   letterScore = 0.1 / (letters per row)
///   Typically with 5 letters per row: 0.02 per letter
///
/// Final LogMAR = LogMAR of best row read
///              + (letterScore × number of letters missed on that row)
///              - (letterScore × number of letters read on next row)
/// ═══════════════════════════════════════════════════════════════════

/// Calculate per-letter LogMAR score
double logMARLetterScore(int lettersPerRow) {
  return 0.1 / lettersPerRow;
}

/// Calculate final LogMAR score from test results
/// [lastPassedRowIndex] = index of last row where ≥50% were correct
/// [errorsOnLastRow] = number of errors on the last passed row
/// [correctOnNextRow] = correct answers on the row after last passed (if attempted)
/// [lettersPerRow] = number of letters/presentations per row (typically 5)
double calculateLogMAR({
  required int lastPassedRowIndex,
  required int errorsOnLastRow,
  int correctOnNextRow = 0,
  int lettersPerRow = 5,
}) {
  if (lastPassedRowIndex < 0 || lastPassedRowIndex >= snellenRows.length) {
    return 1.1; // worse than 6/60
  }
  final baseLogMAR = snellenRows[lastPassedRowIndex].logMAR;
  final letterScore = logMARLetterScore(lettersPerRow);
  return baseLogMAR + (errorsOnLastRow * letterScore) - (correctOnNextRow * letterScore);
}

/// Convert LogMAR to Snellen metric notation string (approximate)
String logMARToSnellenMetric(double logMAR) {
  final denom = 6.0 * math.pow(10, logMAR);
  if (denom >= 60) return '6/60';
  if (denom <= 4.8) return '6/4.8';
  // Round to nearest standard
  final standards = [4.8, 6.0, 7.5, 9.5, 12.0, 15.0, 18.0, 24.0, 30.0, 38.0, 48.0, 60.0];
  double closest = 6.0;
  double minDiff = double.infinity;
  for (final s in standards) {
    final diff = (denom - s).abs();
    if (diff < minDiff) { minDiff = diff; closest = s; }
  }
  // Format nicely
  if (closest == closest.roundToDouble()) {
    return '6/${closest.toInt()}';
  }
  return '6/$closest';
}

/// Rough mapping of acuity → estimated sphere equivalent.
/// Based on clinical correlation data (approximate).
double estimatedSphereForAcuity(String acuity) {
  switch (acuity) {
    case '6/6':   return 0.00;
    case '6/7.5': return -0.25;
    case '6/9':   return -0.50;
    case '6/9.5': return -0.50;
    case '6/12':  return -1.00;
    case '6/15':  return -1.25;
    case '6/18':  return -1.75;
    case '6/24':  return -2.50;
    case '6/30':  return -3.00;
    case '6/36':  return -3.50;
    case '6/38':  return -3.50;
    case '6/48':  return -4.00;
    case '6/60':  return -4.50;
    default:      return 0.00;
  }
}

/// ═══════════════════════════════════════════════════════════════════
/// Screen Calibration Utilities
/// ═══════════════════════════════════════════════════════════════════

class ScreenCalibration {
  /// Device DPI (pixels per inch)
  final double dpi;
  /// Viewing distance in meters
  final double viewingDistanceM;

  const ScreenCalibration({
    required this.dpi,
    required this.viewingDistanceM,
  });

  /// Standard test distance: 3 meters (phone at arm's length equivalent)
  static const double defaultDistanceM = 0.4; // ~40cm arm's length

  /// Standard credit card width for calibration: 85.6mm
  static const double creditCardWidthMm = 85.6;
  /// Standard credit card height: 53.98mm
  static const double creditCardHeightMm = 53.98;

  /// Calculate pixel size for a given optotype row
  double optotypePixels(SnellenRow row) {
    return row.physicalHeightPixels(viewingDistanceM, dpi);
  }

  /// Minimum pixel size for accurate rendering (below this, results unreliable)
  /// Rule: stroke width must be at least 2 pixels
  double minimumReliablePixels(SnellenRow row) {
    final strokePx = row.strokeWidthMm(viewingDistanceM) * dpi / 25.4;
    return strokePx >= 2.0 ? row.physicalHeightPixels(viewingDistanceM, dpi) : -1;
  }
}
