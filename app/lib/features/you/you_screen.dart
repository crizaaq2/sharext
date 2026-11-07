import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/components/ui_kit.dart';
import '../../design/tokens.dart';
import '../../l10n/generated/app_localizations.dart';
import '../shell/sx_page.dart';
import '../state/app_state.dart';

/// "You": profile, language, theme, delivery readiness and diagnostics.
class YouScreen extends ConsumerStatefulWidget {
  const YouScreen({super.key});

  @override
  ConsumerState<YouScreen> createState() => _YouScreenState();
}

class _YouScreenState extends ConsumerState<YouScreen> {
  late final TextEditingController _name = TextEditingController(
    text: ref.read(appControllerProvider).displayName,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final SonarTokens tokens = SonarTokens.of(context);
    final AppModel model = ref.watch(appControllerProvider);
    final AppController controller = ref.read(appControllerProvider.notifier);

    return SafeArea(
      child: SxPage(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: SxSpace.x4, bottom: SxSpace.x3),
            child: Text(
              l10n.navYou,
              style: SxType.display.copyWith(color: tokens.text),
            ),
          ),
          Row(
            children: <Widget>[
              PeerAvatar(
                name: model.displayName.isEmpty ? '?' : model.displayName,
                size: 56,
              ),
              const SizedBox(width: SxSpace.x4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      model.displayName.isEmpty ? l10n.nameHint : model.displayName,
                      style: SxType.title.copyWith(fontSize: 20, color: tokens.text),
                    ),
                    Text(
                      l10n.youAreVisible,
                      style: SxType.caption.copyWith(color: tokens.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: SxSpace.x6),
          TextField(
            controller: _name,
            style: SxType.body.copyWith(color: tokens.text),
            decoration: InputDecoration(
              labelText: l10n.yourName,
              hintText: l10n.nameHint,
            ),
            onSubmitted: controller.setDisplayName,
            onChanged: (String value) {
              if (value.trim().length > 1) controller.setDisplayName(value);
            },
          ),
          SxSectionHeader(title: l10n.language),
          Wrap(
            spacing: SxSpace.x2,
            runSpacing: SxSpace.x2,
            children: <Widget>[
              _Choice(
                label: l10n.themeSystem,
                selected: model.localeCode == null,
                onTap: () => controller.setLocale(null),
              ),
              _Choice(
                label: 'Soomaali',
                selected: model.localeCode == 'so',
                onTap: () => controller.setLocale(const Locale('so')),
              ),
              _Choice(
                label: 'English',
                selected: model.localeCode == 'en',
                onTap: () => controller.setLocale(const Locale('en')),
              ),
              _Choice(
                label: 'العربية',
                selected: model.localeCode == 'ar',
                onTap: () => controller.setLocale(const Locale('ar')),
              ),
            ],
          ),
          SxSectionHeader(title: l10n.theme),
          Wrap(
            spacing: SxSpace.x2,
            children: <Widget>[
              _Choice(
                label: l10n.themeDark,
                selected: model.themeMode == ThemeMode.dark,
                onTap: () => controller.setThemeMode(ThemeMode.dark),
              ),
              _Choice(
                label: l10n.themeLight,
                selected: model.themeMode == ThemeMode.light,
                onTap: () => controller.setThemeMode(ThemeMode.light),
              ),
              _Choice(
                label: l10n.themeSystem,
                selected: model.themeMode == ThemeMode.system,
                onTap: () => controller.setThemeMode(ThemeMode.system),
              ),
            ],
          ),
          SxSectionHeader(title: l10n.deliveryReadiness),
          SxRow(
            icon: Icons.bluetooth,
            title: l10n.readinessBluetooth,
            subtitle: l10n.notSetUpYet,
            trailing: StatusPill(
              label: l10n.limited,
              color: tokens.accent,
            ),
          ),
          SxRow(
            icon: Icons.notifications_none,
            title: l10n.readinessNotifications,
            subtitle: l10n.notSetUpYet,
            trailing: StatusPill(label: l10n.limited, color: tokens.accent),
          ),
          SxRow(
            icon: Icons.battery_charging_full,
            title: l10n.readinessKeepReady,
            subtitle: l10n.notSetUpYet,
            trailing: StatusPill(label: l10n.limited, color: tokens.accent),
          ),
          SxSectionHeader(title: l10n.diagnostics),
          SxRow(
            icon: Icons.article_outlined,
            title: l10n.shareLogs,
            onTap: () => _showLog(context, controller),
          ),
          SxRow(
            icon: Icons.copy_all_outlined,
            title: l10n.copyDebugInfo,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.copyDebugInfo)),
            ),
          ),
          SxSectionHeader(title: l10n.about),
          SxRow(
            icon: Icons.info_outline,
            title: l10n.appName,
            subtitle: '${l10n.versionLabel} 0.1.0 (Sprint 0)',
          ),
          const SizedBox(height: SxSpace.x12),
        ],
      ),
    );
  }

  void _showLog(BuildContext context, AppController controller) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (BuildContext context, ScrollController scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(SxSpace.x4),
          children: <Widget>[
            Text(
              l10n.shareLogs,
              style: SxType.title.copyWith(
                color: SonarTokens.of(context).text,
              ),
            ),
            const SizedBox(height: SxSpace.x3),
            SelectableText(
              controller.log.export(),
              style: SxType.caption.copyWith(
                color: SonarTokens.of(context).secondaryText,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final SonarTokens tokens = SonarTokens.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(SxRadius.pill),
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(
          horizontal: SxSpace.x4,
          vertical: SxSpace.x2,
        ),
        decoration: BoxDecoration(
          color: selected
              ? tokens.primary.withValues(alpha: 0.16)
              : tokens.raised.withValues(alpha: 0.6),
          borderRadius: const BorderRadius.all(SxRadius.pill),
          border: Border.all(
            color: selected
                ? tokens.primary
                : tokens.secondaryText.withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          label,
          style: SxType.label.copyWith(
            color: selected ? tokens.primary : tokens.text,
          ),
        ),
      ),
    );
  }
}
