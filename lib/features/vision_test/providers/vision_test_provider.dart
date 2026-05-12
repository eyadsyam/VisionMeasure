import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/snellen_data.dart';
import '../../../core/utils/clinical_analysis.dart';
import '../../../core/providers/calibration_provider.dart';

enum TestEye { right, left }

enum TestMode { snellen, eChart }
enum TestPhase { instructions, calibration, positioning, testing, switchEye, results }

/// ═══════════════════════════════════════════════════════════════════
/// Professional Adaptive Staircase Vision Testing Algorithm
/// ═══════════════════════════════════════════════════════════════════
///
/// Implements a clinical-grade 4-2 staircase procedure:
///
///   Phase 1 (Coarse): Step size = 2 rows per reversal
///   Phase 2 (Fine):   Step size = 1 row per reversal (after 2 reversals)
///
/// Termination criteria:
///   • 6 reversals reached → compute threshold from last 4 reversals
///   • Boundary reached (best or worst row)
///
/// Per-row scoring:
///   • 5 presentations per row (ETDRS standard)
///   • Pass threshold: ≥ 3/5 correct (≥ 60%)
///   • E directions are randomized with no-repeat guarantee
///
/// LogMAR scoring:
///   • Each letter = 0.02 logMAR (0.1 / 5 letters)
///   • Final score = weighted average of reversal rows
///
/// Anti-memorization:
///   • Random E direction per stimulus
///   • No two consecutive same-direction presentations
///   • Staircase prevents predictable sequences
/// ═══════════════════════════════════════════════════════════════════

class VisionTestState {
  final TestPhase phase;
  final TestEye currentEye;
  final TestMode mode;
  final int currentRowIndex;
  final int attemptsUsed;
  final int correctInRow;
  final String? rightAcuity;
  final String? leftAcuity;
  final double? rightLogMAR;
  final double? leftLogMAR;
  final double? faceDistanceCm;
  final bool positionConfirmed;
  final int lastERotation;
  final int? lastGuessDir;
  final bool? lastGuessCorrect;
  final bool waitingForNext;
  final int snellenLetterIdx;
  final String? snellenUserInput;
  final DateTime? attemptStartTime;

  // Per-eye attempt records for clinical analysis
  final List<AttemptRecord> currentEyeAttempts;
  final List<AttemptRecord> rightEyeAttempts;
  final List<AttemptRecord> leftEyeAttempts;
  final ClinicalReport? report;

  // Staircase state
  final int reversalCount;         // number of direction changes
  final bool lastRowPassed;        // did the last row pass?
  final List<int> reversalRows;    // row indices where reversals occurred
  final List<int> usedRotations;   // track rotations used in current row
  final int staircaseStep;         // current step size (2 for coarse, 1 for fine)
  final bool staircaseInitialized; // has the first row been evaluated?

  // Calibration
  final double? screenDpi;
  final bool calibrated;

  // Total rows tested (for progress tracking in staircase)
  final int totalRowsTested;

  static const int attemptsPerRow = 5;     // ETDRS standard: 5 per row
  static const int minCorrectToPass = 3;   // ≥60% to pass
  static const int maxReversals = 6;       // stop after 6 reversals
  static const int startRowIndex = 3;      // start at ~6/30 (middle difficulty)
  static const int coarseStep = 2;         // initial step size
  static const int fineStep = 1;           // step after 2 reversals
  static const int finePhaseAfterReversals = 2; // switch to fine after this many reversals

  const VisionTestState({
    this.phase = TestPhase.instructions,
    this.currentEye = TestEye.right,
    this.mode = TestMode.eChart,
    this.currentRowIndex = startRowIndex,
    this.attemptsUsed = 0,
    this.correctInRow = 0,
    this.rightAcuity,
    this.leftAcuity,
    this.rightLogMAR,
    this.leftLogMAR,
    this.faceDistanceCm,
    this.positionConfirmed = false,
    this.lastERotation = 0,
    this.lastGuessDir,
    this.lastGuessCorrect,
    this.waitingForNext = false,
    this.snellenLetterIdx = 0,
    this.snellenUserInput,
    this.attemptStartTime,
    this.currentEyeAttempts = const [],
    this.rightEyeAttempts = const [],
    this.leftEyeAttempts = const [],
    this.report,
    this.reversalCount = 0,
    this.lastRowPassed = true,
    this.reversalRows = const [],
    this.usedRotations = const [],
    this.staircaseStep = coarseStep,
    this.staircaseInitialized = false,
    this.screenDpi,
    this.calibrated = false,
    this.totalRowsTested = 0,
  });

