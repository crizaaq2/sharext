import 'package:sx_core/sx_core.dart';
import 'package:test/test.dart';

void main() {
  group('Redactor', () {
    test('removes hex keys, key=value secrets, blobs and paths', () {
      final String scrubbed = Redactor.scrub(
        'handshake key=0011aabbccdd ok '
        'pub 9f8e7d6c5b4a39281706f5e4d3c2b1a09f8e7d6c5b4a39281706f5e4d3c2b1a0 '
        'file /home/max/DCIM/photo.jpg question=Fariin sir ah?',
      );
      expect(scrubbed, contains('key=<redacted>'));
      expect(scrubbed, contains('<hex>'));
      expect(scrubbed, contains('<path>'));
      expect(scrubbed, isNot(contains('photo.jpg')));
      expect(scrubbed, isNot(contains('9f8e7d6c')));
    });

    test('leaves ordinary event lines alone', () {
      const String line = 'link ready kind=gatt mtu=517';
      expect(Redactor.scrub(line), equals(line));
    });
  });

  group('SxLog', () {
    test('keeps only the newest capacity records', () {
      int tick = 0;
      final SxLog log = SxLog(
        capacity: 3,
        clock: () => DateTime.utc(2026, 11, 7, 12, 0, tick++),
      );
      for (int i = 0; i < 5; i++) {
        log.info('event $i');
      }
      expect(log.records, hasLength(3));
      expect(log.records.first.line, 'event 2');
      expect(log.records.last.line, 'event 4');
    });

    test('export never contains a secret', () {
      final SxLog log = SxLog();
      log.info('identity created');
      log.error('noise key=abc123 rejected');
      final String text = log.export();
      expect(text, contains('ShAre XT diagnostics log'));
      expect(text, contains('identity created'));
      expect(text, contains('key=<redacted>'));
      expect(text, isNot(contains('abc123')));
    });

    test('clear empties the buffer', () {
      final SxLog log = SxLog();
      log.warn('bluetooth off');
      log.clear();
      expect(log.records, isEmpty);
    });
  });

  group('FeatureFlags', () {
    test('ship the plan defaults', () {
      final FeatureFlags flags = FeatureFlags();
      expect(flags.isEnabled(FeatureFlag.l2cap), isTrue);
      expect(flags.isEnabled(FeatureFlag.turbo), isFalse);
      expect(flags.isEnabled(FeatureFlag.showOtherDevices), isFalse);
    });

    test('overrides are immutable and serialise by name', () {
      final FeatureFlags base = FeatureFlags();
      final FeatureFlags changed = base.withFlag(FeatureFlag.turbo, enabled: true);
      expect(changed.isEnabled(FeatureFlag.turbo), isTrue);
      expect(base.isEnabled(FeatureFlag.turbo), isFalse);
      expect(changed.toJson()['turbo'], isTrue);
    });
  });

  test('SLP/1 identifiers stay frozen', () {
    expect(Slp1.serviceUuid, 'b7f4e0d2-3c1a-4e8b-9a52-6d0c1f7e4a93');
    expect(Slp1.infoCharacteristic, endsWith('94'));
    expect(Slp1.psmCharacteristic, endsWith('95'));
    expect(Slp1.rxCharacteristic, endsWith('96'));
    expect(Slp1.txCharacteristic, endsWith('97'));
    expect(MsgType.fromWire(0x02), MsgType.text);
    expect(MsgType.fromWire(0x99), isNull, reason: 'unknown types are ignored');
    expect(Slp1.retryBackoff, hasLength(6));
  });
}
