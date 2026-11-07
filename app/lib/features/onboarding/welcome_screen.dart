import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design/components/sonar_mark.dart';
import '../../design/tokens.dart';
import '../../l10n/generated/app_localizations.dart';
import '../state/app_state.dart';

/// First run: three short slides, a name, then the people around you.
/// Permissions are asked after this screen in the real build (SX-402).
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final PageController _pages = PageController();
  final TextEditingController _name = TextEditingController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    _name.dispose();
    super.dispose();
  }

  void _next(int total) {
    if (_index == total - 1) {
      ref.read(appControllerProvider.notifier).setDisplayName(_name.text);
      context.go('/around');
      return;
    }
    _pages.nextPage(
      duration: SxMotion.standard,
      curve: SxMotion.smooth,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final SonarTokens tokens = SonarTokens.of(context);
    final List<({String title, String body})> slides = <({String title, String body})>[
      (title: l10n.onboardTitle1, body: l10n.onboardBody1),
      (title: l10n.onboardTitle2, body: l10n.onboardBody2),
      (title: l10n.onboardTitle3, body: l10n.onboardBody3),
    ];
    final bool last = _index == slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    SxSpace.x4,
                    SxSpace.x3,
                    SxSpace.x2,
                    0,
                  ),
                  child: Row(
                    children: <Widget>[
                      const SonarMark(size: 34),
                      const SizedBox(width: SxSpace.x2),
                      const SonarWordmark(fontSize: 18),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          ref
                              .read(appControllerProvider.notifier)
                              .setDisplayName(_name.text);
                          context.go('/around');
                        },
                        child: Text(l10n.onboardSkip),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pages,
                    onPageChanged: (int i) => setState(() => _index = i),
                    itemCount: slides.length,
                    itemBuilder: (BuildContext context, int i) {
                      final ({String title, String body}) slide = slides[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SxSpace.x6,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SonarMark(
                              size: 118,
                              withBackground: i != 1,
                              semanticLabel: slide.title,
                            ),
                            const SizedBox(height: SxSpace.x8),
                            Text(
                              slide.title,
                              style: SxType.display.copyWith(
                                color: tokens.text,
                              ),
                            ),
                            const SizedBox(height: SxSpace.x3),
                            Text(
                              slide.body,
                              style: SxType.body.copyWith(
                                color: tokens.secondaryText,
                              ),
                            ),
                            if (i == slides.length - 1) ...<Widget>[
                              const SizedBox(height: SxSpace.x8),
                              Text(
                                l10n.nameQuestion,
                                style: SxType.label.copyWith(
                                  color: tokens.secondaryText,
                                ),
                              ),
                              const SizedBox(height: SxSpace.x2),
                              TextField(
                                controller: _name,
                                textInputAction: TextInputAction.done,
                                style: SxType.body.copyWith(color: tokens.text),
                                decoration: InputDecoration(
                                  hintText: l10n.nameHint,
                                ),
                                onSubmitted: (_) => _next(slides.length),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(SxSpace.x6),
                  child: Row(
                    children: <Widget>[
                      for (int i = 0; i < slides.length; i++)
                        AnimatedContainer(
                          duration: SxMotion.micro,
                          margin: const EdgeInsetsDirectional.only(
                            end: SxSpace.x2,
                          ),
                          width: i == _index ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _index
                                ? tokens.primary
                                : tokens.secondaryText.withValues(alpha: 0.4),
                            borderRadius: const BorderRadius.all(
                              SxRadius.pill,
                            ),
                          ),
                        ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => _next(slides.length),
                        child: Text(
                          last ? l10n.onboardStart : l10n.onboardNext,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
