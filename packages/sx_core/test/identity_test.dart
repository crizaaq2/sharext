import 'dart:typed_data';

import 'package:sx_core/sx_core.dart';
import 'package:test/test.dart';

Uint8List fingerprint(int seed) => Uint8List.fromList(
  List<int>.generate(32, (int i) => (i * 7 + seed) & 0xff),
);

void main() {
  group('SafetyNumber', () {
    test('formats 12 groups of 5 digits', () {
      final String value = SafetyNumber.format(fingerprint(1));
      final List<String> groups = value.split(' ');
      expect(groups, hasLength(12));
      for (final String group in groups) {
        expect(group.length, 5);
        expect(int.tryParse(group), isNotNull);
      }
    });

    test('is deterministic for the same key and differs across keys', () {
      expect(
        SafetyNumber.format(fingerprint(1)),
        equals(SafetyNumber.format(fingerprint(1))),
      );
      expect(
        SafetyNumber.format(fingerprint(1)),
        isNot(equals(SafetyNumber.format(fingerprint(2)))),
      );
    });

    test('rejects a fingerprint that is not 32 bytes', () {
      expect(
        () => SafetyNumber.format(Uint8List(16)),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('PeerTag', () {
    test('is six bytes and public-key dependent', () {
      final Uint8List key = fingerprint(3);
      final Uint8List tag = PeerTag.forWindow(key, 1000);
      expect(tag, hasLength(Slp1.peerTagLength));
      expect(tag, isNot(equals(PeerTag.forWindow(fingerprint(4), 1000))));
    });

    test('changes every 15 minutes window', () {
      final Uint8List key = fingerprint(3);
      expect(
        PeerTag.forWindow(key, 1000),
        isNot(equals(PeerTag.forWindow(key, 1001))),
      );
    });

    test('windowFor advances every 900 seconds', () {
      final DateTime base = DateTime.utc(2026, 11, 7, 12, 0, 0);
      final int first = PeerTag.windowFor(base);
      expect(PeerTag.windowFor(base.add(const Duration(seconds: 899))), first);
      expect(PeerTag.windowFor(base.add(const Duration(seconds: 900))), first + 1);
    });

    test('expected() covers the current and neighbouring windows', () {
      final Uint8List key = fingerprint(9);
      final DateTime at = DateTime.utc(2026, 11, 7, 12, 0, 0);
      final List<Uint8List> tags = PeerTag.expected(key, at);
      expect(tags, hasLength(3));
      expect(tags[1], equals(PeerTag.forWindow(key, PeerTag.windowFor(at))));
      expect(tags[0], isNot(equals(tags[1])));
      expect(tags[2], isNot(equals(tags[1])));
    });

    test('service data starts with the frozen version byte', () {
      final Uint8List data = PeerTag.serviceData(
        PeerTag.forWindow(fingerprint(3), 1),
        flags: 0x05,
      );
      expect(data, hasLength(2 + Slp1.peerTagLength));
      expect(data[0], Slp1.serviceDataVersion);
      expect(data[1], 0x05);
    });

    test('hex is lowercase and stable', () {
      final Uint8List tag = PeerTag.forWindow(fingerprint(3), 1);
      final String hex = PeerTag.hex(tag);
      expect(hex, hasLength(12));
      expect(hex, equals(hex.toLowerCase()));
      expect(hex, equals(PeerTag.hex(tag)));
    });
  });
}
