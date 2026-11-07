import 'dart:typed_data';

import 'package:sx_core/sx_core.dart';
import 'package:test/test.dart';

Uint8List bytes(int length, {int seed = 0}) =>
    Uint8List.fromList(List<int>.generate(length, (int i) => (i + seed) & 0xff));

void main() {
  group('GattFragmenter', () {
    test('round trips a payload across many fragments', () {
      final Uint8List payload = bytes(5000);
      final List<Uint8List> fragments = GattFragmenter(
        maxFragmentBytes: 512,
      ).fragment(payload);
      expect(fragments, isNotEmpty);
      expect(fragments.every((Uint8List f) => f.length <= 512), isTrue);
      // START on the first, END on the last, sequence counts up.
      expect(fragments.first[0] & 0x01, 1);
      expect(fragments.last[0] & 0x02, 2);
      for (int i = 0; i < fragments.length; i++) {
        expect((fragments[i][0] >> 2) & 0x3f, i);
      }

      final GattReassembler reassembler = GattReassembler();
      Uint8List? rebuilt;
      for (final Uint8List fragment in fragments) {
        rebuilt = reassembler.add(fragment) ?? rebuilt;
      }
      expect(rebuilt, equals(payload));
      expect(reassembler.inProgress, isFalse);
    });

    test('sends an empty payload as one START|END fragment', () {
      final List<Uint8List> fragments = GattFragmenter().fragment(
        Uint8List(0),
      );
      expect(fragments, hasLength(1));
      expect(fragments.single[0], 0x03);
      expect(GattReassembler().add(fragments.single), isEmpty);
    });

    test('refuses payloads that need more than 64 fragments', () {
      expect(
        () => GattFragmenter(maxFragmentBytes: 2).fragment(bytes(128)),
        throwsA(
          isA<FramingException>().having(
            (FramingException e) => e.kind,
            'kind',
            FrameError.oversized,
          ),
        ),
      );
    });
  });

  group('GattReassembler', () {
    test('rejects a fragment that arrives without START', () {
      final Uint8List orphan = Uint8List.fromList(<int>[0x02, 0x41]);
      expect(
        () => GattReassembler().add(orphan),
        throwsA(
          isA<FramingException>().having(
            (FramingException e) => e.kind,
            'kind',
            FrameError.truncated,
          ),
        ),
      );
    });

    test('aborts on a sequence gap and forgets the half payload', () {
      final GattReassembler reassembler = GattReassembler();
      final List<Uint8List> fragments = GattFragmenter(
        maxFragmentBytes: 4,
      ).fragment(bytes(20));
      expect(reassembler.add(fragments.first), isNull);
      expect(
        () => reassembler.add(fragments[2]),
        throwsA(
          isA<FramingException>().having(
            (FramingException e) => e.kind,
            'kind',
            FrameError.sequenceGap,
          ),
        ),
      );
      expect(reassembler.inProgress, isFalse);
    });

    test('caps the reassembled payload at maxPayloadBytes', () {
      final GattReassembler reassembler = GattReassembler(maxPayloadBytes: 10);
      final List<Uint8List> fragments = GattFragmenter(
        maxFragmentBytes: 8,
      ).fragment(bytes(40));
      expect(
        () {
          for (final Uint8List fragment in fragments) {
            reassembler.add(fragment);
          }
        },
        throwsA(
          isA<FramingException>().having(
            (FramingException e) => e.kind,
            'kind',
            FrameError.oversized,
          ),
        ),
      );
    });

    test('rejects an empty fragment', () {
      expect(
        () => GattReassembler().add(Uint8List(0)),
        throwsA(isA<FramingException>()),
      );
    });
  });

  group('FrameCodec and FrameDecoder', () {
    test('round trips one frame split arbitrarily across chunks', () {
      final Uint8List plaintext = bytes(300, seed: 12);
      final Uint8List wire = FrameCodec.encode(plaintext);
      expect(wire.length, plaintext.length + 2);
      expect((wire[0] << 8) | wire[1], plaintext.length);

      final FrameDecoder decoder = FrameDecoder();
      final List<Uint8List> out = <Uint8List>[];
      for (int i = 0; i < wire.length; i += 7) {
        final int end = i + 7 > wire.length ? wire.length : i + 7;
        out.addAll(decoder.add(Uint8List.sublistView(wire, i, end)));
      }
      expect(out, hasLength(1));
      expect(out.single, equals(plaintext));
      expect(decoder.bufferedBytes, 0);
    });

    test('returns two frames delivered in one chunk', () {
      final Uint8List a = FrameCodec.encode(bytes(10, seed: 1));
      final Uint8List b = FrameCodec.encode(bytes(32, seed: 2));
      final Uint8List joined = Uint8List.fromList(<int>[...a, ...b]);
      final List<Uint8List> frames = FrameDecoder().add(joined);
      expect(frames, hasLength(2));
      expect(frames.first, equals(bytes(10, seed: 1)));
      expect(frames.last, equals(bytes(32, seed: 2)));
    });

    test('refuses a plaintext larger than maxPlaintext', () {
      expect(
        () => FrameCodec.encode(
          Uint8List(Slp1.maxPlaintext + 1),
        ),
        throwsA(isA<FramingException>()),
      );
    });

    test('fails fast on a hostile length prefix instead of buffering', () {
      final Uint8List hostile = Uint8List.fromList(<int>[0xff, 0xff, 0x00]);
      expect(
        () => FrameDecoder().add(hostile),
        throwsA(
          isA<FramingException>().having(
            (FramingException e) => e.kind,
            'kind',
            FrameError.oversized,
          ),
        ),
      );
    });

    test('keeps a half frame across calls, then completes it', () {
      final FrameDecoder decoder = FrameDecoder();
      final Uint8List wire = FrameCodec.encode(bytes(40, seed: 5));
      expect(decoder.add(Uint8List.sublistView(wire, 0, 3)), isEmpty);
      expect(decoder.bufferedBytes, 3);
      final List<Uint8List> frames = decoder.add(
        Uint8List.sublistView(wire, 3),
      );
      expect(frames, hasLength(1));
      expect(frames.single, equals(bytes(40, seed: 5)));
    });
  });
}
