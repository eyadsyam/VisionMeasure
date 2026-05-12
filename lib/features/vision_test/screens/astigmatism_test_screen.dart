import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/l10n/app_translations.dart';
import '../../../models/vision_record.dart';

enum _TestStep {
  rightEyeCheck,
  rightEyeAxis,
  leftEyeCheck,
  leftEyeAxis,
  done,
}

class AstigmatismTestScreen extends StatefulWidget {
  const AstigmatismTestScreen({super.key});

  @override
  State<AstigmatismTestScreen> createState() => _AstigmatismTestScreenState();
}

class _AstigmatismTestScreenState extends State<AstigmatismTestScreen> {
  _TestStep _step = _TestStep.rightEyeCheck;
  bool _rightUneven = false;
  bool _leftUneven = false;
  double _rightAxis = 0;
  double _leftAxis = 0;
  double _currentSelection = 0;

  void _answerUneven(bool uneven) {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_step == _TestStep.rightEyeCheck) {
        _rightUneven = uneven;
        if (uneven) {
          _currentSelection = 0;
          _step = _TestStep.rightEyeAxis;
        } else {
          _step = _TestStep.leftEyeCheck;
        }
      } else if (_step == _TestStep.leftEyeCheck) {
        _leftUneven = uneven;
        if (uneven) {
          _currentSelection = 0;
          _step = _TestStep.leftEyeAxis;
        } else {
          _step = _TestStep.done;
        }
      }
    });
  }

  void _confirmAxis() {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_step == _TestStep.rightEyeAxis) {
        _rightAxis = _currentSelection;
        _step = _TestStep.leftEyeCheck;
      } else if (_step == _TestStep.leftEyeAxis) {
        _leftAxis = _currentSelection;
        _step = _TestStep.done;
      }
    });
  }

  Future<void> _save() async {
    final box = Hive.box<VisionRecord>('vision_records');
    final rec = VisionRecord(
      id: const Uuid().v4(),
      createdAt: DateTime.now(),
      testType: 'astigmatism',
      notes:
          'OD: ${_rightUneven ? "uneven (Axis ${_rightAxis.toInt()}°)" : "equal"}, OS: ${_leftUneven ? "uneven (Axis ${_leftAxis.toInt()}°)" : "equal"}',
      odCylinder: _rightUneven ? -0.75 : 0,
      odAxis: _rightUneven ? _rightAxis : 0,
      osCylinder: _leftUneven ? -0.75 : 0,
      osAxis: _leftUneven ? _leftAxis : 0,
    );
    await box.put(rec.id, rec);
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('profile_saved'))),
    );
    context.go('/history');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    String eyeLabel = '';
    String stepText = '';
    bool isAxisSelection = false;

    switch (_step) {
      case _TestStep.rightEyeCheck:
        eyeLabel = context.tr('right_eye');
        stepText = '1/4';
        break;
      case _TestStep.rightEyeAxis:
        eyeLabel = context.tr('right_eye');
        stepText = '2/4';
        isAxisSelection = true;
        break;
      case _TestStep.leftEyeCheck:
        eyeLabel = context.tr('left_eye');
        stepText = '3/4';
        break;
      case _TestStep.leftEyeAxis:
        eyeLabel = context.tr('left_eye');
        stepText = '4/4';
        isAxisSelection = true;
        break;
      case _TestStep.done:
        eyeLabel = context.tr('done');
        break;
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('astigmatism_check'))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _step == _TestStep.done
              ? _ResultView(
                  rightUneven: _rightUneven,
                  leftUneven: _leftUneven,
                  rightAxis: _rightAxis,
                  leftAxis: _leftAxis,
                  onSave: _save,
                )
              : Column(
                  children: [
                    // Eye indicator badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF134E4A).withValues(alpha: 0.4)
                            : const Color(0xFFCCFBF1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF14B8A6)
                                  .withValues(alpha: 0.2)
                              : const Color(0xFF14B8A6)
                                  .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.visibility_rounded,
                              color: cs.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${context.tr('which_eye')} — $eyeLabel',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          // Step indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              stepText,
                              style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isAxisSelection
                          ? 'استخدم المؤشر لاختيار الخط الأغمق والأكثر وضوحاً'
                          : context.tr('astigmatism_instr'),
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                                height: 1.5,
                              ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (ctx, cons) {
                          final dim =
                              math.min(cons.maxWidth, cons.maxHeight);
                          return Center(
                            child: RepaintBoundary(
                              child: CustomPaint(
                                size: Size.square(dim),
                                painter: _InteractiveRadialFanPainter(
                                  color: cs.onSurface,
                                  highlightColor: cs.primary,
                                  selectedAxis: isAxisSelection ? _currentSelection : null,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isAxisSelection) ...[
                      // Axis slider
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          children: [
                            Text('0°', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Slider(
                                value: _currentSelection,
                                min: 0,
                                max: 165,
                                divisions: 11,
                                label: '${_currentSelection.toInt()}°',
                                onChanged: (val) {
                                  setState(() {
                                    _currentSelection = val;
                                  });
                                  HapticFeedback.selectionClick();
                                },
                              ),
                            ),
                            Text('165°', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: _confirmAxis,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                        ),
                        child: const Text('تأكيد المحور', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _answerUneven(false),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(54),
                              ),
                              child: Text(
                                context.tr('all_lines_equal'),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => _answerUneven(true),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(54),
                              ),
                              child: Text(
                                context.tr('some_lines_darker'),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final bool rightUneven;
  final bool leftUneven;
  final double rightAxis;
  final double leftAxis;
  final VoidCallback onSave;

  const _ResultView({
    required this.rightUneven,
    required this.leftUneven,
    required this.rightAxis,
    required this.leftAxis,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final likely = rightUneven || leftUneven;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: likely
                ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                : const Color(0xFF10B981).withValues(alpha: 0.12),
          ),
          child: Icon(
            likely
                ? Icons.warning_amber_rounded
                : Icons.check_circle_rounded,
            size: 40,
            color: likely
                ? const Color(0xFFF59E0B)
                : const Color(0xFF10B981),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          likely
              ? context.tr('astigmatism_likely')
              : context.tr('astigmatism_unlikely'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF334155).withValues(alpha: 0.5)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            children: [
              _row(
                context,
                context.tr('right_eye'),
                rightUneven
                    ? '${context.tr('some_lines_darker')} (${rightAxis.toInt()}°)'
                    : context.tr('all_lines_equal'),
                rightUneven,
              ),
              Divider(
                height: 20,
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
              _row(
                context,
                context.tr('left_eye'),
                leftUneven
                    ? '${context.tr('some_lines_darker')} (${leftAxis.toInt()}°)'
                    : context.tr('all_lines_equal'),
                leftUneven,
              ),
            ],
          ),
        ),
        const Spacer(),
        FilledButton(
          onPressed: onSave,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(58),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.save_rounded, size: 20),
              const SizedBox(width: 8),
              Text(
                context.tr('save_result'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Disclaimer
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF78350F).withValues(alpha: 0.15)
                : const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? const Color(0xFFFCD34D).withValues(alpha: 0.2)
                  : const Color(0xFFF59E0B).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: isDark
                    ? const Color(0xFFFCD34D)
                    : const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr('medical_disclaimer'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.4,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, String k, String v, bool uneven) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: uneven
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                  : const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              v,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: uneven
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF10B981),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints a 12-spoke radial fan chart for astigmatism screening with axis selection.
class _InteractiveRadialFanPainter extends CustomPainter {
  final Color color;
  final Color highlightColor;
  final double? selectedAxis;

  _InteractiveRadialFanPainter({
    required this.color,
    required this.highlightColor,
    this.selectedAxis,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 20;

    const int spokes = 12; // 0, 15, 30 ... 165
    
    // Draw numbers
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < spokes; i++) {
      final angleDeg = i * 15.0;
      final angleRad = angleDeg * math.pi / 180.0;

      final dx = math.cos(angleRad) * radius;
      final dy = -math.sin(angleRad) * radius; // y is down in Flutter

      final isSelected = selectedAxis != null && (selectedAxis! - angleDeg).abs() < 1;

      final paint = Paint()
        ..color = isSelected ? highlightColor : color
        ..strokeWidth = isSelected ? 5.5 : 3.0
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(center.dx - dx, center.dy - dy),
        Offset(center.dx + dx, center.dy + dy),
        paint,
      );

      // Draw degrees labels on the outer edge
      final labelRadius = radius + 14;
      final labelDx = math.cos(angleRad) * labelRadius;
      final labelDy = -math.sin(angleRad) * labelRadius;

      textPainter.text = TextSpan(
        text: '${angleDeg.toInt()}°',
        style: TextStyle(
          color: isSelected ? highlightColor : color.withValues(alpha: 0.6),
          fontSize: isSelected ? 12 : 10,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        ),
      );
      textPainter.layout();
      
      // Draw label on one side
      canvas.save();
      canvas.translate(center.dx + labelDx, center.dy + labelDy);
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
      
      // Draw label on the opposite side
      canvas.save();
      canvas.translate(center.dx - labelDx, center.dy - labelDy);
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }

    // Center dot
    final dot = Paint()..color = selectedAxis != null ? highlightColor : color;
    canvas.drawCircle(center, 6, dot);
  }

  @override
  bool shouldRepaint(covariant _InteractiveRadialFanPainter old) =>
      old.color != color ||
      old.highlightColor != highlightColor ||
      old.selectedAxis != selectedAxis;
}
