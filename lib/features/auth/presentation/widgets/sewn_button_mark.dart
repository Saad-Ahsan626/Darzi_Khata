import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';

/// The four-hole button mark. Each part takes a 0–1 amount so the splash can
/// draw the rim, set the holes and pull the two cross-stitches through; the
/// defaults give the finished mark.
class SewnButtonMark extends StatelessWidget {
  const SewnButtonMark({
    super.key,
    this.size = 96,
    this.rim = 1,
    this.holes = 1,
    this.firstStitch = 1,
    this.secondStitch = 1,
    this.color = AppPalette.white,
  });

  final double size;
  final double rim;
  final double holes;
  final double firstStitch;
  final double secondStitch;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _SewnButtonPainter(
      rim: rim,
      holes: holes,
      firstStitch: firstStitch,
      secondStitch: secondStitch,
      color: color,
    ),
  );
}

class _SewnButtonPainter extends CustomPainter {
  const _SewnButtonPainter({
    required this.rim,
    required this.holes,
    required this.firstStitch,
    required this.secondStitch,
    required this.color,
  });

  final double rim;
  final double holes;
  final double firstStitch;
  final double secondStitch;
  final Color color;

  // Geometry from the design's 52-unit drawing.
  static const _viewBox = 52.0;
  static const _rimRadius = 18.0;
  static const _rimWidth = 1.8;
  static const _holeOffset = 5.5;
  static const _holeRadius = 2.3;
  static const _stitchReach = 7.66;
  static const _stitchWidth = 0.81;
  static const _stitchOpacity = 0.85;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / _viewBox;
    final center = size.center(Offset.zero);

    // The rim draws clockwise from twelve o'clock.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: _rimRadius * unit),
      -math.pi / 2,
      2 * math.pi * rim.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _rimWidth * unit,
    );

    final holePaint = Paint()
      ..color = color.withValues(alpha: color.a * holes.clamp(0.0, 1.0));
    for (final dx in const [-_holeOffset, _holeOffset]) {
      for (final dy in const [-_holeOffset, _holeOffset]) {
        canvas.drawCircle(
          center + Offset(dx, dy) * unit,
          _holeRadius * unit,
          holePaint,
        );
      }
    }

    // Each stitch grows from the centre out to a pair of opposite holes.
    void stitch(double amount, Offset direction) {
      final drawn = amount.clamp(0.0, 1.0);
      if (drawn == 0) return;
      final reach = direction * (_stitchReach * unit * drawn);
      canvas.drawLine(
        center - reach,
        center + reach,
        Paint()
          ..color = color.withValues(alpha: color.a * _stitchOpacity * drawn)
          ..strokeWidth = _stitchWidth * unit,
      );
    }

    stitch(firstStitch, const Offset(1, 1));
    stitch(secondStitch, const Offset(1, -1));
  }

  @override
  bool shouldRepaint(_SewnButtonPainter oldDelegate) =>
      oldDelegate.rim != rim ||
      oldDelegate.holes != holes ||
      oldDelegate.firstStitch != firstStitch ||
      oldDelegate.secondStitch != secondStitch ||
      oldDelegate.color != color;
}
