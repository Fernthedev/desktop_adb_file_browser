import 'package:clipboard/clipboard.dart';
import 'package:desktop_adb_file_browser/utils/adb.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef DownloadFileCallback = Future<void> Function(
    String source, String fileName);

typedef RenameFileCallback = Future<void> Function(
    String source, String newName);

abstract class FileWidgetUI extends StatelessWidget {
  final String friendlyFileName;
  final String fullFilePath;
  final bool isDirectory;
  final VoidCallback onClick;
  final DownloadFileCallback downloadFile;
  final RenameFileCallback renameFileCallback;

  const FileWidgetUI(
      {Key? key,
      required this.friendlyFileName,
      required this.fullFilePath,
      required this.isDirectory,
      required this.onClick,
      required this.downloadFile,
      required this.renameFileCallback})
      : super(key: key);

  Future<void> copyPathToClipboard() {
    return FlutterClipboard.copy(fullFilePath);
  }

  Future<void> saveToDesktop() {
    return downloadFile(fullFilePath, friendlyFileName);
  }

  Future<void> renameFile(String newName) {
    return renameFileCallback(fullFilePath, newName);
  }

  String? validateNewName(String? newName) {
    if (newName == null || newName.isEmpty) {
      return "New name cannot be empty";
    }

    if (newName.contains("/")) return "Cannot contain slashes";

    return null;
  }
}

class FileFolderCard extends FileWidgetUI {
  const FileFolderCard(
      {Key? key,
      required String friendlyFileName,
      required String fullFilePath,
      required bool isDirectory,
      required VoidCallback onClick,
      required DownloadFileCallback downloadFile,
      required RenameFileCallback renameFileCallback})
      : super(
            key: key,
            friendlyFileName: friendlyFileName,
            fullFilePath: fullFilePath,
            isDirectory: isDirectory,
            onClick: onClick,
            downloadFile: downloadFile,
            renameFileCallback: renameFileCallback);

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
  static const double _iconSplashRadius = 20;

  final FocusNode _focusNode = FocusNode();

  FileFolderListTile(
      {Key? key,
      required String friendlyFileName,
      required String fullFilePath,
      required bool isDirectory,
      required VoidCallback onClick,
      required DownloadFileCallback downloadFile,
      required RenameFileCallback renameFileCallback})
      : super(
            key: key,
            friendlyFileName: friendlyFileName,
            fullFilePath: fullFilePath,
            isDirectory: isDirectory,
            onClick: onClick,
            downloadFile: downloadFile,
            renameFileCallback: renameFileCallback);

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
          IconButton(
              splashRadius: _iconSplashRadius,
              onPressed: () {
                _focusNode.requestFocus();
              },
              icon: const Icon(Icons.edit)),
          const Icon(Icons.delete_forever),
        ],
      ),
      onTap: onClick,
      title: AbsorbPointer(
        
        child: TextFormField(
          maxLines: 1,
          enableSuggestions: false,
          maxLengthEnforcement: MaxLengthEnforcement.truncateAfterCompositionEnds,
          decoration: const InputDecoration(
            // cool animation border effect
            // this makes it rectangular when not selected
            enabledBorder: InputBorder.none,
            focusedBorder: UnderlineInputBorder(),
            border: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            fillColor: null,
            filled: false,
          ),
          focusNode: _focusNode,
          initialValue: friendlyFileName,
          validator: validateNewName,
          onFieldSubmitted: renameFile,
        ),
      ),
      // Row(
      //   children: [
      //     Flexible(
      //       fit: FlexFit.loose,
      //       child: SizedBox(
      //         width: 500,
      //         child:
      //       ),
      //     ),
      //   ],
      // ),
    );
  }
}
