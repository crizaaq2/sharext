import 'dart:convert';
import 'dart:typed_data';

import 'package:sx_core/sx_core.dart';
import 'package:test/test.dart';

OutboxItem item(
  String id, {
  String peer = 'peer-a',
  MsgType type = MsgType.text,
  int length = 4,
  DateTime? at,
}) => OutboxItem(
  id: id,
  peerId: peer,
  type: type,
  payload: Uint8List.fromList(List<int>.filled(length, 0x41)),
  createdAt: at ?? DateTime.utc(2026, 11, 7, 12),
);

void main() {
  late DateTime now;
  late Outbox outbox;

  setUp(() {
    now = DateTime.utc(2026, 11, 7, 12, 0, 10);
    outbox = Outbox(clock: () => now);
  });

  test('enqueue dedupes by id', () {
    expect(outbox.enqueue(item('a')), isTrue);
    expect(outbox.enqueue(item('a')), isFalse);
    expect(outbox.pendingCount, 1);
  });

  test('only visible peers get items due, oldest first', () {
    outbox.enqueue(item('a', at: DateTime.utc(2026, 11, 7, 12, 0, 5)));
    outbox.enqueue(item('b', at: DateTime.utc(2026, 11, 7, 12, 0, 1)));
    outbox.enqueue(item('c', peer: 'peer-b', at: DateTime.utc(2026, 11, 7, 12)));

    expect(outbox.due(), isEmpty);
    outbox.setPeerVisible('peer-a', visible: true);
    expect(
      outbox.due().map((OutboxItem i) => i.id).toList(),
      equals(<String>['b', 'a']),
    );

    outbox.setPeerVisible('peer-b', visible: true);
    expect(outbox.due(), hasLength(3));
  });

  test('markSent schedules the frozen backoff and never says delivered', () {
    outbox.setPeerVisible('peer-a', visible: true);
    outbox.enqueue(item('a'));

    final List<Duration> observed = <Duration>[];
    for (int attempt = 0; attempt < Slp1.retryBackoff.length + 1; attempt++) {
      outbox.markSent('a');
      final OutboxItem current = outbox.items.single;
      expect(current.status, MessageStatus.sent);
      observed.add(current.nextAttemptAt.difference(now));
      expect(outbox.due(), isEmpty, reason: 'backoff has not elapsed yet');
      now = current.nextAttemptAt;
    }
    expect(observed.take(6).toList(), equals(Slp1.retryBackoff));
    expect(
      observed.last,
      equals(Slp1.retryBackoff.last),
      reason: 'the schedule clamps at 30 s',
    );
  });

  test('markDelivered is the only thing that removes an item', () {
    outbox.setPeerVisible('peer-a', visible: true);
    outbox.enqueue(item('a'));
    outbox.markDelivered('a');
    expect(outbox.pendingCount, 0);
    expect(outbox.enqueue(item('a')), isFalse, reason: 'no double send');
  });

  test('markFailed keeps the item for the UI but stops the scheduler', () {
    outbox.setPeerVisible('peer-a', visible: true);
    outbox.enqueue(item('a'));
    outbox.markFailed('a');
    expect(outbox.items.single.status, MessageStatus.failed);
    expect(outbox.due(), isEmpty);
  });

  test('survives a JSON round trip, including the retry clock', () {
    outbox.setPeerVisible('peer-a', visible: true);
    outbox.enqueue(item('a', at: DateTime.utc(2026, 11, 7, 12, 0, 3)));
    outbox.enqueue(item('b', peer: 'peer-b'));
    outbox.markSent('a');

    final String encoded = jsonEncode(outbox.toJson());
    final List<Map<String, Object?>> decoded =
        (jsonDecode(encoded) as List<Object?>).cast<Map<String, Object?>>();
    final Outbox restored = Outbox.restore(decoded, clock: () => now);

    expect(restored.pendingCount, 2);
    expect(restored.items.first.id, 'a');
    expect(restored.items.first.status, MessageStatus.sent);
    expect(restored.items.first.attempts, 1);
    expect(restored.items.first.payload, equals(item('a').payload));
    // Nothing is visible after a restart until the scanner says so.
    expect(restored.due(), isEmpty);
    restored.setPeerVisible('peer-a', visible: true);
    // The 1 s backoff recorded before the restart still applies.
    expect(restored.due(), isEmpty);
    now = DateTime.utc(2026, 11, 7, 12, 0, 11);
    expect(restored.due(), hasLength(1));
  });

  test('restore drops duplicates so a crash replay cannot double send', () {
    final List<Map<String, Object?>> json = <Map<String, Object?>>[
      item('a').toJson(),
      item('a').toJson(),
    ];
    expect(Outbox.restore(json).pendingCount, 1);
  });

  test('filters by message type for the priority scheduler', () {
    outbox.setPeerVisible('peer-a', visible: true);
    outbox.enqueue(item('file', type: MsgType.fileData));
    outbox.enqueue(item('text', type: MsgType.text));
    expect(
      outbox.due(msgType: MsgType.text).map((OutboxItem i) => i.id),
      equals(<String>['text']),
    );
    expect(
      outbox.due(msgType: MsgType.fileData).map((OutboxItem i) => i.id),
      equals(<String>['file']),
    );
  });
}
