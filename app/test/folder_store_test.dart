import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sharext/features/files/folder_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('sharext/storage');
  final List<String> calls = <String>[];

  void answer(Future<Object?> Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) {
          calls.add(call.method);
          return handler(call);
        });
  }

  setUp(calls.clear);

  tearDown(
    () => TestDefaultBinaryMessengerBinding
        .instance
        .defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  test('reports the saved folder', () async {
    answer(
      (_) async =>
          <String, Object?>{'name': 'ShAre XT', 'uri': 'content://tree/shared'},
    );

    final SxFolder? folder = await ChannelFolderStore(channel).current();

    expect(folder?.name, 'ShAre XT');
    expect(folder?.uri, 'content://tree/shared');
    expect(calls, <String>['folder']);
  });

  test('asks the picker and returns the chosen folder', () async {
    answer(
      (_) async => <String, Object?>{'name': 'Downloads', 'uri': 'content://t/2'},
    );

    final SxFolder? folder = await ChannelFolderStore(channel).pick();

    expect(folder?.name, 'Downloads');
    expect(calls, <String>['pickFolder']);
  });

  test('a cancelled picker changes nothing', () async {
    answer((_) async => null);

    expect(await ChannelFolderStore(channel).pick(), isNull);
  });

  test('lists folders first, then names, ignoring unnamed entries', () async {
    answer(
      (_) async => <Object?>[
        <String, Object?>{'name': 'note.txt', 'bytes': 12, 'isFolder': false},
        <String, Object?>{
          'name': 'Sawirro',
          'bytes': 0,
          'isFolder': true,
          'modifiedAt': 1,
        },
        <String, Object?>{'name': '', 'bytes': 1},
        <String, Object?>{'name': 'Audio.m4a', 'bytes': 99},
      ],
    );

    final List<StoredFile> files = await ChannelFolderStore(channel).list();

    expect(files.map((StoredFile f) => f.name), <String>[
      'Sawirro',
      'Audio.m4a',
      'note.txt',
    ]);
    expect(files.first.isFolder, isTrue);
    expect(files.first.modifiedAt, 1);
    expect(files.last.bytes, 12);
  });

  test('sortStoredFiles keeps its input untouched', () {
    const List<StoredFile> input = <StoredFile>[
      StoredFile(name: 'b.bin', bytes: 1, modifiedAt: 0),
      StoredFile(name: 'A.bin', bytes: 1, modifiedAt: 0),
    ];

    final List<StoredFile> sorted = sortStoredFiles(input);

    expect(sorted.map((StoredFile f) => f.name), <String>['A.bin', 'b.bin']);
    expect(input.first.name, 'b.bin');
  });

  test('a build without the channel reports no folder and no files', () async {
    final ChannelFolderStore store = ChannelFolderStore(channel);

    expect(await store.current(), isNull);
    expect(await store.list(), isEmpty);
    expect(await store.pick(), isNull);
    await store.forget();
  });
}
