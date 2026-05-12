import 'dart:convert';
import 'dart:math' as math;
import '../constants/snellen_data.dart';

/// ═══════════════════════════════════════════════════════════════════
/// Clinical Analysis Engine — Professional Grade
/// ═══════════════════════════════════════════════════════════════════
///
/// This engine provides:
/// 1. Per-letter LogMAR scoring (0.02 per letter, ETDRS-style)
/// 2. Staircase-aware acuity determination
/// 3. Directional error pattern analysis for astigmatism
/// 4. Response time anomaly detection
/// 5. Binocular comparison & amblyopia screening
/// 6. Statistical confidence scoring
/// ═══════════════════════════════════════════════════════════════════

/// Records a single attempt during the vision test.
class AttemptRecord {
  final int rowIndex;
  final int shownDirection;   // 0=right,1=down,2=left,3=up; -1 for snellen
  final int guessedDirection; // -1 = "can't see" or snellen
  final bool correct;
  final int responseMs;
  final double logMAR;        // LogMAR of the row

  const AttemptRecord({
    required this.rowIndex,
    required this.shownDirection,
    required this.guessedDirection,
    required this.correct,
    required this.responseMs,
    this.logMAR = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'row': rowIndex, 'shown': shownDirection,
    'guessed': guessedDirection, 'ok': correct, 'ms': responseMs,
    'logMAR': logMAR,
  };
}

/// Full clinical analysis result for one eye.
class EyeAnalysis {
  final String acuity;           // e.g. '6/12'
  final double logMARScore;      // precise LogMAR score
  final double sphere;           // estimated sphere (D)
  final double cylinder;         // estimated cylinder (D)
  final int axis;                // estimated axis (°)
  final double sphericalEq;      // sphere + cylinder/2
  final double avgResponseMs;
  final int cantSeeCount;
  final int totalAttempts;
  final int correctAttempts;
  final double accuracy;         // 0.0-1.0
  final String condition;        // 'Normal','Myopia','Hyperopia', etc.
  final String severity;         // 'Normal','Mild','Moderate','Severe'
  final List<String> flags;      // clinical warnings
  final double confidenceScore;  // 0.0-1.0 reliability metric
  final Map<int, _RowPerformance> rowPerformances; // per-row breakdown

  const EyeAnalysis({
    required this.acuity, required this.logMARScore,
    required this.sphere, required this.cylinder,
    required this.axis, required this.sphericalEq, required this.avgResponseMs,
    required this.cantSeeCount, required this.totalAttempts,
    required this.correctAttempts, required this.accuracy,
    required this.condition, required this.severity, required this.flags,
    this.confidenceScore = 0.0,
    this.rowPerformances = const {},
  });
}

/// Per-row performance metrics
class _RowPerformance {
  final int total;
  final int correct;
  final double avgMs;
  final bool passed;

  const _RowPerformance({
    required this.total, required this.correct,
    required this.avgMs, required this.passed,
  });
}

/// Full report for both eyes.
class ClinicalReport {
  final EyeAnalysis od; // right
  final EyeAnalysis os; // left
  final List<String> binocularFlags; // amblyopia, etc.
  final String overallAssessment;
  final double testReliability; // 0.0-1.0

  const ClinicalReport({
    required this.od, required this.os,
    required this.binocularFlags, required this.overallAssessment,
    this.testReliability = 0.0,
  });

  /// Encode the report into a JSON string to store in VisionRecord.notes.
  String toJsonString() => jsonEncode({
    'od': _eyeJson(od), 'os': _eyeJson(os),
    'binocular': binocularFlags, 'assessment': overallAssessment,
    'reliability': testReliability,
  });

  static Map<String, dynamic> _eyeJson(EyeAnalysis e) => {
    'acuity': e.acuity, 'logMAR': e.logMARScore,
    'sphere': e.sphere, 'cylinder': e.cylinder,
    'axis': e.axis, 'se': e.sphericalEq, 'avgMs': e.avgResponseMs,
    'cantSee': e.cantSeeCount, 'total': e.totalAttempts,
    'correct': e.correctAttempts, 'accuracy': e.accuracy,
    'condition': e.condition, 'severity': e.severity, 'flags': e.flags,
    'confidence': e.confidenceScore,
  };

  static ClinicalReport? fromJsonString(String? json) {
    if (json == null) return null;
    try {
      final m = jsonDecode(json) as Map<String, dynamic>;
      return ClinicalReport(
        od: _parseEye(m['od']), os: _parseEye(m['os']),
        binocularFlags: List<String>.from(m['binocular'] ?? []),
        overallAssessment: m['assessment'] ?? '',
        testReliability: (m['reliability'] ?? 0).toDouble(),
      );
    } catch (_) { return null; }
  }

