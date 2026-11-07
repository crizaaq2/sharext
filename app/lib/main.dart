import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'design/theme.dart';
import 'design/tokens.dart';
import 'features/state/app_state.dart';
import 'l10n/generated/app_localizations.dart';
import 'router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: ShAreXtApp()));
}

class ShAreXtApp extends ConsumerWidget {
  const ShAreXtApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppModel model = ref.watch(appControllerProvider);
    return MaterialApp.router(
      title: 'ShAre XT',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: buildSonarTheme(SonarTokens.light, Brightness.light),
      darkTheme: buildSonarTheme(SonarTokens.dark, Brightness.dark),
      themeMode: model.themeMode,
      locale: model.localeCode == null ? null : Locale(model.localeCode!),
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (BuildContext context, Widget? child) {
        // Never let the system text scale break a layout (§6 accessibility).
        final MediaQueryData media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 1,
              maxScaleFactor: 2,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
