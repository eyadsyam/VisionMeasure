import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/snellen_data.dart';
import '../../../core/l10n/app_translations.dart';
import '../../../models/vision_record.dart';
import '../providers/vision_test_provider.dart';
import '../widgets/tumbling_e_painter.dart';

class VisionTestScreen extends ConsumerStatefulWidget {
  const VisionTestScreen({super.key});
  @override
  ConsumerState<VisionTestScreen> createState() => _State();
}

class _State extends ConsumerState<VisionTestScreen> {
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(visionTestProvider.notifier).reset();
    });
  }

  void _newStimulus() {
    final n = ref.read(visionTestProvider.notifier);
    final s = ref.read(visionTestProvider);
    if (s.mode == TestMode.eChart) {
      n.setERotation(_rng.nextInt(4));
    } else {
      final row = snellenRows[s.currentRowIndex];
      n.setSnellenLetter(_rng.nextInt(row.letters.length));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(visionTestProvider);
    return Scaffold(
      body: SafeArea(child: switch (s.phase) {
        TestPhase.instructions => _buildInstructions(s),
        TestPhase.calibration => _buildPositioning(),
        TestPhase.positioning => _buildPositioning(),
        TestPhase.testing => _buildTesting(s),
        TestPhase.switchEye => _buildSwitch(s),
        TestPhase.results => _buildResults(s),
      }),
    );
  }

  // ── INSTRUCTIONS + TEST TYPE CHOICE ──
  Widget _buildInstructions(VisionTestState s) {
    final cs = Theme.of(context).colorScheme;
    return Padding(padding: const EdgeInsets.all(24), child: Column(children: [
      const Spacer(),
      Container(width: 80, height: 80,
        decoration: BoxDecoration(gradient: LinearGradient(colors: [cs.primary, cs.primary.withValues(alpha: .7)]), borderRadius: BorderRadius.circular(24)),
        child: const Icon(Icons.visibility_rounded, color: Colors.white, size: 40)),
      const SizedBox(height: 20),
      Text(context.tr('test_intro_title'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800), textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Text(context.tr('test_intro_sub'), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.5), textAlign: TextAlign.center),
      const SizedBox(height: 28),
      // Test type selector
      Text(context.tr('choose_test_type'), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      Row(children: [
        _typeCard('E', context.tr('echart_label'), s.mode == TestMode.eChart, () => ref.read(visionTestProvider.notifier).setMode(TestMode.eChart)),
        const SizedBox(width: 12),
        _typeCard('Aa', context.tr('snellen_label'), s.mode == TestMode.snellen, () => ref.read(visionTestProvider.notifier).setMode(TestMode.snellen)),
      ]),
      const SizedBox(height: 24),
      for (final step in [
        (Icons.straighten_rounded, context.tr('test_step1')),
        (Icons.remove_red_eye_outlined, context.tr('test_step2')),
        (Icons.touch_app_rounded, context.tr('test_step3')),
      ]) Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: cs.primary.withValues(alpha: .1), borderRadius: BorderRadius.circular(10)),
          child: Icon(step.$1, size: 18, color: cs.primary)),
        const SizedBox(width: 12),
        Expanded(child: Text(step.$2, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500))),
      ])),
      const Spacer(flex: 2),
      SizedBox(width: double.infinity, height: 54, child: FilledButton(
        onPressed: () => ref.read(visionTestProvider.notifier).startPositioning(),
        child: Text(context.tr('test_start_btn'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))),
      const SizedBox(height: 6),
      TextButton(onPressed: () => context.pop(), child: Text(context.tr('cancel'))),
    ]));
  }

  Widget _typeCard(String icon, String label, bool sel, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    final dk = Theme.of(context).brightness == Brightness.dark;
    return Expanded(child: Material(
      color: sel ? cs.primary.withValues(alpha: .12) : dk ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16),
        child: Container(padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
            border: Border.all(color: sel ? cs.primary : dk ? const Color(0xFF334155) : const Color(0xFFE2E8F0), width: sel ? 2 : 1)),
          child: Column(children: [
            Text(icon, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'monospace', color: sel ? cs.primary : cs.onSurface)),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? cs.primary : cs.onSurface, fontSize: 13)),
          ])))));
  }

  // ── POSITIONING ──
  Widget _buildPositioning() {
    final cs = Theme.of(context).colorScheme;
    return Padding(padding: const EdgeInsets.all(24), child: Column(children: [
      const Spacer(),
      Icon(Icons.person_outline_rounded, size: 72, color: cs.primary),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.phone_android_rounded, size: 28, color: cs.onSurfaceVariant),
        Container(width: 80, height: 2, color: cs.outlineVariant, margin: const EdgeInsets.symmetric(horizontal: 8)),
        Icon(Icons.accessibility_new_rounded, size: 40, color: cs.primary),
      ]),
      const SizedBox(height: 24),
      Text(context.tr('position_title'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800), textAlign: TextAlign.center),
      const SizedBox(height: 10),
      Text(context.tr('position_sub'), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.5), textAlign: TextAlign.center),
      const SizedBox(height: 20),
      for (final t in [
        (Icons.straighten_rounded, context.tr('position_tip1')),
        (Icons.visibility_off_rounded, context.tr('position_tip2')),
        (Icons.light_mode_rounded, context.tr('position_tip3')),
      ]) Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
        Icon(t.$1, size: 18, color: cs.primary), const SizedBox(width: 10),
        Expanded(child: Text(t.$2, style: Theme.of(context).textTheme.bodySmall)),
      ])),
      const Spacer(flex: 2),
      SizedBox(width: double.infinity, height: 54, child: FilledButton(
        onPressed: () { ref.read(visionTestProvider.notifier).confirmPosition(); _newStimulus(); },
        child: Text(context.tr('position_ready'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))),
      const SizedBox(height: 6),
      TextButton(onPressed: () => context.pop(), child: Text(context.tr('back'))),
    ]));
  }

  // ── ACTIVE TEST ──
  Widget _buildTesting(VisionTestState s) {
    final cs = Theme.of(context).colorScheme;
    final row = snellenRows[s.currentRowIndex];
    return Column(children: [
      // Top bar
      Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 0), child: Row(children: [
        IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close_rounded)),
        Expanded(child: Column(children: [
          Text(s.currentEye == TestEye.right ? context.tr('right_eye') : context.tr('left_eye'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          ClipRRect(borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: s.overallProgress, minHeight: 5,
              backgroundColor: cs.outlineVariant.withValues(alpha: .3), valueColor: AlwaysStoppedAnimation(cs.primary))),
        ])),
        const SizedBox(width: 48),
      ])),
      // Row info + LogMAR + attempt dots
      Padding(padding: const EdgeInsets.fromLTRB(18, 10, 18, 0), child: Row(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: cs.primary.withValues(alpha: .1), borderRadius: BorderRadius.circular(8)),
          child: Text(row.acuity, style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800, fontSize: 14))),
        const SizedBox(width: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: cs.tertiary.withValues(alpha: .1), borderRadius: BorderRadius.circular(8)),
          child: Text('LogMAR ${row.logMAR.toStringAsFixed(1)}', style: TextStyle(color: cs.tertiary, fontWeight: FontWeight.w600, fontSize: 11))),
        const Spacer(),
        Row(children: List.generate(VisionTestState.attemptsPerRow, (i) {
          Color c = cs.outlineVariant;
          if (i < s.attemptsUsed) c = (i < s.correctInRow) ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
          return Container(width: 10, height: 10, margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(shape: BoxShape.circle, color: c));
        })),
      ])),
      // Stimulus display — medical-grade optotype rendering
      Expanded(child: Center(child: AnimatedSwitcher(duration: const Duration(milliseconds: 200),
        child: s.mode == TestMode.eChart
          ? Container(
              key: ValueKey('e_${s.currentRowIndex}_${s.attemptsUsed}_${s.lastERotation}'),
              child: TumblingEOptotype(
                size: s.calibratedSize.clamp(16.0, 200.0),
                direction: s.lastERotation,
                color: cs.onSurface,
                clinicalMode: true,
              ))
          : Text(s.currentSnellenLetter, key: ValueKey('sn_${s.currentRowIndex}_${s.attemptsUsed}_${s.snellenLetterIdx}'),
              style: TextStyle(fontSize: s.calibratedSize.clamp(16.0, 200.0), fontWeight: FontWeight.w900, fontFamily: 'monospace', color: cs.onSurface, height: 1.0)),
      ))),
      // Feedback
      if (s.lastGuessCorrect != null)
        Container(margin: const EdgeInsets.symmetric(horizontal: 20), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: (s.lastGuessCorrect! ? const Color(0xFF22C55E) : const Color(0xFFEF4444)).withValues(alpha: .12), borderRadius: BorderRadius.circular(10)),
          child: Text(s.lastGuessCorrect! ? '✓ ${context.tr('correct_check')}' : '✗ ${context.tr('try_again_check')}', textAlign: TextAlign.center,
            style: TextStyle(color: s.lastGuessCorrect! ? const Color(0xFF22C55E) : const Color(0xFFEF4444), fontWeight: FontWeight.w700))),
      const SizedBox(height: 8),
      // Input area
      if (s.mode == TestMode.eChart) _eChartButtons(s)
      else _snellenInput(s),
      const SizedBox(height: 16),
    ]);
  }

  Widget _eChartButtons(VisionTestState s) {
    final cs = Theme.of(context).colorScheme;
    return Directionality(textDirection: TextDirection.ltr,
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 40), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(context.tr('which_direction_e'), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 10),
        _dBtn(Icons.arrow_upward_rounded, 3, s),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _dBtn(Icons.arrow_back_rounded, 2, s),
          const SizedBox(width: 72),
          _dBtn(Icons.arrow_forward_rounded, 0, s),
        ]),
        const SizedBox(height: 8),
        _dBtn(Icons.arrow_downward_rounded, 1, s),
        const SizedBox(height: 24),
        TextButton.icon(
          onPressed: s.waitingForNext ? null : () => _handleEGuess(-1),
          icon: const Icon(Icons.visibility_off_rounded, size: 18),
          label: Text(context.tr('cant_see')),
          style: TextButton.styleFrom(foregroundColor: cs.onSurfaceVariant),
        ),
      ])));
  }

  Widget _dBtn(IconData icon, int dir, VisionTestState s) {
    final cs = Theme.of(context).colorScheme;
    final dk = Theme.of(context).brightness == Brightness.dark;
    final isThis = s.lastGuessDir == dir;
    Color bg, fg, bd;
    if (isThis && s.lastGuessCorrect == true) { bg = const Color(0xFF22C55E).withValues(alpha: .15); fg = const Color(0xFF22C55E); bd = fg.withValues(alpha: .5); }
    else if (isThis && s.lastGuessCorrect == false) { bg = const Color(0xFFEF4444).withValues(alpha: .15); fg = const Color(0xFFEF4444); bd = fg.withValues(alpha: .5); }
    else { bg = dk ? const Color(0xFF1E293B) : cs.surfaceContainerHighest; fg = cs.primary; bd = dk ? const Color(0xFF334155).withValues(alpha: .5) : const Color(0xFFE2E8F0); }
    return SizedBox(width: 64, height: 64, child: Material(color: bg, borderRadius: BorderRadius.circular(18),
      child: InkWell(onTap: s.waitingForNext ? null : () => _handleEGuess(dir), borderRadius: BorderRadius.circular(18),
        child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: bd)),
          child: Icon(icon, size: 30, color: fg)))));
  }

  Widget _snellenInput(VisionTestState s) {
    final cs = Theme.of(context).colorScheme;
    final dk = Theme.of(context).brightness == Brightness.dark;
    final letters = ['E','F','P','T','O','Z','L','D','C'];
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(context.tr('which_letter'), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
        children: letters.map((l) {
          final isThis = s.snellenUserInput?.toUpperCase() == l;
          Color bg, fg, bd;
          if (isThis && s.lastGuessCorrect == true) { bg = const Color(0xFF22C55E).withValues(alpha: .15); fg = const Color(0xFF22C55E); bd = fg.withValues(alpha: .5); }
          else if (isThis && s.lastGuessCorrect == false) { bg = const Color(0xFFEF4444).withValues(alpha: .15); fg = const Color(0xFFEF4444); bd = fg.withValues(alpha: .5); }
          else { bg = dk ? const Color(0xFF1E293B) : cs.surfaceContainerHighest; fg = cs.primary; bd = dk ? const Color(0xFF334155).withValues(alpha: .5) : const Color(0xFFE2E8F0); }
          return SizedBox(width: 52, height: 52, child: Material(color: bg, borderRadius: BorderRadius.circular(14),
            child: InkWell(onTap: s.waitingForNext ? null : () => _handleSnellenGuess(l), borderRadius: BorderRadius.circular(14),
              child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: bd)),
                child: Center(child: Text(l, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'monospace', color: fg)))))));
        }).toList()),
      const SizedBox(height: 16),
      TextButton.icon(
        onPressed: s.waitingForNext ? null : () => _handleSnellenGuess('?'),
        icon: const Icon(Icons.visibility_off_rounded, size: 18),
        label: Text(context.tr('cant_see')),
        style: TextButton.styleFrom(foregroundColor: cs.onSurfaceVariant),
      ),
    ]);
  }

  void _handleEGuess(int dir) {
    HapticFeedback.selectionClick();
    final result = ref.read(visionTestProvider.notifier).submitEGuess(dir);
    _processResult(result);
  }

  void _handleSnellenGuess(String letter) {
    HapticFeedback.selectionClick();
    final result = ref.read(visionTestProvider.notifier).submitSnellenGuess(letter);
    _processResult(result);
  }

  void _processResult(String? result) {
    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      final n = ref.read(visionTestProvider.notifier);
      if (result == null) {
        _newStimulus();
      } else if (result == 'advance') {
        n.advanceRow();
        _newStimulus();
      } else if (result == 'regress') {
        n.regressRow();
        _newStimulus();
      } else {
        // 'finish_eye' or any other terminal result
        n.finishCurrentEye();
      }
    });
  }

  // ── SWITCH EYE ──
  Widget _buildSwitch(VisionTestState s) {
    final cs = Theme.of(context).colorScheme;
    return Padding(padding: const EdgeInsets.all(24), child: Column(children: [
      const Spacer(flex: 2),
      const Icon(Icons.check_circle_rounded, size: 64, color: Color(0xFF22C55E)),
      const SizedBox(height: 20),
      Text(context.tr('switch_eye_title'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800), textAlign: TextAlign.center),
      const SizedBox(height: 12),
      Text(context.tr('switch_eye_sub'), style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant, height: 1.5), textAlign: TextAlign.center),
      const SizedBox(height: 24),
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: cs.primary.withValues(alpha: .08), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Icon(Icons.visibility_rounded, color: cs.primary), const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.tr('right_eye'), style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
            Text(s.rightAcuity ?? '—', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            if (s.rightLogMAR != null)
              Text('LogMAR ${s.rightLogMAR!.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.tertiary, fontWeight: FontWeight.w600)),
            if (s.rightEyeAttempts.isNotEmpty)
              Text('${context.tr('avg_response')}: ${((s.rightEyeAttempts.map((a) => a.responseMs).reduce((a, b) => a + b) / s.rightEyeAttempts.length) / 1000).toStringAsFixed(1)}s',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ])),
        ])),
      const Spacer(flex: 3),
      SizedBox(width: double.infinity, height: 54, child: FilledButton(
        onPressed: () { ref.read(visionTestProvider.notifier).startLeftEye(); _newStimulus(); },
        child: Text(context.tr('switch_eye_btn'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))),
      const SizedBox(height: 16),
    ]));
  }

  // ── RESULTS ──
  Widget _buildResults(VisionTestState s) {
    final cs = Theme.of(context).colorScheme;
    final dk = Theme.of(context).brightness == Brightness.dark;
    return Padding(padding: const EdgeInsets.all(24), child: Column(children: [
      const Spacer(),
      Icon(Icons.assessment_rounded, size: 56, color: cs.primary),
      const SizedBox(height: 16),
      Text(context.tr('results_title'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 20),
      Row(children: [
        Expanded(child: _eyeResult(context.tr('right_eye'), s.report?.od)),
        const SizedBox(width: 12),
        Expanded(child: _eyeResult(context.tr('left_eye'), s.report?.os)),
      ]),
      const SizedBox(height: 16),
      Container(padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: dk ? const Color(0xFF78350F).withValues(alpha: .15) : const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(14), border: Border.all(color: dk ? const Color(0xFFFCD34D).withValues(alpha: .2) : const Color(0xFFF59E0B).withValues(alpha: .3))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline_rounded, size: 16, color: dk ? const Color(0xFFFCD34D) : const Color(0xFFF59E0B)),
          const SizedBox(width: 10),
          Expanded(child: Text(context.tr('medical_disclaimer'), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.4))),
        ])),
      const Spacer(flex: 2),
      SizedBox(width: double.infinity, height: 54, child: FilledButton(onPressed: _save,
        child: Text(context.tr('results_save'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))),
      const SizedBox(height: 16),
    ]));
  }

  Widget _eyeResult(String label, dynamic analysis) {
    if (analysis == null) return const SizedBox();
    final cs = Theme.of(context).colorScheme;
    final dk = Theme.of(context).brightness == Brightness.dark;

    // Severity color coding
    Color severityColor;
    switch (analysis.severity) {
      case 'Normal': severityColor = const Color(0xFF22C55E); break;
      case 'Mild': severityColor = const Color(0xFFF59E0B); break;
      case 'Moderate': severityColor = const Color(0xFFEF4444); break;
      default: severityColor = const Color(0xFFDC2626); break;
    }

    // Confidence color
    final confPct = (analysis.confidenceScore * 100).toInt();
    final confColor = confPct >= 70 ? const Color(0xFF22C55E) : confPct >= 50 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);
    
    return Container(padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: dk ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: dk ? const Color(0xFF334155).withValues(alpha: .5) : const Color(0xFFE2E8F0))),
      child: Column(children: [
        Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        // Main acuity
        Text(analysis.acuity, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        // LogMAR score
        Text('LogMAR ${analysis.logMARScore.toStringAsFixed(2)}', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        // Severity badge
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: severityColor.withValues(alpha: .12), borderRadius: BorderRadius.circular(6)),
          child: Text(analysis.severity, style: TextStyle(color: severityColor, fontSize: 11, fontWeight: FontWeight.w700))),
        const SizedBox(height: 4),
        Text(analysis.condition, style: TextStyle(color: cs.primary, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('SE: ${analysis.sphericalEq > 0 ? '+' : ''}${analysis.sphericalEq.toStringAsFixed(2)} D', style: TextStyle(color: cs.onSurface, fontSize: 12, fontWeight: FontWeight.w600)),
        if (analysis.cylinder != 0) ...[
          const SizedBox(height: 2),
          Text('Cyl: ${analysis.cylinder.toStringAsFixed(2)} @ ${analysis.axis}°', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
        ],
        const SizedBox(height: 6),
        // Accuracy + Response time
        Text('${(analysis.accuracy * 100).toInt()}% accuracy', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
        const SizedBox(height: 2),
        Text('⏱ ${(analysis.avgResponseMs / 1000).toStringAsFixed(1)}s avg', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
        const SizedBox(height: 4),
        // Confidence indicator
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(confPct >= 70 ? Icons.verified_rounded : Icons.warning_amber_rounded, size: 12, color: confColor),
          const SizedBox(width: 3),
          Text('$confPct% reliable', style: TextStyle(color: confColor, fontSize: 10, fontWeight: FontWeight.w600)),
        ]),
      ]));
  }

  Future<void> _save() async {
    final s = ref.read(visionTestProvider);
    final box = Hive.box<VisionRecord>('vision_records');
    final rec = VisionRecord(
      id: const Uuid().v4(), createdAt: DateTime.now(),
      testType: s.mode == TestMode.eChart ? 'echart' : 'snellen',
      odAcuity: s.rightAcuity, osAcuity: s.leftAcuity,
      odSphere: s.rightAcuity != null && s.rightAcuity != '>6/60' ? estimatedSphereForAcuity(s.rightAcuity!) : null,
      osSphere: s.leftAcuity != null && s.leftAcuity != '>6/60' ? estimatedSphereForAcuity(s.leftAcuity!) : null,
      odCylinder: s.report?.od.cylinder ?? 0.0,
      osCylinder: s.report?.os.cylinder ?? 0.0,
      odAxis: s.report?.od.axis.toDouble() ?? 0.0,
      osAxis: s.report?.os.axis.toDouble() ?? 0.0,
      faceDistanceCm: null,
      notes: s.report?.toJsonString() ?? '',
      snellenScore: null,
    );
    await box.put(rec.id, rec);
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    context.go('/history');
  }
}
