import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sx_core/sx_core.dart';

import '../../design/components/ui_kit.dart';
import '../../design/tokens.dart';
import '../../l10n/generated/app_localizations.dart';
import '../shell/sx_page.dart';
import '../state/app_state.dart';

/// The conversation list: last message, time, state of the last tick.
class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final SonarTokens tokens = SonarTokens.of(context);
    final AppModel model = ref.watch(appControllerProvider);
    final List<DemoPeer> conversations = model.conversations;

    return SafeArea(
      child: SxPage(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: SxSpace.x4, bottom: SxSpace.x2),
            child: Text(
              l10n.navChats,
              style: SxType.display.copyWith(color: tokens.text),
            ),
          ),
          if (conversations.isEmpty)
            EmptyState(
              icon: Icons.chat_bubble_outline,
              title: l10n.navChats,
              body: l10n.chatsEmpty,
            ),
          for (final DemoPeer peer in conversations)
            _ConversationTile(
              peer: peer,
              messages: model.messagesFor(peer.id),
              onTap: () => context.go('/chat/${peer.id}'),
            ),
          const SizedBox(height: SxSpace.x12),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.peer,
    required this.messages,
    required this.onTap,
  });

  final DemoPeer peer;
  final List<ChatMessage> messages;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final SonarTokens tokens = SonarTokens.of(context);
    final ChatMessage? last = messages.isEmpty ? null : messages.last;
    final String time = last == null
        ? ''
        : TimeOfDay.fromDateTime(last.at).format(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: SxSpace.x2),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(SxRadius.tile)),
        child: Container(
          padding: const EdgeInsets.all(SxSpace.x3),
          decoration: BoxDecoration(
            color: tokens.raised.withValues(alpha: 0.65),
            borderRadius: const BorderRadius.all(Radius.circular(SxRadius.tile)),
          ),
          child: Row(
            children: <Widget>[
              PeerAvatar(name: peer.name),
              const SizedBox(width: SxSpace.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      peer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SxType.body.copyWith(
                        color: tokens.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: <Widget>[
                        if (last != null && last.outgoing) ...<Widget>[
                          Icon(
                            last.status == MessageStatus.delivered
                                ? Icons.done_all
                                : last.status == MessageStatus.queued
                                ? Icons.schedule
                                : Icons.check,
                            size: 13,
                            color: tokens.secondaryText,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            last?.text ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SxType.caption.copyWith(
                              color: tokens.secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: SxSpace.x2),
              Text(
                time,
                style: SxType.caption.copyWith(color: tokens.secondaryText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