  static EyeAnalysis _parseEye(Map<String, dynamic> m) => EyeAnalysis(
    acuity: m['acuity'] ?? '—',
    logMARScore: (m['logMAR'] ?? 1.0).toDouble(),
    sphere: (m['sphere'] ?? 0).toDouble(),
    cylinder: (m['cylinder'] ?? 0).toDouble(), axis: m['axis'] ?? 0,
    sphericalEq: (m['se'] ?? 0).toDouble(),
    avgResponseMs: (m['avgMs'] ?? 0).toDouble(),
    cantSeeCount: m['cantSee'] ?? 0, totalAttempts: m['total'] ?? 0,
    correctAttempts: m['correct'] ?? 0, accuracy: (m['accuracy'] ?? 0).toDouble(),
    condition: m['condition'] ?? '', severity: m['severity'] ?? '',
    flags: List<String>.from(m['flags'] ?? []),
    confidenceScore: (m['confidence'] ?? 0).toDouble(),
  );
}

/// ═══════════════════════════════════════════════════════════════════
/// Main Clinical Analyzer — Professional Grade
/// ═══════════════════════════════════════════════════════════════════
class ClinicalAnalyzer {

  /// Analyze one eye's attempts with LogMAR-based scoring.
  static EyeAnalysis analyzeEye(List<AttemptRecord> attempts, String acuity) {
    final total = attempts.length;
    final correct = attempts.where((a) => a.correct).length;
    final cantSee = attempts.where((a) => a.guessedDirection == -1).length;
    final accuracy = total > 0 ? correct / total : 0.0;
    final avgMs = total > 0
        ? attempts.map((a) => a.responseMs).reduce((a, b) => a + b) / total
        : 0.0;

    // ── Per-row performance breakdown ──
    final rowPerformances = <int, _RowPerformance>{};
    final rowGroups = <int, List<AttemptRecord>>{};
    for (final a in attempts) {
      rowGroups.putIfAbsent(a.rowIndex, () => []).add(a);
    }
    for (final entry in rowGroups.entries) {
      final rowAttempts = entry.value;
      final rowCorrect = rowAttempts.where((a) => a.correct).length;
      final rowAvgMs = rowAttempts.map((a) => a.responseMs).reduce((a, b) => a + b) / rowAttempts.length;
      final passed = rowCorrect >= (rowAttempts.length * 0.5).ceil();
      rowPerformances[entry.key] = _RowPerformance(
        total: rowAttempts.length, correct: rowCorrect,
        avgMs: rowAvgMs, passed: passed,
      );
    }

    // ── LogMAR Score Calculation ──
    double logMARScore = _calculateLogMARFromAttempts(attempts, acuity);

    // ── Sphere estimation from acuity ──
    final sphere = _sphereFromAcuity(acuity);

    // ── Cylinder & Axis from direction error patterns (E-chart only) ──
    double cylinder = 0;
    int axis = 0;
    final eAttempts = attempts.where((a) => a.shownDirection >= 0).toList();
    if (eAttempts.isNotEmpty) {
      // Horizontal directions: 0 (right), 2 (left)
      // Vertical directions: 1 (down), 3 (up)
      final hShown = eAttempts.where((a) => a.shownDirection == 0 || a.shownDirection == 2).toList();
      final vShown = eAttempts.where((a) => a.shownDirection == 1 || a.shownDirection == 3).toList();
      final hErrors = hShown.isEmpty ? 0.0 : hShown.where((a) => !a.correct).length / hShown.length;
      final vErrors = vShown.isEmpty ? 0.0 : vShown.where((a) => !a.correct).length / vShown.length;
      final diff = (hErrors - vErrors).abs();

      if (diff > 0.2 && (hShown.length + vShown.length) >= 4) {
        // Significant directional asymmetry → astigmatism indicator
        cylinder = -(diff * 2.0).clamp(0.25, 3.0);
        // Round to nearest 0.25
        cylinder = (cylinder * 4).roundToDouble() / 4;
        if (hErrors > vErrors) {
          axis = 180; // WTR - errors in horizontal → axis at 180°
        } else {
          axis = 90; // ATR - errors in vertical → axis at 90°
        }
      }
    }

    final sphericalEq = sphere + cylinder / 2;

    // ── Condition assessment ──
    String condition;
    if (acuity == '>6/60') {
      condition = 'Severe Visual Impairment';
    } else if (sphere < -0.25) {
      condition = 'Myopia';
    } else if (sphere > 0.25) {
      condition = 'Hyperopia';
    } else {
      condition = 'Normal';
    }

    // ── Severity (WHO classification) ──
    String severity;
    final denom = _denominator(acuity);
    if (denom <= 6) severity = 'Normal';
    else if (denom <= 9.5) severity = 'Mild';
    else if (denom <= 18) severity = 'Moderate';
    else if (denom <= 36) severity = 'Significant';
    else severity = 'Severe';

    // ── Confidence Score ──
    double confidence = _calculateConfidence(attempts, avgMs);

    // ── Flags ──
    final flags = <String>[];
    if (cylinder.abs() >= 0.5) flags.add('Possible astigmatism (est. ${cylinder.toStringAsFixed(2)} D @ $axis°)');
    if (cantSee > 0) flags.add('Patient reported "can\'t see" $cantSee time(s)');
    if (avgMs > 5000) flags.add('Slow response time (>5s avg) — possible cognitive/neurological concern');
    if (avgMs > 3000 && avgMs <= 5000) flags.add('Elevated response time — monitor closely');
    if (accuracy < 0.4 && total >= 6) flags.add('Very low accuracy — may indicate severe impairment');
    if (confidence < 0.5) flags.add('Low test reliability — consider retesting');

    // Check for inconsistent direction errors (neurological indicator)
    if (eAttempts.length >= 6) {
      final wrongDir = eAttempts.where((a) => !a.correct && a.guessedDirection >= 0).toList();
      if (wrongDir.length >= 4) {
        final dirSet = wrongDir.map((a) => a.guessedDirection).toSet();
        if (dirSet.length <= 1) {
          flags.add('Perseverative error pattern — always guessing same direction (possible neurological concern)');
        }
      }
    }

    // Check for response time variance (attention indicator)
    if (total >= 6) {
      final times = attempts.map((a) => a.responseMs.toDouble()).toList();
      final mean = times.reduce((a, b) => a + b) / times.length;
      final variance = times.map((t) => math.pow(t - mean, 2)).reduce((a, b) => a + b) / times.length;
      final stdDev = math.sqrt(variance);
      final cv = mean > 0 ? stdDev / mean : 0; // coefficient of variation
      if (cv > 1.0) {
        flags.add('High response time variability (CV=${cv.toStringAsFixed(2)}) — possible attention fluctuation');
      }
    }

    return EyeAnalysis(
      acuity: acuity, logMARScore: logMARScore,
      sphere: sphere, cylinder: cylinder, axis: axis,
      sphericalEq: sphericalEq, avgResponseMs: avgMs, cantSeeCount: cantSee,
      totalAttempts: total, correctAttempts: correct, accuracy: accuracy,
      condition: condition, severity: severity, flags: flags,
      confidenceScore: confidence, rowPerformances: rowPerformances,
    );
  }

