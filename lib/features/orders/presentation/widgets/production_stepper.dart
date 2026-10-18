import 'package:flutter/material.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/features/orders/domain/entities/order_status.dart';

/// A production stage marker: filled with a tick once done, a heavy ring
/// for the stage the order is in, a light ring for stages still ahead.
class StageDot extends StatelessWidget {
  const StageDot({
    super.key,
    required this.done,
    required this.current,
    this.glow = false,
  });

  final bool done;
  final bool current;

  /// An olive halo around the current stage.
  final bool glow;

  @override
  Widget build(BuildContext context) => Container(
    width: 22,
    height: 22,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: done ? AppPalette.carbon : AppPalette.white,
      border: done
          ? null
          : current
          ? Border.all(color: AppPalette.carbon, width: 2.5)
          : Border.all(color: AppPalette.lineStrong, width: 1.5),
      boxShadow: current && glow
          ? const [
              BoxShadow(
                color: Color.fromRGBO(124, 128, 112, 0.22),
                spreadRadius: 4,
              ),
            ]
          : null,
    ),
    child: done
        ? const Icon(Icons.check, size: 14, color: AppPalette.white)
        : null,
  );
}

/// The five stages of an order on one line, from Received to Delivered.
class ProductionStepper extends StatelessWidget {
  const ProductionStepper({super.key, required this.status});

  final String status;

  static const _stages = [...OrderStatus.production, OrderStatus.delivered];
  static const _dot = 22.0;
  static const _labelWidth = 76.0;

  @override
  Widget build(BuildContext context) {
    final current = _stages.indexOf(status).clamp(0, _stages.length - 1);
    final delivered = status == OrderStatus.delivered;
    bool done(int index) => index < current || delivered;

    return Semantics(
      label:
          'Production stage: ${_stages[current]}, '
          '${current + 1} of ${_stages.length}',
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final step = (width - _dot) / (_stages.length - 1);
            final labelStyle = AppTypography.micro.copyWith(
              fontSize: 9.5,
              letterSpacing: 9.5 * 0.02,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    for (var index = 0; index < _stages.length; index++) ...[
                      if (index > 0)
                        Expanded(
                          child: index <= current
                              ? Container(height: 2, color: AppPalette.carbon)
                              : const _DashedConnector(),
                        ),
                      StageDot(
                        done: done(index),
                        current: index == current && !delivered,
                        glow: true,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 14,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (var index = 0; index < _stages.length; index++)
                        _label(
                          index: index,
                          center: _dot / 2 + step * index,
                          width: width,
                          style: labelStyle.copyWith(
                            color: index == current && !delivered
                                ? AppPalette.carbon
                                : done(index)
                                ? AppPalette.ink55
                                : const Color.fromRGBO(23, 25, 24, 0.35),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// The first label lines up with the left edge and the last with the
  /// right; the rest are centred under their dot.
  Widget _label({
    required int index,
    required double center,
    required double width,
    required TextStyle style,
  }) {
    final text = Text(_stages[index], maxLines: 1, style: style);
    if (index == 0) return Positioned(left: 0, top: 0, child: text);
    if (index == _stages.length - 1) {
      return Positioned(right: 0, top: 0, child: text);
    }
    return Positioned(
      left: center - _labelWidth / 2,
      width: _labelWidth,
      top: 0,
      child: Center(child: text),
    );
  }
}

class _DashedConnector extends StatelessWidget {
  const _DashedConnector();

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 2, child: CustomPaint(painter: _DashPainter()));
}

class _DashPainter extends CustomPainter {
  static const _dash = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromRGBO(23, 25, 24, 0.30)
      ..strokeWidth = size.height;
    final y = size.height / 2;
    for (double x = 0; x < size.width; x += _dash * 2) {
      canvas.drawLine(Offset(x, y), Offset(x + _dash, y), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) => false;
}
