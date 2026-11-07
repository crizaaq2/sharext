import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens.dart';

/// One person on the radar.
class RadarBlip {
  const RadarBlip({
    required this.label,
    required this.signal, // 0..1, 1 = very close
    this.verified = false,
  });

  final String label;
  final double signal;
  final bool verified;
}

/// The radar: you in the middle, the people around you as rings.
///
/// The ping is the only thing that moves on its own (§6), and it stops when
/// reduced motion is on.
class RadarView extends StatefulWidget {
  const RadarView({super.key, required this.blips, this.size = 260});

  final List<RadarBlip> blips;
  final double size;

  @override
  State<RadarView> createState() => _RadarViewState();
}

class _RadarViewState extends State<RadarView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ping = AnimationController(
    vsync: this,
    duration: SxMotion.pingLoop,
  );

  @override
  void initState() {
    super.initState();
    _ping.repeat();
  }

  @override
  void dispose() {
    _ping.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SonarTokens tokens = SonarTokens.of(context);
    final bool reducedMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reducedMotion && _ping.isAnimating) _ping.stop();

    return Semantics(
      label: widget.blips.isEmpty
          ? 'Radar, nobody around'
          : 'Radar, ${widget.blips.length} people around',
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _ping,
          builder: (BuildContext context, Widget? child) => CustomPaint(
            painter: _RadarPainter(
              tokens: tokens,
              blips: widget.blips,
              ping: reducedMotion ? 0.35 : _ping.value,
            ),
          ),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.tokens,
    required this.blips,
    required this.ping,
  });

  final SonarTokens tokens;
  final List<RadarBlip> blips;
  final double ping;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double maxRadius = size.shortestSide / 2;

    // Two quiet range rings, separated by tone only (no shadows).
    final Paint ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = tokens.secondaryText.withValues(alpha: 0.25);
    canvas.drawCircle(center, maxRadius * 0.62, ring);
    canvas.drawCircle(center, maxRadius * 0.98, ring);

    // The ping: one ring expanding and fading, 2.4 s loop.
    final Paint pingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = tokens.primary.withValues(alpha: (1 - ping) * 0.45);
    canvas.drawCircle(center, maxRadius * (0.2 + ping * 0.8), pingPaint);

    // You: the lagoon ring in the centre.
    canvas.drawCircle(
      center,
      maxRadius * 0.16,
      Paint()..color = tokens.primary.withValues(alpha: 0.16),
    );
    canvas.drawCircle(
      center,
      maxRadius * 0.16,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = tokens.primary,
    );
    canvas.drawCircle(center, maxRadius * 0.05, Paint()..color = tokens.primary);

    // People: sun rings, distance follows signal strength.
    for (int i = 0; i < blips.length; i++) {
      final RadarBlip blip = blips[i];
      final double angle = -math.pi / 2 + i * (2 * math.pi / 6) + 0.35;
      final double distance = maxRadius * (0.86 - blip.signal * 0.44);
      final Offset at = center + Offset(math.cos(angle), math.sin(angle)) * distance;
      final double r = maxRadius * 0.09;

      canvas.drawCircle(
        at,
        r + 4,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = tokens.accent.withValues(alpha: 0.55),
      );
      canvas.drawCircle(at, r, Paint()..color = tokens.raised);
      canvas.drawCircle(
        at,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = tokens.accent,
      );

      final TextPainter label = TextPainter(
        text: TextSpan(
          text: blip.label.isEmpty ? '?' : blip.label.substring(0, 1).toUpperCase(),
          style: SxType.label.copyWith(color: tokens.text),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, at - Offset(label.width / 2, label.height / 2));
    }
  }

  @override
  bool shouldRepaint(_RadarPainter oldDelegate) =>
      oldDelegate.ping != ping ||
      oldDelegate.tokens != tokens ||
      oldDelegate.blips.length != blips.length;
}
