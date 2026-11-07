import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sx_core/sx_core.dart';

/// A person (or a device without the app) in the demo state.
///
/// Identity in the real product is the peer's Noise public key, never a MAC
/// address (ADR-05). These ids are only for the Sprint 0 demo.
class DemoPeer {
  const DemoPeer({
    required this.id,
    required this.name,
    required this.rssi,
    this.onShareXt = true,
    this.verified = false,
  });

  final String id;
  final String name;
  final int rssi;
  final bool onShareXt;
  final bool verified;
}

/// One message in the demo store. [status] is the real ladder from `sx_core`.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.peerId,
    required this.text,
    required this.at,
    required this.outgoing,
    required this.status,
  });

  final String id;
  final String peerId;
  final String text;
  final DateTime at;
  final bool outgoing;
  final MessageStatus status;

  ChatMessage copyWith({MessageStatus? status}) => ChatMessage(
    id: id,
    peerId: peerId,
    text: text,
    at: at,
    outgoing: outgoing,
    status: status ?? this.status,
  );
}

/// Everything the UI reads. Immutable so Riverpod can diff it.
class AppModel {
  const AppModel({
    required this.peers,
    required this.messages,
    required this.displayName,
    required this.localeCode,
    required this.themeMode,
  });

  final List<DemoPeer> peers;
  final List<ChatMessage> messages;
  final String displayName;

  /// null means "follow the system".
  final String? localeCode;
  final ThemeMode themeMode;

  List<DemoPeer> get aroundPeers =>
      peers.where((DemoPeer p) => p.onShareXt).toList(growable: false);

  List<DemoPeer> get otherDevices =>
      peers.where((DemoPeer p) => !p.onShareXt).toList(growable: false);

  DemoPeer? peerById(String id) {
    for (final DemoPeer peer in peers) {
      if (peer.id == id) return peer;
    }
    return null;
  }

  List<ChatMessage> messagesFor(String peerId) => messages
      .where((ChatMessage m) => m.peerId == peerId)
      .toList(growable: false);

  /// Peers with at least one message, most recent first.
  List<DemoPeer> get conversations {
    final List<DemoPeer> out = <DemoPeer>[];
    for (final DemoPeer peer in peers) {
      if (messages.any((ChatMessage m) => m.peerId == peer.id)) out.add(peer);
    }
    out.sort((DemoPeer a, DemoPeer b) {
      final DateTime at = _lastAt(a.id);
      final DateTime bt = _lastAt(b.id);
      return bt.compareTo(at);
    });
    return out;
  }

  DateTime _lastAt(String peerId) {
    DateTime latest = DateTime.fromMillisecondsSinceEpoch(0);
    for (final ChatMessage m in messages) {
      if (m.peerId == peerId && m.at.isAfter(latest)) latest = m.at;
    }
    return latest;
  }

  int get queuedCount =>
      messages.where((ChatMessage m) => m.outgoing && m.status == MessageStatus.queued).length;

  AppModel copyWith({
    List<DemoPeer>? peers,
    List<ChatMessage>? messages,
    String? displayName,
    String? localeCode,
    bool clearLocale = false,
    ThemeMode? themeMode,
  }) => AppModel(
    peers: peers ?? this.peers,
    messages: messages ?? this.messages,
    displayName: displayName ?? this.displayName,
    localeCode: clearLocale ? null : (localeCode ?? this.localeCode),
    themeMode: themeMode ?? this.themeMode,
  );
}

final NotifierProvider<AppController, AppModel> appControllerProvider =
    NotifierProvider<AppController, AppModel>(AppController.new);

/// The Sprint 0 controller: honest state, real framing, no radio.
///
/// Messages go through the real [Outbox] (persist first) and the real framing
/// code over `sx_core`'s [FakeNetwork]. A peer only becomes `delivered` when
/// its side actually persisted the message and sent the receipt back. No
/// Bluetooth plugin exists yet, so nothing leaves this process — the UI says so.
class AppController extends Notifier<AppModel> {
  final Outbox _outbox = Outbox();
  final SxLog _log = SxLog();
  final Map<String, Link> _links = <String, Link>{};
  final Map<String, FrameDecoder> _peerDecoders = <String, FrameDecoder>{};
  final Map<String, FrameDecoder> _receiptDecoders = <String, FrameDecoder>{};

  FakeNetwork? _network;
  FakeTransport? _self;
  int _sequence = 0;
  bool _disposed = false;

  /// Diagnostics read this; it is already redacted by [SxLog].
  SxLog get log => _log;

  @override
  AppModel build() {
    ref.onDispose(() {
      _disposed = true;
      _network?.disposeAll();
      _links.clear();
    });
    final DateTime now = DateTime.now();
    _log.info('boot protocol SLP/1');
    return AppModel(
      peers: const <DemoPeer>[
        DemoPeer(id: 'axmed', name: 'Axmed', rssi: -54, verified: true),
        DemoPeer(id: 'fadumo', name: 'Fadumo', rssi: -67),
        DemoPeer(id: 'yuusuf', name: 'Yuusuf', rssi: -83),
        DemoPeer(id: 'printer', name: 'HP LaserJet', rssi: -71, onShareXt: false),
        DemoPeer(id: 'tv', name: 'Living room TV', rssi: -89, onShareXt: false),
      ],
      messages: <ChatMessage>[
        ChatMessage(
          id: 'seed-1',
          peerId: 'axmed',
          text: 'Salaan! Ma maqashay ShAre XT?',
          at: now.subtract(const Duration(minutes: 42)),
          outgoing: false,
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: 'seed-2',
          peerId: 'axmed',
          text: 'Haa, waa mid fiican. Internet ma u baahna.',
          at: now.subtract(const Duration(minutes: 40)),
          outgoing: true,
          status: MessageStatus.delivered,
        ),
        ChatMessage(
          id: 'seed-3',
          peerId: 'axmed',
          text: 'Sawirka aad dirtay waan helay, mahadsanid.',
          at: now.subtract(const Duration(minutes: 12)),
          outgoing: false,
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: 'seed-4',
          peerId: 'fadumo',
          text: 'Berri ayaan ku arki doonaa.',
          at: now.subtract(const Duration(days: 1, hours: 3)),
          outgoing: false,
          status: MessageStatus.read,
        ),
      ],
      displayName: '',
      localeCode: null,
      themeMode: ThemeMode.dark,
    );
  }

