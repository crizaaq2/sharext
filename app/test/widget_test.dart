import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sx_core/sx_core.dart';
import 'package:sharext/design/components/ui_kit.dart';
import 'package:sharext/design/theme.dart';
import 'package:sharext/design/tokens.dart';
import 'package:sharext/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('an outgoing delivered bubble shows the delivered tick', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildSonarTheme(SonarTokens.dark, Brightness.dark),
        home: const Scaffold(
          body: ChatBubble(
            text: 'Salaan!',
            outgoing: true,
            timeLabel: '10:42',
            status: MessageStatus.delivered,
          ),
        ),
      ),
    );
    expect(find.text('Salaan!'), findsOneWidget);
    expect(find.byIcon(Icons.done_all), findsOneWidget);
  });

  testWidgets('a queued message shows the clock, never a tick', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildSonarTheme(SonarTokens.dark, Brightness.dark),
        home: const Scaffold(
          body: ChatBubble(
            text: 'Waiting',
            outgoing: true,
            timeLabel: '10:43',
            status: MessageStatus.queued,
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.schedule), findsOneWidget);
    expect(find.byIcon(Icons.done_all), findsNothing);
  });

  testWidgets('arabic mirrors the layout', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (BuildContext context) =>
              Text(Directionality.of(context).name),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('rtl'), findsOneWidget);
  });
}