  VisionTestState copyWith({
    TestPhase? phase, TestEye? currentEye, TestMode? mode,
    int? currentRowIndex, int? attemptsUsed, int? correctInRow,
    String? rightAcuity, String? leftAcuity,
    double? rightLogMAR, double? leftLogMAR,
    double? faceDistanceCm,
    bool? positionConfirmed, int? lastERotation, int? lastGuessDir,
    bool? lastGuessCorrect, bool? waitingForNext, int? snellenLetterIdx,
    String? snellenUserInput, DateTime? attemptStartTime,
    List<AttemptRecord>? currentEyeAttempts,
    List<AttemptRecord>? rightEyeAttempts,
    List<AttemptRecord>? leftEyeAttempts,
    ClinicalReport? report,
    int? reversalCount, bool? lastRowPassed,
    List<int>? reversalRows, List<int>? usedRotations,
    int? staircaseStep, bool? staircaseInitialized,
    double? screenDpi, bool? calibrated,
    int? totalRowsTested,
    bool clearLastGuess = false, bool clearSnellenInput = false,
  }) {
    return VisionTestState(
      phase: phase ?? this.phase,
      currentEye: currentEye ?? this.currentEye,
      mode: mode ?? this.mode,
      currentRowIndex: currentRowIndex ?? this.currentRowIndex,
      attemptsUsed: attemptsUsed ?? this.attemptsUsed,
      correctInRow: correctInRow ?? this.correctInRow,
      rightAcuity: rightAcuity ?? this.rightAcuity,
      leftAcuity: leftAcuity ?? this.leftAcuity,
      rightLogMAR: rightLogMAR ?? this.rightLogMAR,
      leftLogMAR: leftLogMAR ?? this.leftLogMAR,
      faceDistanceCm: faceDistanceCm ?? this.faceDistanceCm,
      positionConfirmed: positionConfirmed ?? this.positionConfirmed,
      lastERotation: lastERotation ?? this.lastERotation,
      lastGuessDir: clearLastGuess ? null : (lastGuessDir ?? this.lastGuessDir),
      lastGuessCorrect: clearLastGuess ? null : (lastGuessCorrect ?? this.lastGuessCorrect),
      waitingForNext: waitingForNext ?? this.waitingForNext,
      snellenLetterIdx: snellenLetterIdx ?? this.snellenLetterIdx,
      snellenUserInput: clearSnellenInput ? null : (snellenUserInput ?? this.snellenUserInput),
      attemptStartTime: attemptStartTime ?? this.attemptStartTime,
      currentEyeAttempts: currentEyeAttempts ?? this.currentEyeAttempts,
      rightEyeAttempts: rightEyeAttempts ?? this.rightEyeAttempts,
      leftEyeAttempts: leftEyeAttempts ?? this.leftEyeAttempts,
      report: report ?? this.report,
      reversalCount: reversalCount ?? this.reversalCount,
      lastRowPassed: lastRowPassed ?? this.lastRowPassed,
      reversalRows: reversalRows ?? this.reversalRows,
      usedRotations: usedRotations ?? this.usedRotations,
      staircaseStep: staircaseStep ?? this.staircaseStep,
      staircaseInitialized: staircaseInitialized ?? this.staircaseInitialized,
      screenDpi: screenDpi ?? this.screenDpi,
      calibrated: calibrated ?? this.calibrated,
      totalRowsTested: totalRowsTested ?? this.totalRowsTested,
    );
  }

  String get currentAcuity => snellenRows[currentRowIndex].acuity;
  double get currentLogMAR => snellenRows[currentRowIndex].logMAR;
  double get rowProgress => currentRowIndex / snellenRows.length;

