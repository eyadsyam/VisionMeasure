import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StepperField extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final double step;
  final int fractionDigits;
  final String? suffix;
  final ValueChanged<double> onChanged;

  const StepperField({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
    this.fractionDigits = 2,
    this.suffix,
  });

  void _set(double v) {
    final clamped = v.clamp(min, max);
    HapticFeedback.selectionClick();
    onChanged(double.parse(clamped.toStringAsFixed(fractionDigits)));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
                Text(
                  '${value.toStringAsFixed(fractionDigits)}${suffix ?? ''}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          _RoundIconButton(
            icon: Icons.remove_rounded,
            onTap: () => _set(value - step),
          ),
          const SizedBox(width: 6),
          _RoundIconButton(
            icon: Icons.add_rounded,
            onTap: () => _set(value + step),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.primary,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: cs.onPrimary, size: 20),
        ),
      ),
    );
  }
}
