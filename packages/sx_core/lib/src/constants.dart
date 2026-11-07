/// SLP/1 identifiers, message types and limits (PLAN section 4).
///
/// These values are frozen after the first public release. Never reorder or
/// renumber [MsgType]: the wire value is the number in brackets.
library;

/// Protocol constants shared by every ShAre XT implementation.
abstract final class Slp1 {
  /// Advertised service UUID. Scanners always filter on this.
  static const String serviceUuid = 'b7f4e0d2-3c1a-4e8b-9a52-6d0c1f7e4a93';

  /// PeerInfo (protobuf) — small GATT read that resolves a device.
  static const String infoCharacteristic = 'b7f4e0d2-3c1a-4e8b-9a52-6d0c1f7e4a94';

  /// L2CAP PSM as u16 big-endian; 0 means "no L2CAP on this device".
  static const String psmCharacteristic = 'b7f4e0d2-3c1a-4e8b-9a52-6d0c1f7e4a95';

  /// Session frames written by the client (write without response).
  static const String rxCharacteristic = 'b7f4e0d2-3c1a-4e8b-9a52-6d0c1f7e4a96';

  /// Session frames notified by the server.
  static const String txCharacteristic = 'b7f4e0d2-3c1a-4e8b-9a52-6d0c1f7e4a97';

  /// Service-data layout in the scan response: version, flags, 6-byte peerTag.
  static const int serviceDataVersion = 1;
  static const int peerTagLength = 6;

  /// Largest plaintext in one session frame. Keep the allocation cap below it.
  static const int maxPlaintext = 16 * 1024;

  /// Hard cap for one reassembled GATT payload or undecoded frame buffer.
  /// We never allocate more than this for unauthenticated input.
  static const int maxFrame = 64 * 1024;

  /// Largest GATT fragment sequence number (6 bits).
  static const int maxFragmentSequence = 63;

  /// Idle time before a PING, and silence after which a link is dead.
  static const Duration heartbeatIdle = Duration(seconds: 10);
  static const Duration linkTimeout = Duration(seconds: 25);

  /// Retry backoff schedule, seconds, while the peer stays visible.
  static const List<Duration> retryBackoff = <Duration>[
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 16),
    Duration(seconds: 30),
  ];

  /// A peer is stale after this long without a sighting.
  static const Duration sightingStaleAfter = Duration(seconds: 15);

  /// Design limit for simultaneous links (Android allows about 7).
  static const int maxConcurrentLinks = 5;
}

/// Message types inside a session envelope. Wire value in brackets.
enum MsgType {
  hello(0x01),
  text(0x02),
  sticker(0x03),
  receipt(0x04),
  typing(0x05),
  fileOffer(0x10),
  fileAccept(0x11),
  fileReject(0x12),
  fileData(0x13),
  fileAck(0x14),
  fileDone(0x15),
  fileCancel(0x16),
  fileResume(0x17),
  ping(0x20),
  pong(0x21),
  bye(0x22),
  error(0x23);

  const MsgType(this.wire);

  /// Wire value. Frozen.
  final int wire;

  /// Returns null for an unknown type so the caller can ignore it and stay
  /// forward compatible.
  static MsgType? fromWire(int value) {
    for (final MsgType type in values) {
      if (type.wire == value) return type;
    }
    return null;
  }
}

/// Status ladder for one outgoing message (PLAN section 4).
///
/// `delivered` means the peer persisted it, never merely that bytes left us.
enum MessageStatus { queued, sent, delivered, read, failed }

/// What kind of payload an attachment carries.
enum AttachmentKind { image, video, audio, voice, document, apk, other }