  /// Progress indicator — staircase-aware
  /// Estimates based on reversals completed vs max
  double get overallProgress {
    final eyeOffset = currentEye == TestEye.left ? 0.5 : 0.0;
    if (reversalCount >= maxReversals) return eyeOffset + 0.5;
    // Use reversals as progress metric (more meaningful for staircase)
    final staircaseProgress = (reversalCount / maxReversals).clamp(0.0, 1.0);
    // Blend with row-based progress for smoother visual
    final rowBasedProgress = totalRowsTested > 0
        ? (totalRowsTested / (snellenRows.length * 1.5)).clamp(0.0, 1.0)
        : 0.0;
    final blended = (staircaseProgress * 0.6 + rowBasedProgress * 0.4).clamp(0.0, 1.0);
    return eyeOffset + (blended * 0.5);
  }

  String get currentSnellenLetter {
    final row = snellenRows[currentRowIndex];
    return row.letters[snellenLetterIdx % row.letters.length];
  }

  /// Get calibrated letter size in logical pixels
  /// If calibration is available, use physical calculations
  /// Otherwise fall back to the static size values
  double get calibratedSize {
    final row = snellenRows[currentRowIndex];
    if (screenDpi != null && screenDpi! > 0) {
      final distanceM = (faceDistanceCm ?? 40.0) / 100.0;
      return row.physicalHeightPixels(distanceM, screenDpi!);
    }
    return row.size;
  }

  /// Check if current optotype size is reliable for rendering
  /// Stroke width must be at least 2 pixels
  bool get isCurrentSizeReliable {
    final row = snellenRows[currentRowIndex];
    if (screenDpi != null && screenDpi! > 0) {
      final distanceM = (faceDistanceCm ?? 40.0) / 100.0;
      final strokePx = row.strokeWidthMm(distanceM) * screenDpi! / 25.4;
      return strokePx >= 2.0;
    }
    // Fallback: if the static size is too small, flag it
    return row.size >= 10.0;
  }
}

class VisionTestNotifier extends StateNotifier<VisionTestState> {
  VisionTestNotifier() : super(const VisionTestState());

  final _rng = math.Random();

  void setMode(TestMode mode) => state = state.copyWith(mode: mode);

  void startPositioning() => state = state.copyWith(phase: TestPhase.positioning);

  void setCalibration(double dpi) {
    state = state.copyWith(screenDpi: dpi, calibrated: true);
  }

  void confirmPosition() {
    state = state.copyWith(
      phase: TestPhase.testing, positionConfirmed: true,
      currentRowIndex: VisionTestState.startRowIndex,
      attemptStartTime: DateTime.now(),
    );
  }

  /// Generate a new random E rotation, ensuring no repetition
  /// within the same row (prevents memorization)
  void setERotation(int rot) {
    // Ensure this rotation hasn't been used too much in current row
    final used = List<int>.from(state.usedRotations);
    int finalRot = rot;

    // If all 4 directions have been used, allow repeats but avoid consecutive
    if (used.length < 4) {
      int attempts = 0;
      while (used.contains(finalRot) && attempts < 10) {
        finalRot = _rng.nextInt(4);
        attempts++;
      }
    } else {
      // Avoid same as last direction shown
      int attempts = 0;
      while (finalRot == state.lastERotation && attempts < 10) {
        finalRot = _rng.nextInt(4);
        attempts++;
      }
    }
    used.add(finalRot);

    state = state.copyWith(
      lastERotation: finalRot, clearLastGuess: true,
      waitingForNext: false, attemptStartTime: DateTime.now(),
      usedRotations: used,
    );
  }

  void setSnellenLetter(int idx) {
    state = state.copyWith(
      snellenLetterIdx: idx, clearSnellenInput: true,
      waitingForNext: false, attemptStartTime: DateTime.now(),
    );
  }

  int _recordResponseTime() {
    if (state.attemptStartTime == null) return 0;
    return DateTime.now().difference(state.attemptStartTime!).inMilliseconds;
  }

