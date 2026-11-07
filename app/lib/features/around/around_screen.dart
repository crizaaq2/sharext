import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../design/components/radar_view.dart';
import '../../design/components/sonar_mark.dart';
import '../../design/components/ui_kit.dart';
import '../../design/tokens.dart';
import '../../l10n/generated/app_localizations.dart';
import '../state/app_state.dart';
import '../shell/sx_page.dart';

/// "Around you": the radar and the people running ShAre XT nearby.
class AroundScreen extends ConsumerWidget {
  const AroundScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final SonarTokens tokens = SonarTokens.of(context);
    final AppModel model = ref.watch(appControllerProvider);
    final List<DemoPeer> around = model.aroundPeers;

    return SafeArea(
      child: SxPage(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: SxSpace.x3, bottom: SxSpace.x2),
            child: Row(
              children: <Widget>[
                const SonarWordmark(fontSize: 22),
                const Spacer(),
                StatusPill(
                  label: l10n.readyPillCount(around.length),
                  icon: Icons.bluetooth_searching,
                ),
              ],
            ),
          ),
          Text(
            l10n.aroundSubtitle,
            style: SxType.body.copyWith(color: tokens.secondaryText),
          ),
          const SizedBox(height: SxSpace.x2),
          Center(
            child: RadarView(
              size: 240,
              blips: <RadarBlip>[
                for (final DemoPeer peer in around)
                  RadarBlip(
                    label: peer.name,
                    signal: ((peer.rssi + 100) / 50).clamp(0.1, 1.0),
                    verified: peer.verified,
                  ),
              ],
            ),
          ),
          if (around.isEmpty)
            EmptyState(
              icon: Icons.wifi_tethering_off,
              title: l10n.aroundSubtitle,
              body: l10n.aroundEmpty,
            ),
          Container(
            margin: const EdgeInsets.only(top: SxSpace.x2),
            padding: const EdgeInsets.all(SxSpace.x3),
            decoration: BoxDecoration(
              color: tokens.raised.withValues(alpha: 0.7),
              borderRadius: const BorderRadius.all(
                Radius.circular(SxRadius.tile),
              ),
              border: Border.all(
                color: tokens.accent.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.science_outlined, size: 18, color: tokens.accent),
                const SizedBox(width: SxSpace.x2),
                Expanded(
                  child: Text(
                    l10n.demoBanner,
                    style: SxType.caption.copyWith(color: tokens.secondaryText),
                  ),
                ),
              ],
            ),
          ),
          SxSectionHeader(title: l10n.navAround),
          for (final DemoPeer peer in around)
            Padding(
              padding: const EdgeInsets.only(bottom: SxSpace.x2),
              child: PeerTile(
                name: peer.name,
                rssi: peer.rssi,
                inRange: true,
                inRangeLabel: l10n.inRange,
                outOfRangeLabel: l10n.outOfRange,
                verified: peer.verified,
                onTap: () => context.go('/chat/${peer.id}'),
              ),
            ),
          if (model.otherDevices.isNotEmpty) ...<Widget>[
            SxSectionHeader(title: l10n.notOnShareXt),
            for (final DemoPeer peer in model.otherDevices)
              PeerTile(
                name: peer.name,
                rssi: peer.rssi,
                inRange: false,
                inRangeLabel: l10n.inRange,
                outOfRangeLabel: l10n.notOnShareXt,
                muted: true,
              ),
          ],
          const SizedBox(height: SxSpace.x12),
        ],
      ),
    );
  }
}
