/// The radio seam (PLAN section 3, ADR-03, ADR-08).
///
/// Features never import platform code: they see [RadioTransport] and [Link].
/// [FakeTransport] implements the same contract in memory so everything except
/// the air interface can be tested without hardware.
library;

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'constants.dart';

/// What the radio on this device can do (SX-202 fills this in for real).
class RadioCapabilities {
  const RadioCapabilities({
    required this.advertising,
    required this.scanning,
    required this.l2cap,
    required this.gattServer,
    this.maxMtu = 517,
  });

  final bool advertising;
  final bool scanning;
  final bool l2cap;
  final bool gattServer;
  final int maxMtu;

  Map<String, Object?> toJson() => <String, Object?>{
    'advertising': advertising,
    'scanning': scanning,
    'l2cap': l2cap,
    'gattServer': gattServer,
    'maxMtu': maxMtu,
  };
}

/// A device seen advertising the ShAre XT service.
class PeerSighting {
  const PeerSighting({
    required this.handle,
    required this.rssi,
    required this.seenAt,
    this.displayName,
    this.resolved = false,
  });

  /// Opaque per-session handle from the radio (a MAC on Android, a device id on
  /// Windows). Never a stable identity: identity is the Noise key.
  final String handle;

  /// Signal strength in dBm, smoothed by the scanner.
  final int rssi;

  final DateTime seenAt;

  /// Known only after INFO resolution (slow path) or a contact's cached name.
  final String? displayName;

  /// True once INFO was read or the peerTag matched a contact.
  final bool resolved;

  PeerSighting copyWith({String? displayName, bool? resolved}) => PeerSighting(
    handle: handle,
    rssi: rssi,
    seenAt: seenAt,
    displayName: displayName ?? this.displayName,
    resolved: resolved ?? this.resolved,
  );
}

/// What we put in the advertisement / scan response.
class Advert {
  const Advert({this.serviceData, this.connectable = true});

  /// `[version][flags][peerTag]`, see [PeerTag.serviceData]. Null when the
  /// platform cannot add service data (for example Windows peripherals).
  final Uint8List? serviceData;

  final bool connectable;
}

/// Link quality, surfaced in Diagnostics and the transfer sheet.
class LinkStats {
  const LinkStats({
    required this.kind,
    required this.mtu,
    required this.bytesSent,
    required this.bytesReceived,
    this.rssi,
  });

  /// `l2cap` or `gatt`.
  final String kind;
  final int mtu;
  final int bytesSent;
  final int bytesReceived;
  final int? rssi;

  LinkStats addSent(int bytes) => LinkStats(
    kind: kind,
    mtu: mtu,
    bytesSent: bytesSent + bytes,
    bytesReceived: bytesReceived,
    rssi: rssi,
  );

  LinkStats addReceived(int bytes) => LinkStats(
    kind: kind,
    mtu: mtu,
    bytesSent: bytesSent,
    bytesReceived: bytesReceived + bytes,
    rssi: rssi,
  );
}

/// A reliable, ordered byte stream to one peer.
abstract class Link {
  /// Largest frame this link accepts in one [send].
  int get maxFrame;

  /// Frames from the peer. Errors close the stream.
  Stream<Uint8List> get frames;

  /// Queues one frame. Throws [StateError] when the link is closed or the frame
  /// is larger than [maxFrame].
  Future<void> send(Uint8List frame);

  Future<void> close();

  LinkStats get stats;

  /// Fires once when the peer goes away or [close] is called.
  Future<void> get closed;
}

/// The only radio API features may touch.
abstract class RadioTransport {
  Future<RadioCapabilities> capabilities();

  /// Sightings of nearby devices advertising the service UUID.
  Stream<PeerSighting> scan({bool includeOthers = false});

  Future<void> startAdvertising(Advert advert);

  Future<void> stopAdvertising();

  Future<Link> connect(String handle);

  /// Links the peer opened towards us (we advertise, they connect).
  Stream<Link> incomingLinks();

