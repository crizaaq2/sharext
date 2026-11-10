import 'package:flutter/material.dart';

import '../../design/components/ui_kit.dart';
import '../../design/tokens.dart';
import '../../l10n/generated/app_localizations.dart';
import 'folder_store.dart';

/// Opens the one-folder sheet used from the You tab.
Future<void> showFilesSheet(BuildContext context, {FolderStore? store}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) =>
        FilesSheet(store: store ?? ChannelFolderStore()),
  );
}

/// Shows the chosen folder and everything inside it, including files the owner
/// dropped there with a file manager.
class FilesSheet extends StatefulWidget {
  const FilesSheet({super.key, required this.store});

  final FolderStore store;

  @override
  State<FilesSheet> createState() => _FilesSheetState();
}

class _FilesSheetState extends State<FilesSheet> {
  SxFolder? _folder;
  List<StoredFile> _files = const <StoredFile>[];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final SxFolder? folder = await widget.store.current();
    final List<StoredFile> files = folder == null
        ? const <StoredFile>[]
        : await widget.store.list();
    if (!mounted) return;
    setState(() {
      _folder = folder;
      _files = files;
      _loading = false;
    });
  }

  Future<void> _choose() async {
    setState(() => _busy = true);
    final SxFolder? folder = await widget.store.pick();
    final List<StoredFile> files = folder == null
        ? const <StoredFile>[]
        : await widget.store.list();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _folder = folder;
      _files = files;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final SonarTokens tokens = SonarTokens.of(context);

    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (BuildContext context, ScrollController scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(SxSpace.x4),
          children: <Widget>[
            Text(
              l10n.folderTitle,
              style: SxType.title.copyWith(color: tokens.text),
            ),
            const SizedBox(height: SxSpace.x2),
            Text(
              _folder?.name ?? l10n.folderNotChosen,
              style: SxType.body.copyWith(color: tokens.secondaryText),
            ),
            const SizedBox(height: SxSpace.x3),
            Text(
              l10n.folderHint,
              style: SxType.caption.copyWith(color: tokens.secondaryText),
            ),
            const SizedBox(height: SxSpace.x4),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: _busy ? null : _choose,
                child: Text(l10n.folderChoose),
              ),
            ),
            const SizedBox(height: SxSpace.x4),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(SxSpace.x4),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_folder == null)
              SxRow(
                icon: Icons.folder_off_outlined,
                title: l10n.folderNotChosen,
                subtitle: l10n.folderHint,
              )
            else ...<Widget>[
              if (_files.isEmpty)
                SxRow(
                  icon: Icons.folder_open_outlined,
                  title: l10n.folderEmpty,
                )
              else ...<Widget>[
                Text(
                  l10n.folderCount(_files.length),
                  style: SxType.caption.copyWith(color: tokens.secondaryText),
                ),
                const SizedBox(height: SxSpace.x2),
                for (final StoredFile file in _files)
                  SxRow(
                    icon: file.isFolder
                        ? Icons.folder_outlined
                        : Icons.insert_drive_file_outlined,
                    title: file.name,
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
