import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sx_core/sx_core.dart';

import '../../design/components/ui_kit.dart';
import '../../design/tokens.dart';
import '../../l10n/generated/app_localizations.dart';
import '../state/app_state.dart';

/// The chat: bubbles, ticks and an honest status line.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.peerId});

  final String peerId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appControllerProvider.notifier).connect(widget.peerId);
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final String text = _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    ref.read(appControllerProvider.notifier).send(widget.peerId, text);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: SxMotion.standard,
        curve: SxMotion.smooth,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final SonarTokens tokens = SonarTokens.of(context);
    final AppModel model = ref.watch(appControllerProvider);
    final DemoPeer? peer = model.peerById(widget.peerId);

    if (peer == null) {
      return Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: () => context.go('/around'))),
        body: EmptyState(
          icon: Icons.person_off_outlined,
          title: l10n.notOnShareXt,
          body: l10n.aroundEmpty,
        ),
      );
    }

    final List<ChatMessage> messages = model.messagesFor(peer.id);
    final List<ChatMessage> outgoing = messages
        .where((ChatMessage m) => m.outgoing)
        .toList(growable: false);
    final ChatMessage? lastOutgoing = outgoing.isEmpty ? null : outgoing.last;
    final bool waiting = lastOutgoing != null &&
        lastOutgoing.status != MessageStatus.delivered &&
        lastOutgoing.status != MessageStatus.read;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => context.go('/around'),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
        titleSpacing: 0,
        title: Row(
          children: <Widget>[
            PeerAvatar(name: peer.name, size: 36),
            const SizedBox(width: SxSpace.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    peer.name,
                    style: SxType.title.copyWith(
                      fontSize: 18,
                      color: tokens.text,
                    ),
                  ),
                  Text(
                    peer.onShareXt ? l10n.inRange : l10n.notOnShareXt,
                    style: SxType.caption.copyWith(
                      color: peer.onShareXt ? tokens.primary : tokens.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            if (peer.onShareXt)
              StatusPill(label: l10n.inRange, icon: Icons.near_me_outlined),
            const SizedBox(width: SxSpace.x2),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            color: tokens.raised.withValues(alpha: 0.6),
            padding: const EdgeInsets.symmetric(
              horizontal: SxSpace.x4,
              vertical: SxSpace.x2,
            ),
            child: Text(
              l10n.demoBanner,
              style: SxType.caption.copyWith(color: tokens.secondaryText),
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(
                    SxSpace.x4,
                    SxSpace.x4,
                    SxSpace.x4,
                    SxSpace.x2,
                  ),
                  itemCount: messages.length + 1,
                  itemBuilder: (BuildContext context, int index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: SxSpace.x3),
                        child: Center(
                          child: Text(
                            l10n.today,
                            style: SxType.caption.copyWith(
                              color: tokens.secondaryText,
                            ),
                          ),
                        ),
                      );
                    }
                    final ChatMessage message = messages[index - 1];
                    return ChatBubble(
                      text: message.text,
                      outgoing: message.outgoing,
                      timeLabel: TimeOfDay.fromDateTime(message.at).format(context),
                      status: message.outgoing ? message.status : null,
                    );
                  },
                ),
              ),
            ),
          ),
          if (waiting)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SxSpace.x4,
                vertical: SxSpace.x2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.schedule, size: 14, color: tokens.secondaryText),
                  const SizedBox(width: SxSpace.x2),
                  Flexible(
                    child: Text(
                      lastOutgoing.status == MessageStatus.queued
                          ? l10n.waitingForPeer(peer.name)
                          : l10n.statusSent,
                      style: SxType.caption.copyWith(
                        color: tokens.secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                SxSpace.x3,
                SxSpace.x2,
                SxSpace.x3,
                SxSpace.x3,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: tokens.secondaryText,
                    tooltip: l10n.attachmentsComingSoon,
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.attachmentsComingSoon)),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      style: SxType.chat.copyWith(color: tokens.text),
                      decoration: InputDecoration(hintText: l10n.chatHint),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: SxSpace.x2),
                  IconButton.filled(
                    onPressed: _send,
                    tooltip: l10n.send,
                    style: IconButton.styleFrom(
                      backgroundColor: tokens.primary,
                      foregroundColor: tokens.onPrimary,
                      minimumSize: const Size(48, 48),
                    ),
                    icon: const Icon(Icons.arrow_upward),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
