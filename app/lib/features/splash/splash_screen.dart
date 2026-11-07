import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design/components/sonar_mark.dart';
import '../../design/tokens.dart';

/// Splash: the rings slide together, the lens fills, three rings expand (§7).
/// At most 1.1 s, and a static frame when reduced motion is on.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _controller.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed && mounted) {
        context.go('/welcome');
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduced && _controller.duration != SxMotion.micro) {
      _controller.duration = SxMotion.micro;
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SonarTokens tokens = SonarTokens.of(context);
    return Scaffold(
      backgroundColor: tokens.base,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) {
            final double t = SxMotion.lens.transform(
              _controller.value.clamp(0.0, 1.0),
            );
            return Opacity(
              opacity: _controller.value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 0.88 + 0.12 * t,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SonarMark(size: 132, withBackground: true),
                    const SizedBox(height: SxSpace.x6),
                    const SonarWordmark(fontSize: 26),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