  /// Calculate LogMAR from attempt records
  static double _calculateLogMARFromAttempts(List<AttemptRecord> attempts, String acuity) {
    if (attempts.isEmpty) return 1.1;

    // Group by row
    final rowGroups = <int, List<AttemptRecord>>{};
    for (final a in attempts) {
      rowGroups.putIfAbsent(a.rowIndex, () => []).add(a);
    }

    // Find last passed row and count errors
    int lastPassedRow = -1;
    int errorsOnLastRow = 0;
    int correctOnNextRow = 0;

    for (int i = 0; i < snellenRows.length; i++) {
      if (!rowGroups.containsKey(i)) continue;
      final rowAttempts = rowGroups[i]!;
      final rowCorrect = rowAttempts.where((a) => a.correct).length;
      final threshold = (rowAttempts.length * 0.5).ceil();

      if (rowCorrect >= threshold) {
        lastPassedRow = i;
        errorsOnLastRow = rowAttempts.length - rowCorrect;
      } else {
        // This row was failed — count correct answers on it
        if (lastPassedRow >= 0) {
          correctOnNextRow = rowCorrect;
        }
        break;
      }
    }

    if (lastPassedRow < 0) return 1.1; // worse than 6/60

    return calculateLogMAR(
      lastPassedRowIndex: lastPassedRow,
      errorsOnLastRow: errorsOnLastRow,
      correctOnNextRow: correctOnNextRow,
      lettersPerRow: rowGroups[lastPassedRow]?.length ?? 5,
    );
  }