  Future<void> dispose();
}

/// Deterministic faults for [FakeTransport]: everything the radio can do badly.
class FakeFaults {
  const FakeFaults({
    this.latency = Duration.zero,
    this.loss = 0,
    this.maxFrame = 512,
    this.kind = 'gatt',
    this.seed = 7,
  });

  /// One-way delay applied to every frame.
  final Duration latency;

  /// Probability in 0..1 that a frame is dropped.
  final double loss;

  final int maxFrame;

  final String kind;

  /// Keeps a run reproducible.
  final int seed;
}

/// The in-memory harness from ADR-08.
///
/// Create one [FakeTransport] per simulated device, attach it to a
/// [FakeNetwork], start advertising, and the other nodes see it.
class FakeTransport implements RadioTransport {
  FakeTransport({
    required FakeNetwork network,
    required this.deviceId,
    this.faults = const FakeFaults(),
    DateTime Function()? clock,
  }) : _network = network,
       _clock = clock ?? DateTime.now;

  final FakeNetwork _network;
  final FakeFaults faults;
  final String deviceId;
  final DateTime Function() _clock;

  final StreamController<PeerSighting> _sightings =
      StreamController<PeerSighting>.broadcast();
  final StreamController<Link> _incoming = StreamController<Link>.broadcast();
  final Random _random = Random();
  bool _advertising = false;
  bool _disposed = false;
  Advert? _advert;

  /// Frames the network refused because the link was lossy. Tests assert on it.
  int droppedFrames = 0;

  @override
  Future<RadioCapabilities> capabilities() async => const RadioCapabilities(
    advertising: true,
    scanning: true,
    l2cap: true,
    gattServer: true,
  );

  @override
  Stream<PeerSighting> scan({bool includeOthers = false}) {
    _network._registerScanner(this);
    return _sightings.stream;
  }

  @override
  Future<void> startAdvertising(Advert advert) async {
    _advert = advert;
    _advertising = true;
    _network._broadcastSightings();
  }

  @override
  Future<void> stopAdvertising() async {
    _advertising = false;
    _network._broadcastSightings();
  }

  @override
  Future<Link> connect(String handle) async {
    final FakeTransport? peer = _network._find(handle);
    if (peer == null) {
      throw StateError('no such peer: $handle');
    }
    if (!peer._advertising) {
      throw StateError('peer is not advertising: $handle');
    }
    final _FakeLinkPair pair = _FakeLinkPair.create(
      a: this,
      b: peer,
      faultsA: faults,
      faultsB: peer.faults,
      clock: _clock,
    );
    peer._incoming.add(pair.b);
    return pair.a;
  }

  @override
  Stream<Link> incomingLinks() => _incoming.stream;

  @override
  Future<void> dispose() async {
    _disposed = true;
    _advertising = false;
    _network._unregisterScanner(this);
    await _sightings.close();
    await _incoming.close();
  }

  void _emitSighting(FakeTransport other) {
    if (_disposed || _sightings.isClosed) return;
    _sightings.add(
      PeerSighting(
        handle: other.deviceId,
        rssi: -55,
        seenAt: _clock(),
        resolved: other._advert?.serviceData != null,
      ),
    );
  }

  bool _acceptsFrame() {
    if (faults.loss <= 0) return true;
    return _random.nextDouble() >= faults.loss;
  }
}

/// A switchboard for any number of simulated devices.
class FakeNetwork {
  final Map<String, FakeTransport> _nodes = <String, FakeTransport>{};
  final List<FakeTransport> _scanners = <FakeTransport>[];

  /// Adds a device and returns its transport.
  FakeTransport addDevice(
    String id, {
    FakeFaults faults = const FakeFaults(),
    DateTime Function()? clock,
  }) {
    final FakeTransport node = FakeTransport(
      network: this,
      deviceId: id,
      faults: faults,
      clock: clock,
    );
    _nodes[id] = node;
    return node;
  }

