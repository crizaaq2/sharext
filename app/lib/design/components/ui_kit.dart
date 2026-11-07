import 'package:flutter/material.dart';
import 'package:sx_core/sx_core.dart';

import '../tokens.dart';

/// A small rounded label: Ready, In range, Limited.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.onTap,
  });

  final String label;
  final Color? color;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final SonarTokens tokens = SonarTokens.of(context);
    final Color tint = color ?? tokens.primary;
    final Widget content = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SxSpace.x3,
        vertical: SxSpace.x2 - 2,
      ),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: const BorderRadius.all(SxRadius.pill),
        border: Border.all(color: tint.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 14, color: tint),
            const SizedBox(width: SxSpace.x1 + 2),
          ],
          Text(label, style: SxType.caption.copyWith(color: tint)),
        ],
      ),
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(SxRadius.pill),
      child: content,
    );
  }
}

/// Three bars driven by RSSI. Decorative, with a text alternative.
class SignalBars extends StatelessWidget {
  const SignalBars({super.key, required this.rssi});

  final int rssi;

  @override
  Widget build(BuildContext context) {
    final SonarTokens tokens = SonarTokens.of(context);
    final int level = rssi > -60
        ? 3
        : rssi > -75
        ? 2
        : 1;
    return Semantics(
      label: 'Signal $level of 3',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List<Widget>.generate(3, (int i) {
          final bool on = i < level;
          return Container(
            width: 3,
            height: 5.0 + i * 4,
            margin: const EdgeInsetsDirectional.only(end: 2),
            decoration: BoxDecoration(
              color: on ? tokens.accent : tokens.secondaryText.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.all(Radius.circular(2)),
            ),
          );
        }),
      ),
    );
  }
}

/// A circular avatar with an initial and the ring colour of its state.
class PeerAvatar extends StatelessWidget {
  const PeerAvatar({
    super.key,
    required this.name,
    this.size = 44,
    this.highlighted = true,
  });

  final String name;
  final double size;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final SonarTokens tokens = SonarTokens.of(context);
    final String initial = name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tokens.raised,
        border: Border.all(
          color: highlighted ? tokens.accent : tokens.secondaryText.withValues(alpha: 0.35),
          width: 2,
        ),
      ),
      child: Text(
        initial,
        style: SxType.title.copyWith(fontSize: size * 0.38, color: tokens.text),
      ),
    );
  }
}

/// A row in the people list.
class PeerTile extends StatelessWidget {
  const PeerTile({
    super.key,
    required this.name,
    required this.rssi,
    required this.inRange,
    this.inRangeLabel,
    this.outOfRangeLabel,
    this.verified = false,
    this.trailing,
    this.onTap,
    this.muted = false,
  });

  final String name;
  final int rssi;
  final bool inRange;
  final String? inRangeLabel;
  final String? outOfRangeLabel;
  final bool verified;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final SonarTokens tokens = SonarTokens.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(SxRadius.tile)),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: SxSpace.x3,
            vertical: SxSpace.x3,
          ),
          decoration: BoxDecoration(
            color: muted ? Colors.transparent : tokens.raised.withValues(alpha: 0.65),
            borderRadius: const BorderRadius.all(Radius.circular(SxRadius.tile)),
          ),
          child: Row(
            children: <Widget>[
              PeerAvatar(name: name, highlighted: inRange && !muted),
              const SizedBox(width: SxSpace.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SxType.body.copyWith(
                              color: muted ? tokens.secondaryText : tokens.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (verified) ...<Widget>[
                          const SizedBox(width: SxSpace.x1 + 2),
                          Icon(Icons.verified, size: 15, color: tokens.primary),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      inRange
                          ? (inRangeLabel ?? 'In range')
                          : (outOfRangeLabel ?? 'Out of range'),
                      style: SxType.caption.copyWith(
                        color: inRange ? tokens.secondaryText : tokens.secondaryText.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (inRange)
                SignalBars(rssi: rssi),
            ],
          ),
        ),
      ),
    );
  }
}

/// One chat bubble. Outgoing uses lagoon, incoming uses reef.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.text,
    required this.outgoing,
    required this.timeLabel,
    this.status,
    this.statusLabel,
    this.maxWidth = SxBreakpoint.bubbleMaxDesktop,
  });

  final String text;
  final bool outgoing;
  final String timeLabel;
  final MessageStatus? status;
  final String? statusLabel;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final SonarTokens tokens = SonarTokens.of(context);
    final Color background = outgoing ? tokens.primary : tokens.raised;
    final Color foreground = outgoing ? tokens.onPrimary : tokens.text;
    final Radius big = const Radius.circular(SxRadius.bubble);
    final Radius tail = const Radius.circular(SxRadius.bubbleTail);

    return Align(
      alignment: outgoing ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        margin: const EdgeInsets.symmetric(vertical: SxSpace.x1),
        padding: const EdgeInsets.symmetric(
          horizontal: SxSpace.x4,
          vertical: SxSpace.x3,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.only(
            topLeft: big,
            topRight: big,
            bottomLeft: outgoing ? big : tail,
            bottomRight: outgoing ? tail : big,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(text, style: SxType.chat.copyWith(color: foreground)),
            const SizedBox(height: SxSpace.x1),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  timeLabel,
                  style: SxType.caption.copyWith(
                    color: foreground.withValues(alpha: 0.65),
                  ),
                ),
                if (status != null) ...<Widget>[
                  const SizedBox(width: SxSpace.x1 + 2),
                  _Ticks(status: status!, color: foreground.withValues(alpha: 0.75)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Ticks extends StatelessWidget {
  const _Ticks({required this.status, required this.color});

  final MessageStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageStatus.queued:
        return Icon(Icons.schedule, size: 13, color: color);
      case MessageStatus.sent:
        return Icon(Icons.check, size: 14, color: color);
      case MessageStatus.delivered:
        return Icon(Icons.done_all, size: 14, color: color);
      case MessageStatus.read:
        return Icon(Icons.done_all, size: 14, color: SonarTokens.of(context).primary);
      case MessageStatus.failed:
        return Icon(Icons.error_outline, size: 14, color: SonarTokens.of(context).danger);
    }
  }
}

/// The quiet empty state: always invites an action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final SonarTokens tokens = SonarTokens.of(context);
    return Padding(
      padding: const EdgeInsets.all(SxSpace.x6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 40, color: tokens.secondaryText),
          const SizedBox(height: SxSpace.x4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: SxType.title.copyWith(color: tokens.text),
          ),
          const SizedBox(height: SxSpace.x2),
          Text(
            body,
            textAlign: TextAlign.center,
            style: SxType.body.copyWith(color: tokens.secondaryText),
          ),
        ],
      ),
    );
  }
}

/// Section heading used by every list.
class SxSectionHeader extends StatelessWidget {
  const SxSectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final SonarTokens tokens = SonarTokens.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        SxSpace.x1,
        SxSpace.x4,
        SxSpace.x1,
        SxSpace.x2,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: SxType.label.copyWith(color: tokens.secondaryText),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A settings-style row with a title, a subtitle and a trailing widget.
class SxRow extends StatelessWidget {
  const SxRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
    this.danger = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final SonarTokens tokens = SonarTokens.of(context);
    final Color titleColor = danger ? tokens.danger : tokens.text;
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(Radius.circular(SxRadius.tile)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SxSpace.x3,
          vertical: SxSpace.x3,
        ),
        child: Row(
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 20, color: tokens.secondaryText),
              const SizedBox(width: SxSpace.x3),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: SxType.body.copyWith(color: titleColor)),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: SxType.caption.copyWith(color: tokens.secondaryText),
                      ),
                    ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