  /// Calculate test confidence/reliability score
  static double _calculateConfidence(List<AttemptRecord> attempts, double avgMs) {
    if (attempts.isEmpty) return 0.0;
    double score = 1.0;

    // Penalize very fast responses (< 500ms = likely random)
    final fastCount = attempts.where((a) => a.responseMs < 500).length;
    score -= (fastCount / attempts.length) * 0.3;

    // Penalize very slow responses (> 8s = likely distracted)
    final slowCount = attempts.where((a) => a.responseMs > 8000).length;
    score -= (slowCount / attempts.length) * 0.2;

    // Penalize too few attempts (less statistical power)
    if (attempts.length < 10) score -= 0.15;
    if (attempts.length < 5) score -= 0.2;

    // Penalize high "can't see" count relative to total
    final cantSee = attempts.where((a) => a.guessedDirection == -1).length;
    if (cantSee > attempts.length * 0.4) score -= 0.2;

    // Bonus for consistent response times
    final times = attempts.map((a) => a.responseMs.toDouble()).toList();
    if (times.length >= 3) {
      final mean = times.reduce((a, b) => a + b) / times.length;
      final variance = times.map((t) => math.pow(t - mean, 2)).reduce((a, b) => a + b) / times.length;
      final cv = mean > 0 ? math.sqrt(variance) / mean : 1.0;
      if (cv < 0.5) score += 0.1; // very consistent
    }

    return score.clamp(0.0, 1.0);
  }

  /// Generate full binocular report.
  static ClinicalReport generateReport(EyeAnalysis od, EyeAnalysis os) {
    final biFlags = <String>[];

    // Amblyopia detection: >2 lines difference
    final odD = _denominator(od.acuity);
    final osD = _denominator(os.acuity);
    final lineDiff = _lineDifference(odD, osD);
    if (lineDiff >= 2) {
      final weaker = odD > osD ? 'OD (Right)' : 'OS (Left)';
      biFlags.add('Significant inter-ocular difference (${od.acuity} vs ${os.acuity}) — $weaker is weaker. Rule out Amblyopia.');
    }

    // LogMAR difference
    final logMARDiff = (od.logMARScore - os.logMARScore).abs();
    if (logMARDiff >= 0.2) {
      biFlags.add('LogMAR difference of ${logMARDiff.toStringAsFixed(2)} between eyes (≥0.2 is clinically significant)');
    }

    // Response time difference
    if (od.avgResponseMs > 0 && os.avgResponseMs > 0) {
      final timeDiff = (od.avgResponseMs - os.avgResponseMs).abs();
      if (timeDiff > 2000) {
        final slower = od.avgResponseMs > os.avgResponseMs ? 'OD' : 'OS';
        biFlags.add('Significant response time difference between eyes ($slower is ${(timeDiff/1000).toStringAsFixed(1)}s slower)');
      }
    }

    // Overall test reliability
    final reliability = (od.confidenceScore + os.confidenceScore) / 2.0;

    // Overall assessment
    String assessment;
    if (od.severity == 'Normal' && os.severity == 'Normal' && biFlags.isEmpty) {
      assessment = 'Both eyes show normal visual acuity (LogMAR ≤ 0.0). No significant refractive error detected. Routine follow-up recommended in 12–24 months.';
    } else if (od.severity == 'Mild' || os.severity == 'Mild') {
      assessment = 'Mild visual reduction detected (LogMAR 0.1–0.2). Recommend comprehensive eye examination within 3–6 months.';
    } else if (od.severity == 'Moderate' || os.severity == 'Moderate') {
      assessment = 'Moderate visual impairment detected (LogMAR 0.3–0.5). Corrective lenses likely needed. Schedule eye exam promptly.';
    } else if (od.severity == 'Significant' || os.severity == 'Significant' || od.severity == 'Severe' || os.severity == 'Severe') {
      assessment = 'Significant/Severe visual impairment detected (LogMAR ≥ 0.6). Urgent comprehensive eye examination required. Possible underlying pathology.';
    } else {
      assessment = 'Visual screening complete. Consult eye care professional for detailed evaluation.';
    }

    if (reliability < 0.6) {
      assessment += '\n\n⚠️ Test reliability is low (${(reliability * 100).toInt()}%). Consider retesting under controlled conditions.';
    }

    return ClinicalReport(
      od: od, os: os, binocularFlags: biFlags,
      overallAssessment: assessment, testReliability: reliability,
    );
  }

  static double _sphereFromAcuity(String acuity) {
    return estimatedSphereForAcuity(acuity);
  }

  static double _denominator(String acuity) {
    if (acuity == '>6/60') return 120;
    final parts = acuity.split('/');
    if (parts.length != 2) return 6;
    return double.tryParse(parts[1]) ?? 6;
  }

  static int _lineDifference(double d1, double d2) {
    final rows = [6.0, 7.5, 9.5, 12.0, 15.0, 18.0, 24.0, 30.0, 38.0, 48.0, 60.0];
    int i1 = -1, i2 = -1;
    for (int i = 0; i < rows.length; i++) {
      if ((d1 - rows[i]).abs() < 1.0) i1 = i;
      if ((d2 - rows[i]).abs() < 1.0) i2 = i;
    }
    if (i1 < 0 || i2 < 0) return 0;
    return (i1 - i2).abs();
  }
}