  void _registerScanner(FakeTransport scanner) {
    if (!_scanners.contains(scanner)) _scanners.add(scanner);
    _broadcastSightings();
  }

  void _unregisterScanner(FakeTransport scanner) => _scanners.remove(scanner);

  FakeTransport? _find(String id) => _nodes[id];

  void _broadcastSightings() {
    for (final FakeTransport scanner in List<FakeTransport>.of(_scanners)) {
      for (final FakeTransport node in _nodes.values) {
        if (node == scanner || !node._advertising) continue;
        scanner._emitSighting(node);
      }
    }
  }

  Future<void> disposeAll() async {
    for (final FakeTransport node in _nodes.values) {
      await node.dispose();
    }
    _nodes.clear();
    _scanners.clear();
  }
}

class _FakeLinkPair {
  _FakeLinkPair._(this.a, this.b);

  final FakeLink a;
  final FakeLink b;

  factory _FakeLinkPair.create({
    required FakeTransport a,
    required FakeTransport b,
    required FakeFaults faultsA,
    required FakeFaults faultsB,
    required DateTime Function() clock,
  }) {
    final FakeLink linkA = FakeLink(
      owner: a,
      remote: b,
      writeFaults: faultsA,
      readFaults: faultsB,
      clock: clock,
    );
    final FakeLink linkB = FakeLink(
      owner: b,
      remote: a,
      writeFaults: faultsB,
      readFaults: faultsA,
      clock: clock,
    );
    linkA.peer = linkB;
    linkB.peer = linkA;
    return _FakeLinkPair._(linkA, linkB);
  }
}

/// One end of a simulated link.
class FakeLink implements Link {
  FakeLink({
    required this.owner,
    required this.remote,
    required this.writeFaults,
    required this.readFaults,
    required DateTime Function() clock,
  }) : _clock = clock;

  final FakeTransport owner;
  final FakeTransport remote;
  final FakeFaults writeFaults;
  final FakeFaults readFaults;
  final DateTime Function() _clock;

  FakeLink? peer;

  final StreamController<Uint8List> _frames =
      StreamController<Uint8List>.broadcast();
  final Completer<void> _closed = Completer<void>();
  int _sent = 0;
  int _received = 0;
  bool _isClosed = false;

  @override
  int get maxFrame => writeFaults.maxFrame;

  @override
  Stream<Uint8List> get frames => _frames.stream;

  @override
  LinkStats get stats => LinkStats(
    kind: writeFaults.kind,
    mtu: writeFaults.maxFrame,
    bytesSent: _sent,
    bytesReceived: _received,
    rssi: -55,
  );

  @override
  Future<void> get closed => _closed.future;

  @override
  Future<void> send(Uint8List frame) async {
    if (_isClosed) throw StateError('link is closed');
    if (frame.length > maxFrame) {
      throw StateError('frame is ${frame.length} bytes, max is $maxFrame');
    }
    _sent += frame.length;
    final FakeLink? other = peer;
    if (other == null || other._isClosed) return;
    // Loss is applied on the receiving direction's faults.
    if (!other.owner._acceptsFrame()) {
      other.owner.droppedFrames++;
      return;
    }
    final Uint8List copy = Uint8List.fromList(frame);
    if (writeFaults.latency > Duration.zero) {
      Timer(writeFaults.latency, () {
        if (other._isClosed || other._frames.isClosed) return;
        other._received += copy.length;
        other._frames.add(copy);
      });
    } else {
      other._received += copy.length;
      other._frames.add(copy);
    }
    _clock();
  }

  @override
  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;
    if (!_closed.isCompleted) _closed.complete();
    await _frames.close();
    final FakeLink? other = peer;
    peer = null;
    if (other != null) await other._remoteClosed();
  }

  Future<void> _remoteClosed() async {
    if (_isClosed) return;
    _isClosed = true;
    if (!_closed.isCompleted) _closed.complete();
    if (!_frames.isClosed) await _frames.close();
  }
}
