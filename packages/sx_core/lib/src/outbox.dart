/// The outbox: persist first, send second (ADR-06, PLAN section 4).
///
/// This is the whole reliability contract in one place, without radios, timers
/// or Flutter: an item is stored, then handed to a link, and it only leaves the
/// outbox when the peer has ACKed after persisting. Retries follow the frozen
/// backoff schedule while the peer is visible; an invisible peer keeps its
/// items queued, which is what "Waiting for Axmed's phone" means.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'constants.dart';

/// One queued thing to send to one peer.
class OutboxItem {
  OutboxItem({
    required this.id,
    required this.peerId,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.status = MessageStatus.queued,
    this.attempts = 0,
    DateTime? nextAttemptAt,
  }) : nextAttemptAt = nextAttemptAt ?? createdAt;

  /// UUIDv7 (or any stable unique id) for a user message.
  final String id;

  /// Stable peer identity: the peer's public-key fingerprint, not a MAC address.
  final String peerId;

  final MsgType type;

  /// Envelope bytes, already serialised. The outbox never inspects or logs them.
  final Uint8List payload;

  final DateTime createdAt;

  final MessageStatus status;

  /// How many times a link write was attempted for this item.
  final int attempts;

  /// Earliest moment the scheduler may hand this item to a link again.
  final DateTime nextAttemptAt;

  OutboxItem copyWith({
    MessageStatus? status,
    int? attempts,
    DateTime? nextAttemptAt,
  }) => OutboxItem(
    id: id,
    peerId: peerId,
    type: type,
    payload: payload,
    createdAt: createdAt,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
  );

  /// Persisted form. Payload is base64 so it survives a JSON round trip.
  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'peer': peerId,
    'type': type.name,
    'payload': base64Encode(payload),
    'created': createdAt.toUtc().toIso8601String(),
    'status': status.name,
    'attempts': attempts,
    'next': nextAttemptAt.toUtc().toIso8601String(),
  };

  static OutboxItem fromJson(Map<String, Object?> json) {
    final Object? rawType = json['type'];
    final MsgType type = MsgType.values.firstWhere(
      (MsgType t) => t.name == rawType,
      orElse: () => MsgType.text,
    );
    return OutboxItem(
      id: json['id']! as String,
      peerId: json['peer']! as String,
      type: type,
      payload: Uint8List.fromList(base64Decode(json['payload']! as String)),
      createdAt: DateTime.parse(json['created']! as String).toLocal(),
      status: MessageStatus.values.firstWhere(
        (MessageStatus s) => s.name == json['status'],
        orElse: () => MessageStatus.queued,
      ),
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      nextAttemptAt: DateTime.parse(json['next']! as String).toLocal(),
    );
  }
}

/// In-memory outbox with a persistence hook. The database (SX-301) will store
/// [toJson] output; the logic and its tests stay here.
class Outbox {
  Outbox({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  /// Test seam. Production passes the wall clock.
  final DateTime Function() _clock;

  final List<OutboxItem> _items = <OutboxItem>[];
  final Set<String> _deliveredIds = <String>{};
  final Set<String> _visiblePeers = <String>{};

  /// Items currently queued or sent but not yet delivered by the peer.
  List<OutboxItem> get items => List<OutboxItem>.unmodifiable(_items);

  int get pendingCount => _items.length;

  /// Adds [item] unless its id was already delivered this session.
  ///
  /// Returns false for a duplicate, which is how we avoid double-sending after
  /// a reconnect or a crash replay.
  bool enqueue(OutboxItem item) {
    if (_deliveredIds.contains(item.id) ||
        _items.any((OutboxItem i) => i.id == item.id)) {
      return false;
    }
    _items.add(item);
    return true;
  }

  /// Marks a peer reachable or gone. Only visible peers get link writes.
  void setPeerVisible(String peerId, {required bool visible}) {
    if (visible) {
      _visiblePeers.add(peerId);
    } else {
      _visiblePeers.remove(peerId);
    }
  }

  bool isPeerVisible(String peerId) => _visiblePeers.contains(peerId);

  /// Items the scheduler may write right now, oldest first.
  ///
  /// Control frames travel out of band; this queue is text and callers should
  /// pass [msgType] to keep the priority order control → text → bulk.
  List<OutboxItem> due({MsgType? msgType}) {
    final DateTime now = _clock();
    final List<OutboxItem> ready = _items
        .where(
          (OutboxItem i) =>
              _visiblePeers.contains(i.peerId) &&
              i.status != MessageStatus.failed &&
              !i.nextAttemptAt.isAfter(now) &&
              (msgType == null || i.type == msgType),
        )
        .toList()
      ..sort((OutboxItem a, OutboxItem b) {
        final int byTime = a.createdAt.compareTo(b.createdAt);
        return byTime != 0 ? byTime : a.id.compareTo(b.id);
      });
    return ready;
  }

  /// Records that the item was written to a link.
  ///
  /// Status becomes `sent` (never `delivered`) and the next retry time comes
  /// from the frozen backoff schedule.
  void markSent(String id) {
    final int index = _items.indexWhere((OutboxItem i) => i.id == id);
    if (index < 0) return;
    final OutboxItem item = _items[index];
    final int attempts = item.attempts + 1;
    final Duration delay =
        Slp1.retryBackoff[(attempts - 1).clamp(0, Slp1.retryBackoff.length - 1)];
    _items[index] = item.copyWith(
      status: MessageStatus.sent,
      attempts: attempts,
      nextAttemptAt: _clock().add(delay),
    );
  }

  /// The peer persisted the item and ACKed. Only now is it delivered.
  void markDelivered(String id) {
    final int index = _items.indexWhere((OutboxItem i) => i.id == id);
    if (index < 0) return;
    _items.removeAt(index);
    _deliveredIds.add(id);
  }

  /// Explicit failure (file rejected, contact blocked). Item leaves the queue.
  void markFailed(String id) {
    final int index = _items.indexWhere((OutboxItem i) => i.id == id);
    if (index < 0) return;
    _items[index] = _items[index].copyWith(status: MessageStatus.failed);
  }

  /// Drop a failed item after the person dismissed it.
  void remove(String id) {
    _items.removeWhere((OutboxItem i) => i.id == id);
    _deliveredIds.add(id);
  }

  /// A peer reset or asked us to resend everything: clear dedupe memory.
  void forgetDelivered() => _deliveredIds.clear();

  List<Map<String, Object?>> toJson() =>
      _items.map((OutboxItem i) => i.toJson()).toList();

  /// Rebuilds the queue at boot. Duplicates are dropped, order is preserved.
  static Outbox restore(
    List<Map<String, Object?>> json, {
    DateTime Function()? clock,
  }) {
    final Outbox outbox = Outbox(clock: clock);
    for (final Map<String, Object?> entry in json) {
      outbox.enqueue(OutboxItem.fromJson(entry));
    }
    return outbox;
  }
}
