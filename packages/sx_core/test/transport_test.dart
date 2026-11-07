import 'dart:async';
import 'dart:typed_data';

import 'package:sx_core/sx_core.dart';
import 'package:test/test.dart';

Uint8List frame(int value) => Uint8List.fromList(<int>[value, value, value]);

void main() {
  late FakeNetwork network;

  setUp(() => network = FakeNetwork());
  tearDown(() => network.disposeAll());

  test('an advertising device is seen by a scanning device', () async {
    final FakeTransport phone = network.addDevice('phone');
    final FakeTransport laptop = network.addDevice('laptop');
    expect(await phone.capabilities(), isA<RadioCapabilities>());

    final List<PeerSighting> seen = <PeerSighting>[];
    final StreamSubscription<PeerSighting> sub = laptop.scan().listen(seen.add);
    await phone.startAdvertising(
      Advert(serviceData: PeerTag.serviceData(Uint8List(6))),
    );
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(seen.map((PeerSighting s) => s.handle), contains('phone'));
    expect(seen.single.resolved, isTrue);
  });

  test('frames travel both ways over one link', () async {
    final FakeTransport a = network.addDevice('a');
    final FakeTransport b = network.addDevice('b');
    await a.startAdvertising(const Advert());
    await b.startAdvertising(const Advert());

    final Future<Link> incoming = b.incomingLinks().first;
    final Link linkA = await a.connect('b');
    final Link linkB = await incoming;

    final Future<Uint8List> gotB = linkB.frames.first;
    await linkA.send(frame(1));
    expect(await gotB, equals(frame(1)));

    final Future<Uint8List> gotA = linkA.frames.first;
    await linkB.send(frame(2));
    expect(await gotA, equals(frame(2)));

    expect(linkA.stats.bytesSent, 3);
    expect(linkA.stats.bytesReceived, 3);
    expect(linkA.stats.kind, 'gatt');
  });

  test('rejects frames larger than the link MTU', () async {
    final FakeTransport a = network.addDevice(
      'a',
      faults: const FakeFaults(maxFrame: 8),
    );
    final FakeTransport b = network.addDevice('b');
    await b.startAdvertising(const Advert());
    final Link link = await a.connect('b');
    await expectLater(link.send(Uint8List(9)), throwsA(isA<StateError>()));
  });

  test('a total-loss link drops frames and counts them', () async {
    final FakeTransport a = network.addDevice('a');
    final FakeTransport b = network.addDevice(
      'b',
      faults: const FakeFaults(loss: 1),
    );
    await b.startAdvertising(const Advert());
    final Link link = await a.connect('b');

    final List<Uint8List> received = <Uint8List>[];
    final StreamSubscription<Uint8List> sub = link.frames.listen(received.add);
    await link.send(frame(5));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await sub.cancel();

    expect(received, isEmpty);
    expect(b.droppedFrames, 1);
  });

  test('connecting to a peer that is not advertising fails', () async {
    final FakeTransport a = network.addDevice('a');
    network.addDevice('b');
    await expectLater(a.connect('b'), throwsA(isA<StateError>()));
  });

  test('closing a link closes the peer side too', () async {
    final FakeTransport a = network.addDevice('a');
    final FakeTransport b = network.addDevice('b');
    await b.startAdvertising(const Advert());
    final Future<Link> incoming = b.incomingLinks().first;
    final Link linkA = await a.connect('b');
    final Link linkB = await incoming;

    final Future<void> peerClosed = linkB.closed;
    await linkA.close();
    await peerClosed;
    await expectLater(linkA.send(frame(1)), throwsA(isA<StateError>()));
  });
}
