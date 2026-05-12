import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/l10n/app_translations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/vision_record.dart';
import '../providers/manual_entry_provider.dart';
import '../widgets/stepper_field.dart';

class ManualEntryScreen extends ConsumerWidget {
  const ManualEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(manualEntryProvider);
    final n = ref.read(manualEntryProvider.notifier);
    final result = s.calculate();
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('manual_entry')),
        actions: [
          Container(
            margin: const EdgeInsetsDirectional.only(end: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B)
                  : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              tooltip: context.tr('reset'),
              onPressed: n.reset,
              icon: Icon(
                Icons.refresh_rounded,
                color: cs.onSurfaceVariant,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Right eye section
            _EyeSection(
              label: context.tr('right_eye'),
              gradient: AppTheme.primaryGradient,
              icon: Icons.visibility_rounded,
              isDark: isDark,
              children: [
                StepperField(
                  label: context.tr('sphere'),
                  value: s.odSphere,
                  min: -20,
                  max: 20,
                  step: 0.25,
                  suffix: ' D',
                  onChanged: (v) => n.update((st) => st.copyWith(odSphere: v)),
                ),
                const SizedBox(height: 10),
                StepperField(
                  label: context.tr('cylinder'),
                  value: s.odCylinder,
                  min: -6,
                  max: 6,
                  step: 0.25,
                  suffix: ' D',
                  onChanged: (v) =>
                      n.update((st) => st.copyWith(odCylinder: v)),
                ),
                const SizedBox(height: 10),
                StepperField(
                  label: context.tr('axis'),
                  value: s.odAxis,
                  min: 0,
                  max: 180,
                  step: 1,
                  fractionDigits: 0,
                  suffix: '°',
                  onChanged: (v) => n.update((st) => st.copyWith(odAxis: v)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Left eye section
            _EyeSection(
              label: context.tr('left_eye'),
              gradient: AppTheme.accentGradient,
              icon: Icons.visibility_rounded,
              isDark: isDark,
              children: [
                StepperField(
                  label: context.tr('sphere'),
                  value: s.osSphere,
                  min: -20,
                  max: 20,
                  step: 0.25,
                  suffix: ' D',
                  onChanged: (v) => n.update((st) => st.copyWith(osSphere: v)),
                ),
                const SizedBox(height: 10),
                StepperField(
                  label: context.tr('cylinder'),
                  value: s.osCylinder,
                  min: -6,
                  max: 6,
                  step: 0.25,
                  suffix: ' D',
                  onChanged: (v) =>
                      n.update((st) => st.copyWith(osCylinder: v)),
                ),
                const SizedBox(height: 10),
                StepperField(
                  label: context.tr('axis'),
                  value: s.osAxis,
                  min: 0,
                  max: 180,
                  step: 1,
                  fractionDigits: 0,
                  suffix: '°',
                  onChanged: (v) => n.update((st) => st.copyWith(osAxis: v)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Results card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF134E4A).withValues(alpha: 0.4)
                    : const Color(0xFFCCFBF1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF14B8A6).withValues(alpha: 0.2)
                      : const Color(0xFF14B8A6).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.analytics_rounded,
                          size: 18,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        context.tr('live_calculation'),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _resLine(
                    context,
                    context.tr('od_se'),
                    '${result.odSphericalEquivalent.toStringAsFixed(2)} D',
                  ),
                  _resLine(
                    context,
                    context.tr('os_se'),
                    '${result.osSphericalEquivalent.toStringAsFixed(2)} D',
                  ),
                  Divider(
                    height: 24,
                    color: cs.primary.withValues(alpha: 0.2),
                  ),
                  _resLine(
                    context,
                    context.tr('od_classification'),
                    context.tr('cls_${result.odClassification}'),
                  ),
                  _resLine(
                    context,
                    context.tr('os_classification'),
                    context.tr('cls_${result.osClassification}'),
                  ),
                  const SizedBox(height: 6),
                  _resLine(
                    context,
                    context.tr('recommended_lens'),
                    context.tr('lens_${result.recommendedLensType}'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () async {
                final box = Hive.box<VisionRecord>('vision_records');
                final rec = VisionRecord(
                  id: const Uuid().v4(),
                  createdAt: DateTime.now(),
                  testType: 'manual',
                  odSphere: s.odSphere,
                  odCylinder: s.odCylinder,
                  odAxis: s.odAxis,
                  osSphere: s.osSphere,
                  osCylinder: s.osCylinder,
                  osAxis: s.osAxis,
                );
                await box.put(rec.id, rec);
                HapticFeedback.mediumImpact();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.tr('save_prescription'))),
                );
                context.go('/history');
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(58),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('save_prescription'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
        ),
      ),
    );
  }

  Widget _resLine(BuildContext context, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _EyeSection extends StatelessWidget {
  final String label;
  final LinearGradient gradient;
  final IconData icon;
  final bool isDark;
  final List<Widget> children;

  const _EyeSection({
    required this.label,
    required this.gradient,
    required this.icon,
    required this.isDark,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...children,
      ],
    );
  }
}
