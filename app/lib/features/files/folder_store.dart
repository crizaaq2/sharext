import 'package:flutter/services.dart';

/// The one folder ShAre XT keeps on the phone.
///
/// The owner chooses it with the system folder picker and the app keeps read and
/// write access to it, including files the owner puts there with a file manager.
/// Everything ShAre XT saves goes into this single folder, never into a tree of
/// per-sender directories.
class SxFolder {
  const SxFolder({required this.name, required this.uri});

  static SxFolder? fromMap(Object? result) {
    if (result is! Map) return null;
    final String? name = result['name'] as String?;
    final String? uri = result['uri'] as String?;
    if (name == null || name.isEmpty || uri == null || uri.isEmpty) return null;
    return SxFolder(name: name, uri: uri);
  }

  /// The folder's display name, e.g. `ShAre XT`.
  final String name;

  /// The document tree URI the grant belongs to.
  final String uri;
}

/// One entry inside [SxFolder]. A folder is listed too, so the sheet never hides
/// something the owner put there.
class StoredFile {
  const StoredFile({
    required this.name,
    required this.bytes,
    required this.modifiedAt,
    this.isFolder = false,
  });

  factory StoredFile.fromMap(Map<Object?, Object?> map) => StoredFile(
    name: map['name'] as String? ?? '',
    bytes: map['bytes'] as int? ?? -1,
    modifiedAt: map['modifiedAt'] as int? ?? 0,
    isFolder: map['isFolder'] as bool? ?? false,
  );

  final String name;

  /// Size in bytes, or -1 when the provider does not report one.
  final int bytes;

  /// Milliseconds since the epoch, or 0 when unknown.
  final int modifiedAt;

  final bool isFolder;
}

/// Folders first, then names in the user's collation order.
List<StoredFile> sortStoredFiles(Iterable<StoredFile> files) {
  final List<StoredFile> sorted = files
      .where((StoredFile f) => f.name.isNotEmpty)
      .toList();
  sorted.sort((StoredFile a, StoredFile b) {
    if (a.isFolder != b.isFolder) return a.isFolder ? -1 : 1;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return List<StoredFile>.unmodifiable(sorted);
}

/// The folder operations the UI needs.
abstract class FolderStore {
  /// The folder chosen before, or null when there is none (yet).
  Future<SxFolder?> current();

  /// Opens the system picker. Returns the new folder, or null if cancelled.
  Future<SxFolder?> pick();

  /// Everything inside the folder, folders first.
  Future<List<StoredFile>> list();

  /// Drops the saved folder and its grant.
  Future<void> forget();
}

/// [FolderStore] over the Android `sharext/storage` channel.
///
/// Desktop targets have no picker yet, so a missing plugin resolves to "no
/// folder" instead of an exception: the Windows build stays honest and usable.
class ChannelFolderStore implements FolderStore {
  ChannelFolderStore([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel('sharext/storage');

  final MethodChannel _channel;

  @override
  Future<SxFolder?> current() async => SxFolder.fromMap(await _call('folder'));

  @override
  Future<SxFolder?> pick() async => SxFolder.fromMap(await _call('pickFolder'));

  @override
  Future<List<StoredFile>> list() async {
    final Object? result = await _call('list');
    if (result is! List) return const <StoredFile>[];
    return sortStoredFiles(
      result
          .whereType<Map<Object?, Object?>>()
          .map(StoredFile.fromMap)
          .toList(growable: false),
    );
  }

  @override
  Future<void> forget() async => _call('forgetFolder');

  Future<Object?> _call(String method) async {
    try {
      return await _channel.invokeMethod<Object?>(method);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
