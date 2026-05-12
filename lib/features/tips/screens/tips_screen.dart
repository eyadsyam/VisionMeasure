import 'package:flutter/material.dart';

import '../../../core/l10n/app_translations.dart';

class TipsScreen extends StatelessWidget {
  const TipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tips = const [
      _Tip(
        'tip1_title',
        'tip1_body',
        Icons.timer_outlined,
        Color(0xFF6366F1),
        LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
      ),
      _Tip(
        'tip2_title',
        'tip2_body',
        Icons.remove_red_eye_outlined,
        Color(0xFF0D9488),
        LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF14B8A6)]),
      ),
      _Tip(
        'tip3_title',
        'tip3_body',
        Icons.light_mode_outlined,
        Color(0xFFF59E0B),
        LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFF97316)]),
      ),
      _Tip(
        'tip4_title',
        'tip4_body',
        Icons.restaurant_outlined,
        Color(0xFF22C55E),
        LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF10B981)]),
      ),
      _Tip(
        'tip5_title',
        'tip5_body',
        Icons.wb_sunny_outlined,
        Color(0xFFEF4444),
        LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFF97316)]),
      ),
      _Tip(
        'tip6_title',
        'tip6_body',
        Icons.medical_services_outlined,
        Color(0xFF0EA5E9),
        LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)]),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('tips_title'))),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: tips.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (ctx, i) {
            final t = tips[i];
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155).withValues(alpha: 0.5)
                      : const Color(0xFFE2E8F0),
                ),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: t.gradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: t.color.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(t.icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(t.titleKey),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.tr(t.bodyKey),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: cs.onSurfaceVariant,
                                height: 1.5,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Tip {
  final String titleKey;
  final String bodyKey;
  final IconData icon;
  final Color color;
  final LinearGradient gradient;
  const _Tip(this.titleKey, this.bodyKey, this.icon, this.color, this.gradient);
}
