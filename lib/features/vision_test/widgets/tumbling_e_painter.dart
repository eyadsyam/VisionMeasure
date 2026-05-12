import 'dart:math' as math;
import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════
/// Medical-Grade Tumbling E Optotype Painter
/// ═══════════════════════════════════════════════════════════════════
///
/// Renders the Tumbling E optotype according to ISO 8596 / BS 4274-1
/// specifications:
///
///   • 5×5 grid design
///   • Stroke width = 1/5 of letter height
///   • Gap width = 1/5 of letter height (equal to stroke)
///   • 3 horizontal arms (top, middle, bottom)
///   • 1 vertical spine
///   • Arms are opening directions: RIGHT(0), DOWN(1), LEFT(2), UP(3)
///
/// Anti-aliasing is DISABLED for clinical accuracy — smoothing
/// can artificially alter apparent letter sharpness.
///
/// The painter uses CustomPainter for pixel-perfect rendering,
/// NOT text glyphs (which vary across fonts/platforms).
/// ═══════════════════════════════════════════════════════════════════

class TumblingEPainter extends CustomPainter {
  /// Rotation: 0=RIGHT, 1=DOWN, 2=LEFT, 3=UP
  final int direction;

  /// Color of the optotype
  final Color color;

  /// If true, draws a high-contrast optotype with no anti-aliasing
  final bool clinicalMode;

  const TumblingEPainter({
    required this.direction,
    this.color = Colors.black,
    this.clinicalMode = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Use the smaller dimension to ensure square optotype
    final optotypeSize = math.min(size.width, size.height);
    final unit = optotypeSize / 5.0; // Each grid unit

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = !clinicalMode; // Disable AA for clinical accuracy

    // Center the optotype in the available space
    final offsetX = (size.width - optotypeSize) / 2.0;
    final offsetY = (size.height - optotypeSize) / 2.0;

    canvas.save();
    canvas.translate(offsetX, offsetY);

    // Apply rotation around center
    if (direction != 0) {
      final center = optotypeSize / 2.0;
      canvas.translate(center, center);
      canvas.rotate(direction * math.pi / 2.0);
      canvas.translate(-center, -center);
    }

    // Draw E opening to the RIGHT (default orientation)
    // Grid layout (5×5):
    //
    //  ██████████   Row 0: full top arm
    //  ██            Row 1: spine only
    //  ████████      Row 2: middle arm (shorter by 1 unit on right)
    //  ██            Row 3: spine only
    //  ██████████   Row 4: full bottom arm
    //
    // More precisely for E opening RIGHT:
    //
    // Vertical spine: x=[0, unit], y=[0, 5*unit]
    // Top arm:    x=[0, 5*unit], y=[0, unit]
    // Middle arm: x=[0, 5*unit], y=[2*unit, 3*unit]
    // Bottom arm: x=[0, 5*unit], y=[4*unit, 5*unit]

    // Vertical spine (left side)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, unit, 5 * unit),
      paint,
    );

    // Top arm
    canvas.drawRect(
      Rect.fromLTWH(unit, 0, 4 * unit, unit),
      paint,
    );

    // Middle arm
    canvas.drawRect(
      Rect.fromLTWH(unit, 2 * unit, 4 * unit, unit),
      paint,
    );

    // Bottom arm
    canvas.drawRect(
      Rect.fromLTWH(unit, 4 * unit, 4 * unit, unit),
      paint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant TumblingEPainter old) =>
      old.direction != direction ||
      old.color != color ||
      old.clinicalMode != clinicalMode;
}

/// Widget wrapper for the TumblingEPainter
/// Provides convenient sizing and animation support
class TumblingEOptotype extends StatelessWidget {
  /// Physical display size in logical pixels
  final double size;

  /// Direction: 0=RIGHT, 1=DOWN, 2=LEFT, 3=UP
  final int direction;

  /// Optotype color (should be high contrast against background)
  final Color color;

  /// Whether to render in clinical mode (no anti-aliasing)
  final bool clinicalMode;

  const TumblingEOptotype({
    super.key,
    required this.size,
    required this.direction,
    this.color = Colors.black,
    this.clinicalMode = true,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(size),
        painter: TumblingEPainter(
          direction: direction,
          color: color,
          clinicalMode: clinicalMode,
        ),
      ),
    );
  }
}
