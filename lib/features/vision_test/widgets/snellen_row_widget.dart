import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/snellen_data.dart';

class SnellenRowWidget extends StatelessWidget {
  final SnellenRow row;
  final Set<int> readIndices;
  final ValueChanged<int> onLetterTap;

  const SnellenRowWidget({
    super.key,
    required this.row,
    required this.readIndices,
    required this.onLetterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < row.letters.length; i++)
          _LetterTile(
            letter: row.letters[i],
            size: row.size,
            read: readIndices.contains(i),
            onTap: () {
              HapticFeedback.selectionClick();
              onLetterTap(i);
            },
          ),
      ],
    );
  }
}

class _LetterTile extends StatelessWidget {
  final String letter;
  final double size;
  final bool read;
  final VoidCallback onTap;

  const _LetterTile({
    required this.letter,
    required this.size,
    required this.read,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tileSize = (size + 32).clamp(56.0, 160.0);
    return Semantics(
      label: 'Letter $letter, ${read ? 'marked as read' : 'tap if you can read it'}',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: tileSize,
          height: tileSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: read ? cs.primary : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Text(
            letter,
            style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w700,
              color: read ? cs.onPrimary : cs.onSurface,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }
}
