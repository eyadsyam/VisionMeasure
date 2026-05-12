import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n/app_translations.dart';

/// An 'E' rotated to 4 possible orientations. User picks direction.
/// Rotation mapping:
///   0 = E opens RIGHT  (default E)
///   1 = E opens DOWN   (rotated 90° clockwise)
///   2 = E opens LEFT   (rotated 180°)
///   3 = E opens UP     (rotated 270° clockwise)
class EChartWidget extends StatelessWidget {
  final double size;
  final int rotationQuarterTurns; // 0=right, 1=down, 2=left, 3=up
  final ValueChanged<int> onGuess;
  final int? lastGuess;
  final bool? correct;

  const EChartWidget({
    super.key,
    required this.size,
    required this.rotationQuarterTurns,
    required this.onGuess,
    this.lastGuess,
    this.correct,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // E display container
        Container(
          width: size + 48,
          height: size + 48,
          alignment: Alignment.center,
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
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: RotatedBox(
            // RotatedBox uses quarter turns: 0=0°, 1=90° CW, 2=180°, 3=270° CW
            quarterTurns: rotationQuarterTurns,
            child: Text(
              'E',
              style: TextStyle(
                fontSize: size,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
                color: cs.onSurface,
                height: 1.0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          context.tr('which_direction_e'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 16),
        // Force LTR so arrow positions don't flip in RTL locales —
        // directional arrows are absolute, not text-directional.
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 3 * 60 + 2 * 10, // 3 columns × button width + gaps
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // top row: up arrow centered
                _DirectionButton(
                  icon: Icons.arrow_upward_rounded,
                  label: 'UP',
                  onTap: () => _tap(3),
                  isCorrect: lastGuess == 3 ? correct : null,
                ),
                const SizedBox(height: 10),
                // middle row: left — spacer — right
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _DirectionButton(
                      icon: Icons.arrow_back_rounded,
                      label: 'LEFT',
                      onTap: () => _tap(2),
                      isCorrect: lastGuess == 2 ? correct : null,
                    ),
                    const SizedBox(width: 60), // empty center
                    _DirectionButton(
                      icon: Icons.arrow_forward_rounded,
                      label: 'RIGHT',
                      onTap: () => _tap(0),
                      isCorrect: lastGuess == 0 ? correct : null,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // bottom row: down arrow centered
                _DirectionButton(
                  icon: Icons.arrow_downward_rounded,
                  label: 'DOWN',
                  onTap: () => _tap(1),
                  isCorrect: lastGuess == 1 ? correct : null,
                ),
              ],
            ),
          ),
        ),
        if (lastGuess != null && correct != null) ...[
          const SizedBox(height: 14),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: correct!
                  ? const Color(0xFF22C55E).withValues(alpha: 0.12)
                  : const Color(0xFFEF4444).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              correct!
                  ? context.tr('correct_check')
                  : context.tr('try_again_check'),
              style: TextStyle(
                color: correct!
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFEF4444),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _tap(int dir) {
    HapticFeedback.selectionClick();
    onGuess(dir);
  }
}

class _DirectionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool? isCorrect; // null = not pressed, true = correct, false = wrong

  const _DirectionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor;
    Color fgColor;
    Color borderColor;

    if (isCorrect == true) {
      bgColor = const Color(0xFF22C55E).withValues(alpha: 0.15);
      fgColor = const Color(0xFF22C55E);
      borderColor = const Color(0xFF22C55E).withValues(alpha: 0.5);
    } else if (isCorrect == false) {
      bgColor = const Color(0xFFEF4444).withValues(alpha: 0.15);
      fgColor = const Color(0xFFEF4444);
      borderColor = const Color(0xFFEF4444).withValues(alpha: 0.5);
    } else {
      bgColor = isDark
          ? const Color(0xFF1E293B)
          : cs.surfaceContainerHighest;
      fgColor = cs.primary;
      borderColor = isDark
          ? const Color(0xFF334155).withValues(alpha: 0.5)
          : const Color(0xFFE2E8F0);
    }

    return SizedBox(
      width: 60,
      height: 60,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Icon(icon, size: 28, color: fgColor),
          ),
        ),
      ),
    );
  }
}
