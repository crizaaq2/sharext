/// SLP/1 framing: GATT fragments and length-prefixed session frames.
///
/// Two layers, both side-effect free and unit tested:
///
///  * [GattFragmenter] / [GattReassembler] — a GATT character write or
///    notification carries `1 header byte + chunk`. Header bit 0 is START,
///    bit 1 is END, bits 2..7 are the sequence number modulo 64.
///  * [FrameCodec] / [FrameDecoder] — session frames are
///    `[len:u16 big-endian][Noise ciphertext]`, plaintext at most 16 KB.
///
/// Both layers cap every allocation: unauthenticated input can never make us
/// allocate more than [Slp1.maxFrame] bytes.
library;

import 'dart:typed_data';

import 'constants.dart';

/// Why framing gave up. Deliberately coarse: no payload detail leaks.
enum FrameError {
  /// A fragment arrived whose sequence number is not the next one.
  sequenceGap,

  /// More data than the protocol allows.
  oversized,

  /// An empty fragment or a malformed length prefix.
  malformed,

  /// The link was reset while a payload was in flight.
  truncated,
}

/// Thrown by the framing layer. Carries no message content.
class FramingException implements Exception {
  const FramingException(this.kind, this.detail);

  final FrameError kind;
  final String detail;

  @override
  String toString() => 'FramingException(${kind.name}): $detail';
}

/// Splits one payload into GATT fragments. Not reusable across payloads.
class GattFragmenter {
  GattFragmenter({this.maxFragmentBytes = 512})
    : assert(maxFragmentBytes >= 2, 'a fragment needs a header and one byte');

  /// Total bytes per GATT write including the header byte.
  final int maxFragmentBytes;

  /// Returns 1 to 64 fragments covering [payload].
  List<Uint8List> fragment(Uint8List payload) {
    final int chunk = maxFragmentBytes - 1;
    final int count = payload.isEmpty ? 1 : (payload.length + chunk - 1) ~/ chunk;
    if (count > Slp1.maxFragmentSequence + 1) {
      throw FramingException(
        FrameError.oversized,
        'payload needs $count fragments, the wire allows at most 64',
      );
    }
    final List<Uint8List> out = <Uint8List>[];
    for (int i = 0; i < count; i++) {
      final int start = i * chunk;
      final int end = start + chunk > payload.length ? payload.length : start + chunk;
      final int safeStart = start > payload.length ? payload.length : start;
      final Uint8List body = Uint8List.sublistView(payload, safeStart, end);
      int header = (i & 0x3f) << 2;
      if (i == 0) header |= 0x01;
      if (i == count - 1) header |= 0x02;
      final Uint8List frame = Uint8List(body.length + 1);
      frame[0] = header;
      frame.setRange(1, frame.length, body);
      out.add(frame);
    }
    return out;
  }
}

/// Rebuilds one payload from GATT fragments.
///
/// A sequence gap, an oversized payload or an empty fragment aborts the payload
/// and throws; the caller must then close the link.
class GattReassembler {
  GattReassembler({this.maxPayloadBytes = Slp1.maxFrame});

  final int maxPayloadBytes;

  final BytesBuilder _buffer = BytesBuilder(copy: true);
  int _expectedSequence = 0;
  bool _active = false;

  /// True between a START fragment and its END fragment.
  bool get inProgress => _active;

  /// Feed one fragment; returns the payload when the END fragment arrives.
  Uint8List? add(Uint8List fragment) {
    if (fragment.isEmpty) {
      _reset();
      throw const FramingException(FrameError.malformed, 'empty fragment');
    }
    final int header = fragment[0];
    final bool start = header & 0x01 != 0;
    final bool end = header & 0x02 != 0;
    final int sequence = (header >> 2) & 0x3f;

    if (start) {
      _buffer.clear();
      _active = true;
      _expectedSequence = 0;
    } else if (!_active) {
      throw const FramingException(
        FrameError.truncated,
        'fragment without a START',
      );
    }

    if (sequence != _expectedSequence) {
      final int got = sequence;
      _reset();
      throw FramingException(
        FrameError.sequenceGap,
        'expected fragment $_expectedSequence, got $got',
      );
    }

    final Uint8List body = Uint8List.sublistView(fragment, 1);
    if (_buffer.length + body.length > maxPayloadBytes) {
      _reset();
      throw FramingException(
        FrameError.oversized,
        'payload exceeds $maxPayloadBytes bytes',
      );
    }
    _buffer.add(body);
    _expectedSequence = (sequence + 1) & 0x3f;

    if (!end) return null;
    final Uint8List payload = _buffer.takeBytes();
    _active = false;
    _expectedSequence = 0;
    return payload;
  }

  /// Drop any half-received payload (link reset, peer gone).
  void reset() => _reset();

  void _reset() {
    _buffer.clear();
    _active = false;
    _expectedSequence = 0;
  }
}

/// Encodes session frames: two length bytes then the ciphertext.
abstract final class FrameCodec {
  /// Wraps [plaintext] (already encrypted by Noise) in a length prefix.
  static Uint8List encode(Uint8List plaintext) {
    if (plaintext.length > Slp1.maxPlaintext) {
      throw FramingException(
        FrameError.oversized,
        'plaintext is ${plaintext.length} bytes, limit is ${Slp1.maxPlaintext}',
      );
    }
    final Uint8List out = Uint8List(plaintext.length + 2);
    out[0] = (plaintext.length >> 8) & 0xff;
    out[1] = plaintext.length & 0xff;
    out.setRange(2, out.length, plaintext);
    return out;
  }
}

/// Incremental decoder for length-prefixed session frames.
///
/// Feed arbitrary byte chunks; get whole frames back. A length prefix larger
/// than [Slp1.maxPlaintext] fails immediately instead of buffering.
class FrameDecoder {
  final List<int> _pending = <int>[];

  /// Number of bytes buffered but not yet framed.
  int get bufferedBytes => _pending.length;

  /// Throws [FramingException] on a bad prefix or on an oversized buffer.
  List<Uint8List> add(Uint8List chunk) {
    if (chunk.isNotEmpty) _pending.addAll(chunk);
    final List<Uint8List> frames = <Uint8List>[];
    int offset = 0;
    while (_pending.length - offset >= 2) {
      final int length = (_pending[offset] << 8) | _pending[offset + 1];
      if (length > Slp1.maxPlaintext) {
        _pending.clear();
        throw FramingException(
          FrameError.oversized,
          'length prefix $length exceeds ${Slp1.maxPlaintext}',
        );
      }
      final int available = _pending.length - offset - 2;
      if (available < length) break;
      frames.add(
        Uint8List.fromList(
          _pending.sublist(offset + 2, offset + 2 + length),
        ),
      );
      offset += 2 + length;
    }
    if (offset > 0) _pending.removeRange(0, offset);
    if (_pending.length > Slp1.maxPlaintext + 2) {
      _pending.clear();
      throw const FramingException(
        FrameError.oversized,
        'decoder buffer grew past one maximum frame',
      );
    }
    return frames;
  }

  /// Discard buffered bytes (link reset).
  void reset() => _pending.clear();
}
