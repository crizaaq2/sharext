import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.dart';

/// The Wadaag lens (PLAN section 7), drawn from the frozen geometry.
///
/// Two rings are two Bluetooth ranges; the overlap is the product. The teal
/// ring passes over the amber one at the top and under it at the bottom.
/// Never recolour, add a shadow or a gradient, and never use the Bluetooth
/// logo.
class SonarMark extends StatelessWidget {
  const SonarMark({
    super.key,
    this.size = 96,
    this.withBackground = false,
    this.monochrome = false,
    this.semanticLabel,
  });

  final double size;

  /// Draws the rounded tideInk plate behind the mark (app icon style).
  final bool withBackground;

  /// One colour only: used for the notification icon and the tray.
  final bool monochrome;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final SonarTokens tokens = SonarTokens.of(context);
    final Widget mark = SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _LensPainter(
          tokens: tokens,
          withBackground: withBackground,
          monochrome: monochrome,
        ),
      ),
    );
    if (semanticLabel == null) return ExcludeSemantics(child: mark);
    return Semantics(label: semanticLabel, image: true, child: mark);
  }
}

class _LensPainter extends CustomPainter {
  const _LensPainter({
    required this.tokens,
    required this.withBackground,
    required this.monochrome,
  });

  final SonarTokens tokens;
  final bool withBackground;
  final bool monochrome;

  // Canvas coordinates of the master SVG.
  static const double _canvas = 512;
  static const double _radius = 100;
  static const Offset _leftCenter = Offset(210, 256);
  static const Offset _rightCenter = Offset(302, 256);
  static const double _stroke = 24;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / _canvas;
    if (withBackground) {
      final RRect plate = RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(116 * s),
      );
      canvas.drawRRect(plate, Paint()..color = tokens.base);
    }

    final Rect leftRect = Rect.fromCircle(
      center: _leftCenter * s,
      radius: _radius * s,
    );
    final Rect rightRect = Rect.fromCircle(
      center: _rightCenter * s,
      radius: _radius * s,
    );
    final Path left = Path()..addOval(leftRect);
    final Path right = Path()..addOval(rightRect);

    // The lens: the overlap, filled.
    final Paint lensPaint = Paint()
      ..color = monochrome ? Colors.white : tokens.text;
    canvas.drawPath(Path.combine(PathOperation.intersect, left, right), lensPaint);

    final Paint ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke * s
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true;

    final Color teal = monochrome ? Colors.white : tokens.primary;
    final Color amber = monochrome ? Colors.white : tokens.accent;

    // Paint order from the master SVG: teal, amber, then the teal top arc.
    canvas.drawPath(left, ringPaint..color = teal);
    canvas.drawPath(right, ringPaint..color = amber);
    canvas.drawArc(
      leftRect,
      -74.5 * math.pi / 180,
      24 * math.pi / 180,
      false,
      ringPaint..color = teal,
    );
  }

  @override
  bool shouldRepaint(_LensPainter oldDelegate) =>
      oldDelegate.tokens != tokens ||
      oldDelegate.withBackground != withBackground ||
      oldDelegate.monochrome != monochrome;
}

/// The wordmark rules (§7): ShAre XT, capitals at 800, lowercase light.
class SonarWordmark extends StatelessWidget {
  const SonarWordmark({super.key, this.fontSize = 24});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final SonarTokens tokens = SonarTokens.of(context);
    final TextStyle base = SxType.title.copyWith(
      fontSize: fontSize,
      letterSpacing: -0.02 * fontSize,
      color: tokens.text,
    );
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: 'Sh',
            style: base.copyWith(fontWeight: FontWeight.w800),
          ),
          TextSpan(
            text: 'Are',
            style: base.copyWith(
              fontWeight: FontWeight.w300,
              fontVariations: const <FontVariation>[
                FontVariation('wght', 380),
              ],
            ),
          ),
          const TextSpan(text: ' '),
          TextSpan(
            text: 'XT',
            style: base.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
      semanticsLabel: 'ShAre XT',
    );
  }
}