  /// Opens the in-memory link to [peerId] and flushes anything queued.
  ///
  /// Returns null when the link is ready, or a reason key when it is not.
  Future<String?> connect(String peerId) async {
    final DemoPeer? peer = state.peerById(peerId);
    if (peer == null) return 'unknown';
    if (!peer.onShareXt) return 'notInstalled';
    if (_links.containsKey(peerId)) {
      await _flush(peerId);
      return null;
    }

    _network ??= FakeNetwork();
    _self ??= _network!.addDevice('me');
    final FakeTransport remote = _network!.addDevice(
      peerId,
      faults: const FakeFaults(
        latency: Duration(milliseconds: 220),
        maxFrame: 512,
      ),
    );
    final Future<Link> incoming = remote.incomingLinks().first;
    await remote.startAdvertising(
      Advert(
        serviceData: PeerTag.serviceData(Uint8List(Slp1.peerTagLength)),
      ),
    );

    try {
      final Link link = await _self!.connect(peerId);
      final Link peerSide = await incoming;
      _links[peerId] = link;
      _peerDecoders[peerId] = FrameDecoder();
      _receiptDecoders[peerId] = FrameDecoder();
      _log.info('link ready kind=${link.stats.kind}');

      // The peer side: reassemble, "persist", then acknowledge.
      peerSide.frames.listen((Uint8List frame) {
        final FrameDecoder decoder = _peerDecoders[peerId]!;
        try {
          for (final Uint8List payload in decoder.add(frame)) {
            final String wire = utf8.decode(payload);
            final String id = wire.split('\u0000').first;
            peerSide.send(
              FrameCodec.encode(
                Uint8List.fromList(utf8.encode('ack\u0000$id')),
              ),
            );
          }
        } on FramingException catch (error) {
          _log.warn('peer framing ${error.kind.name}');
        }
      });

      // Our side: receipts mean the peer persisted the message.
      link.frames.listen((Uint8List frame) {
        final FrameDecoder decoder = _receiptDecoders[peerId]!;
        try {
          for (final Uint8List payload in decoder.add(frame)) {
            final List<String> parts = utf8.decode(payload).split('\u0000');
            if (parts.length == 2 && parts.first == 'ack') {
              _outbox.markDelivered(parts[1]);
              _patchStatus(parts[1], MessageStatus.delivered);
              _log.info('receipt delivered');
            }
          }
        } on FramingException catch (error) {
          _log.warn('receipt framing ${error.kind.name}');
        }
      });

      _outbox.setPeerVisible(peerId, visible: true);
      await _flush(peerId);
      return null;
    } catch (error) {
      _log.warn('connect failed type=${error.runtimeType}');
      return 'unreachable';
    }
  }

  /// Persist first, send second (ADR-06).
  Future<void> send(String peerId, String text) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final DemoPeer? peer = state.peerById(peerId);
    if (peer == null) return;

    final String id = 'm${_sequence++}';
    final DateTime at = DateTime.now();
    final Uint8List payload = Uint8List.fromList(
      utf8.encode('$id\u0000$trimmed'),
    );
    _outbox.enqueue(
      OutboxItem(
        id: id,
        peerId: peerId,
        type: MsgType.text,
        payload: payload,
        createdAt: at,
      ),
    );
    if (_disposed) return;
    state = state.copyWith(
      messages: <ChatMessage>[
        ...state.messages,
        ChatMessage(
          id: id,
          peerId: peerId,
          text: trimmed,
          at: at,
          outgoing: true,
          status: MessageStatus.queued,
        ),
      ],
    );
    _log.info('outbox enqueue type=text');

    if (!peer.onShareXt) return; // invite flow (SX-610), never "sent"
    if (!_links.containsKey(peerId)) {
      final String? reason = await connect(peerId);
      if (reason != null) return;
    }
    await _flush(peerId);
  }

  Future<void> _flush(String peerId) async {
    final Link? link = _links[peerId];
    if (link == null) return;
    for (final OutboxItem item in _outbox.due()) {
      if (item.peerId != peerId) continue;
      await link.send(FrameCodec.encode(item.payload));
      _outbox.markSent(item.id);
      _patchStatus(item.id, MessageStatus.sent);
      _log.info('frame sent type=${item.type.name}');
    }
  }

  void _patchStatus(String id, MessageStatus status) {
    if (_disposed) return;
    state = state.copyWith(
      messages: <ChatMessage>[
        for (final ChatMessage message in state.messages)
          if (message.id == id) message.copyWith(status: status) else message,
      ],
    );
  }

  void setDisplayName(String name) {
    state = state.copyWith(displayName: name.trim());
    _log.info('profile name updated');
  }

  void setLocale(Locale? locale) {
    state = locale == null
        ? state.copyWith(clearLocale: true)
        : state.copyWith(localeCode: locale.languageCode);
  }

  void setThemeMode(ThemeMode mode) => state = state.copyWith(themeMode: mode);
}
