import 'package:flutter/material.dart';

import '../../design/tokens.dart';

/// Shared page frame: one scroll view, one max width, aligned gutters.
class SxPage extends StatelessWidget {
  const SxPage({super.key, required this.children, this.maxWidth = 760});

  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          for (final Widget child in children)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: SxSpace.x4),
              child: child,
            ),
        ],
      ),
    ),
  );
}
