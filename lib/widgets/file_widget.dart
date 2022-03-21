import 'package:clipboard/clipboard.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

typedef DownloadFileCallback = Future<void> Function(
    String source, String fileName);

abstract class FileWidgetUI extends StatelessWidget {
  final String friendlyFileName;
  final String fullFilePath;
  final bool isDirectory;
  final VoidCallback onClick;
  final DownloadFileCallback downloadFile;

  const FileWidgetUI(
      {Key? key,
      required this.friendlyFileName,
      required this.fullFilePath,
      required this.isDirectory,
      required this.onClick,
      required this.downloadFile})
      : super(key: key);

  Future<void> copyPathToClipboard() {
    return FlutterClipboard.copy(fullFilePath);
  }

  Future<void> saveToDesktop() {
    return downloadFile(fullFilePath, friendlyFileName);
  }
}

class FileFolderCard extends FileWidgetUI {
  const FileFolderCard(
      {Key? key,
      required String friendlyFileName,
      required String fullFilePath,
      required bool isDirectory,
      required VoidCallback onClick,
      required DownloadFileCallback downloadFile})
      : super(
            key: key,
            friendlyFileName: friendlyFileName,
            fullFilePath: fullFilePath,
            isDirectory: isDirectory,
            onClick: onClick,
            downloadFile: downloadFile);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onClick,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            ListTile(
              title: Icon(
                _getIcon(),
                size: 24 * 3.0,
              ),
              subtitle: Text(
                friendlyFileName,
                textAlign: TextAlign.center,
              ),
            ),
            Wrap(
              clipBehavior: Clip.antiAlias,
              children: [
                isDirectory
                    ? const Icon(null)
                    : IconButton(
                        icon: const Icon(Icons.download_rounded),
                        onPressed: saveToDesktop,
                      ),
                IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: copyPathToClipboard),
                const Icon(Icons.delete_forever),
              ],
            )
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    return isDirectory ? Icons.folder : FluentIcons.document_48_regular;
  }
}

class FileFolderListTile extends FileWidgetUI {
  const FileFolderListTile(
      {Key? key,
      required String friendlyFileName,
      required String fullFilePath,
      required bool isDirectory,
      required VoidCallback onClick,
      required DownloadFileCallback downloadFile})
      : super(
            key: key,
            friendlyFileName: friendlyFileName,
            fullFilePath: fullFilePath,
            isDirectory: isDirectory,
            onClick: onClick,
            downloadFile: downloadFile);

  static const double _iconSplashRadius = 20;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        isDirectory
            ? Icons.folder
            : FluentIcons.document_48_regular, // document
      ),
      trailing: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          isDirectory
              ? const Icon(null)
              : IconButton(
                  icon: const Icon(Icons.download_rounded),
                  onPressed: saveToDesktop,
                  splashRadius: _iconSplashRadius,
                ),
          IconButton(
            // TODO: Add user feedback when this occurs
            icon: const Icon(Icons.copy),
            onPressed: copyPathToClipboard,
            splashRadius: _iconSplashRadius,
            tooltip: "Copy to clipboard",
          ),
          const Icon(Icons.delete_forever),
        ],
      ),
      onTap: onClick,
      title: Text(friendlyFileName),
    );
  }
}
