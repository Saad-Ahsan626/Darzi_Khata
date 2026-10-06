import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// A one-pixel dashed rule, used between rows and inside cards.
class AppDashedLine extends StatelessWidget {
  const AppDashedLine({super.key, this.color = AppPalette.lineStrong});
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 1,
    width: double.infinity,
    child: CustomPaint(painter: _DashedLinePainter(color)),
  );
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter(this.color);
  final Color color;

  static const _dash = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height;
    final y = size.height / 2;
    for (double x = 0; x < size.width; x += _dash * 2) {
      canvas.drawLine(Offset(x, y), Offset(x + _dash, y), paint);
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// A dashed outline around optional or empty content.
class AppDashedBox extends StatelessWidget {
  const AppDashedBox({
    super.key,
    required this.child,
    this.radius = AppRadii.card,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: _DashedBoxPainter(radius),
    child: Padding(padding: padding, child: child),
  );
}

class _DashedBoxPainter extends CustomPainter {
  const _DashedBoxPainter(this.radius);
  final double radius;

  static const _dash = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.5),
          Radius.circular(radius),
        ),
      );
    final paint = Paint()
      ..color = AppPalette.lineStrong
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in outline.computeMetrics()) {
      for (double start = 0; start < metric.length; start += _dash * 2) {
        canvas.drawPath(metric.extractPath(start, start + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBoxPainter oldDelegate) =>
      oldDelegate.radius != radius;
}

/// Fine vertical lines, like the ticks of a measuring tape, that texture
/// carbon surfaces. Fills the space it is given.
class AppTickPattern extends StatelessWidget {
  const AppTickPattern({super.key, required this.color, this.spacing = 12});
  final Color color;
  final double spacing;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      painter: _TickPatternPainter(color, spacing),
      size: Size.infinite,
    ),
  );
}

class _TickPatternPainter extends CustomPainter {
  const _TickPatternPainter(this.color, this.spacing);
  final Color color;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (double x = 0.5; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_TickPatternPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.spacing != spacing;
}

/// An icon in a bordered tile that heads empty states, sheets and dialogs.
class AppIconTile extends StatelessWidget {
  const AppIconTile({
    super.key,
    required this.icon,
    this.size = 52,
    this.strong = true,
  });

  final IconData icon;
  final double size;

  /// A carbon border for warnings and confirmations; otherwise a quiet one.
  final bool strong;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(size * 0.29),
      border: Border.all(
        color: strong ? AppPalette.carbon : AppPalette.lineStrong,
        width: 1.5,
      ),
    ),
    child: Icon(
      icon,
      size: size * 0.44,
      color: strong ? AppPalette.carbon : AppPalette.greyOlive,
    ),
  );
}