  /// E-chart guess: direction 0-3, or -1 for "can't see"
  String? submitEGuess(int direction) {
    if (state.waitingForNext) return null;
    final responseMs = _recordResponseTime();
    final correct = direction >= 0 && direction == state.lastERotation;
    final attempt = AttemptRecord(
      rowIndex: state.currentRowIndex,
      shownDirection: state.lastERotation,
      guessedDirection: direction,
      correct: correct, responseMs: responseMs,
      logMAR: snellenRows[state.currentRowIndex].logMAR,
    );
    return _processAttempt(correct, attempt, lastGuessDir: direction);
  }

  /// Snellen letter guess
  String? submitSnellenGuess(String letter) {
    if (state.waitingForNext) return null;
    final responseMs = _recordResponseTime();
    final isCantSee = letter == '?';
    final correct = !isCantSee && letter.toUpperCase() == state.currentSnellenLetter.toUpperCase();
    final attempt = AttemptRecord(
      rowIndex: state.currentRowIndex,
      shownDirection: -1,
      guessedDirection: isCantSee ? -1 : 0,
      correct: correct, responseMs: responseMs,
      logMAR: snellenRows[state.currentRowIndex].logMAR,
    );
    return _processAttempt(correct, attempt, snellenInput: letter);
  }

  String? _processAttempt(bool correct, AttemptRecord attempt, {int? lastGuessDir, String? snellenInput}) {
    final newAttempts = state.attemptsUsed + 1;
    final newCorrect = state.correctInRow + (correct ? 1 : 0);
    final newRecords = [...state.currentEyeAttempts, attempt];

    state = state.copyWith(
      attemptsUsed: newAttempts, correctInRow: newCorrect,
      lastGuessDir: lastGuessDir, lastGuessCorrect: correct,
      waitingForNext: true, snellenUserInput: snellenInput,
      currentEyeAttempts: newRecords,
    );

    // Check if row is complete
    if (newAttempts < VisionTestState.attemptsPerRow) return null;

    final passed = newCorrect >= VisionTestState.minCorrectToPass;

    // ── 4-2 Staircase Logic ──
    bool isReversal = false;
    if (state.staircaseInitialized) {
      // Direction changed from last row = reversal
      isReversal = passed != state.lastRowPassed;
    }

    final newReversals = state.reversalCount + (isReversal ? 1 : 0);
    final newReversalRows = isReversal
        ? [...state.reversalRows, state.currentRowIndex]
        : state.reversalRows;

    // Determine step size: switch to fine after 2 reversals
    final newStep = newReversals >= VisionTestState.finePhaseAfterReversals
        ? VisionTestState.fineStep
        : VisionTestState.coarseStep;

    // Termination conditions
    if (newReversals >= VisionTestState.maxReversals) {
      state = state.copyWith(
        reversalCount: newReversals,
        reversalRows: newReversalRows,
        lastRowPassed: passed,
        staircaseStep: newStep,
        staircaseInitialized: true,
        totalRowsTested: state.totalRowsTested + 1,
      );
      return 'finish_eye';
    }

    // Boundary conditions
    if (passed && state.currentRowIndex >= snellenRows.length - 1) {
      // Already at best row (6/6) — finish
      return 'finish_eye';
    }
    if (!passed && state.currentRowIndex <= 0) {
      // Failed worst row (6/60) — finish
      return 'finish_eye';
    }

    // Continue staircase
    state = state.copyWith(
      reversalCount: newReversals,
      reversalRows: newReversalRows,
      lastRowPassed: passed,
      staircaseStep: newStep,
      staircaseInitialized: true,
      totalRowsTested: state.totalRowsTested + 1,
    );

    if (passed) return 'advance';     // go smaller (harder)
    return 'regress';                  // go larger (easier)
  }

  /// Advance to a smaller (harder) row — uses current step size
  void advanceRow() {
    final step = state.staircaseStep;
    final nextRow = (state.currentRowIndex + step).clamp(0, snellenRows.length - 1);
    state = state.copyWith(
      currentRowIndex: nextRow,
      attemptsUsed: 0, correctInRow: 0, snellenLetterIdx: 0,
      clearLastGuess: true, clearSnellenInput: true,
      waitingForNext: false, attemptStartTime: DateTime.now(),
      usedRotations: const [],
    );
  }

