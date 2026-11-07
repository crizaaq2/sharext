/// Identity: safety numbers and rotating advertisement tags (PLAN sections 4, 5).
///
/// The private key itself never lives here — this file only derives what is
/// safe to show or broadcast. Keys are stored by the platform plugin.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'constants.dart';

/// The 60-digit safety number a person compares out loud or scans as a QR.
///
/// Derived from the SHA-256 fingerprint of the peer's long-term public key, in
/// twelve groups of five digits. Deterministic across platforms and versions.
abstract final class SafetyNumber {
  static const int _groups = 12;
  static const int _digitsPerGroup = 5;

  /// [fingerprint] is the SHA-256 of the peer's public key (32 bytes).
  static String format(Uint8List fingerprint) {
    final List<int> digits = _digits(fingerprint);
    final List<String> groups = <String>[];
    for (int i = 0; i < _groups; i++) {
      final int offset = i * _digitsPerGroup;
      groups.add(digits.sublist(offset, offset + _digitsPerGroup).join());
    }
    return groups.join(' ');
  }

  /// Unformatted digits, for QR payloads and tests.
  static List<int> digits(Uint8List fingerprint) => _digits(fingerprint);

  static List<int> _digits(Uint8List fingerprint) {
    if (fingerprint.length != 32) {
      throw ArgumentError.value(
        fingerprint.length,
        'fingerprint',
        'a SHA-256 fingerprint is 32 bytes',
      );
    }
    final int wanted = _groups * _digitsPerGroup;
    final List<int> out = <int>[];
    int counter = 0;
    while (out.length < wanted) {
      // Extend the fingerprint deterministically: hash(fingerprint || counter).
      final List<int> seed = <int>[
        ...fingerprint,
        (counter >> 8) & 0xff,
        counter & 0xff,
      ];
      final List<int> block = sha256.convert(seed).bytes;
      for (int i = 0; i + 3 < block.length && out.length < wanted; i += 4) {
        final int value =
            ((block[i] << 24) |
                (block[i + 1] << 16) |
                (block[i + 2] << 8) |
                block[i + 3]) &
            0x7fffffff;
        final String chunk = (value % 100000).toString().padLeft(
          _digitsPerGroup,
          '0',
        );
        for (final int code in chunk.codeUnits) {
          out.add(code - 0x30);
        }
      }
      counter++;
    }
    return out.sublist(0, wanted);
  }
}

/// The rotating 6-byte tag a device puts in its scan response.
///
/// peerTag = first 6 bytes of HMAC-SHA256(key = peer public key,
/// msg = "sx-tag" + floor(unixTime / 900)). Contacts recompute the current and
/// neighbouring 15-minute windows; strangers cannot correlate tags over time.
abstract final class PeerTag {
  static const String _prefix = 'sx-tag';
  static const int windowSeconds = 900;

  /// Window number for [at] (UTC seconds since the epoch divided by 900).
  static int windowFor(DateTime at) =>
      at.toUtc().millisecondsSinceEpoch ~/ 1000 ~/ windowSeconds;

  /// The tag a contact expects for [window].
  static Uint8List forWindow(Uint8List publicKey, int window) {
    final Hmac hmac = Hmac(sha256, publicKey);
    final List<int> message = <int>[
      ...utf8.encode(_prefix),
      (window >> 24) & 0xff,
      (window >> 16) & 0xff,
      (window >> 8) & 0xff,
      window & 0xff,
    ];
    final List<int> mac = hmac.convert(message).bytes;
    return Uint8List.fromList(mac.sublist(0, Slp1.peerTagLength));
  }

  /// Tags to watch for at [at]: current window and its neighbours.
  static List<Uint8List> expected(Uint8List publicKey, DateTime at) {
    final int window = windowFor(at);
    return <Uint8List>[
      for (int delta = -1; delta <= 1; delta++)
        forWindow(publicKey, window + delta),
    ];
  }

  /// Hex form for logs. Tags are public, but logs still never carry keys.
  static String hex(Uint8List tag) => tag
      .map((int b) => b.toRadixString(16).padLeft(2, '0'))
      .join();

  /// Builds an advertisement's service-data field: version, flags, peerTag.
  static Uint8List serviceData(Uint8List tag, {int flags = 0}) {
    final Uint8List out = Uint8List(2 + Slp1.peerTagLength);
    out[0] = Slp1.serviceDataVersion;
    out[1] = flags & 0xff;
    out.setRange(2, out.length, tag);
    return out;
  }
}