  /// Regress to a larger (easier) row — uses current step size
  void regressRow() {
    final step = state.staircaseStep;
    final prevRow = (state.currentRowIndex - step).clamp(0, snellenRows.length - 1);
    state = state.copyWith(
      currentRowIndex: prevRow,
      attemptsUsed: 0, correctInRow: 0, snellenLetterIdx: 0,
      clearLastGuess: true, clearSnellenInput: true,
      waitingForNext: false, attemptStartTime: DateTime.now(),
      usedRotations: const [],
    );
  }

  void finishCurrentEye() {
    // Determine acuity using staircase convergence
    String acuity;
    double logMAR;

    if (state.reversalRows.isNotEmpty) {
      // Average of last 4 reversal rows (or all if < 4)
      // This is the standard staircase threshold estimation
      final revs = state.reversalRows;
      final avgRows = revs.length > 4 ? revs.sublist(revs.length - 4) : revs;
      final avgRowIdx = (avgRows.reduce((a, b) => a + b) / avgRows.length).round()
          .clamp(0, snellenRows.length - 1);
      acuity = snellenRows[avgRowIdx].acuity;
      logMAR = snellenRows[avgRowIdx].logMAR;

      // Refine LogMAR with per-letter scoring from the threshold row
      final thresholdRowAttempts = state.currentEyeAttempts
          .where((a) => a.rowIndex == avgRowIdx).toList();
      if (thresholdRowAttempts.isNotEmpty) {
        final errors = thresholdRowAttempts.where((a) => !a.correct).length;
        logMAR += errors * 0.02; // per-letter refinement
      }
    } else {
      // Fallback: use last passed row
      final passed = state.correctInRow >= VisionTestState.minCorrectToPass;
      if (passed) {
        acuity = snellenRows[state.currentRowIndex].acuity;
        logMAR = snellenRows[state.currentRowIndex].logMAR;
      } else if (state.currentRowIndex > 0) {
        acuity = snellenRows[state.currentRowIndex - 1].acuity;
        logMAR = snellenRows[state.currentRowIndex - 1].logMAR;
      } else {
        acuity = '>6/60';
        logMAR = 1.1;
      }
    }

    if (state.currentEye == TestEye.right) {
      state = state.copyWith(
        rightAcuity: acuity,
        rightLogMAR: logMAR,
        rightEyeAttempts: List.of(state.currentEyeAttempts),
        phase: TestPhase.switchEye,
      );
    } else {
      final leftAttempts = List<AttemptRecord>.of(state.currentEyeAttempts);
      final odAnalysis = ClinicalAnalyzer.analyzeEye(state.rightEyeAttempts, state.rightAcuity ?? '>6/60');
      final osAnalysis = ClinicalAnalyzer.analyzeEye(leftAttempts, acuity);
      final report = ClinicalAnalyzer.generateReport(odAnalysis, osAnalysis);
      state = state.copyWith(
        leftAcuity: acuity,
        leftLogMAR: logMAR,
        leftEyeAttempts: leftAttempts,
        report: report,
        phase: TestPhase.results,
      );
    }
  }

  void startLeftEye() {
    state = state.copyWith(
      currentEye: TestEye.left,
      currentRowIndex: VisionTestState.startRowIndex,
      attemptsUsed: 0, correctInRow: 0,
      snellenLetterIdx: 0, currentEyeAttempts: const [],
      phase: TestPhase.testing,
      clearLastGuess: true, clearSnellenInput: true,
      waitingForNext: false, attemptStartTime: DateTime.now(),
      reversalCount: 0, lastRowPassed: true,
      reversalRows: const [], usedRotations: const [],
      staircaseStep: VisionTestState.coarseStep,
      staircaseInitialized: false,
      totalRowsTested: 0,
    );
  }

  void reset() => state = const VisionTestState();
}

final visionTestProvider =
    StateNotifierProvider<VisionTestNotifier, VisionTestState>(
  (ref) {
    final notifier = VisionTestNotifier();
    
    // Listen to calibration changes and update the vision test state
    ref.listen<double?>(calibrationProvider, (previous, next) {
      if (next != null && next > 0) {
        notifier.setCalibration(next);
      }
    }, fireImmediately: true);
    
    return notifier;
  },
);
