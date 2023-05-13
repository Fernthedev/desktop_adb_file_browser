import 'package:desktop_adb_file_browser/widgets/browser/file_data.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

@immutable
class FileCardWidget extends StatefulWidget {
  static const double _iconSplashRadius = 20;

  final FileBrowserData fileData;

  final bool isCard;

  const FileCardWidget({
    Key? key,
    required this.fileData,
    required this.isCard,
  }) : super(key: key);

  @override
  State<FileCardWidget> createState() => _FileCardWidgetState();
}

class _FileCardWidgetState extends State<FileCardWidget> with FileDataState {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: navigateToDir,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Flexible(
              flex: 1,
              fit: FlexFit.loose,
              child: ListTile(
                title: Icon(
                  getIcon(),
                  size: 16 * 3.0,
                ),
                subtitle: Text(
                  friendlyFileName,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Wrap(
              clipBehavior: Clip.antiAlias,
              children: [
                fileData.isDirectory
                    ? const Icon(null)
                    : IconButton(
                        icon: const Icon(Icons.download_rounded),
                        onPressed: saveFileToDesktop,
                      ),
                fileData.isDirectory
                    ? const Icon(
                        null, // 16 + iconSize
                      )
                    : IconButton(
                        icon:
                            const Icon(FluentIcons.glasses_24_filled, size: 24),
                        onPressed: watchFile,
                        splashRadius: FileCardWidget._iconSplashRadius,
                        tooltip: "Watch",
                      ),
                fileData.isDirectory
                    ? const Icon(null)
                    : IconButton(
                        icon: const Icon(FluentIcons.open_24_filled, size: 24),
                        onPressed: openTempFile,
                        splashRadius: FileCardWidget._iconSplashRadius,
                        tooltip: "Open (temp)",
                      ),
                IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: copyPathToClipboard),
                IconButton(
                  icon: const Icon(Icons.delete_forever),
                  onPressed: () => removeFileDialog(context),
                  splashRadius: FileCardWidget._iconSplashRadius,
                  tooltip: "Delete",
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  FileBrowserData get fileData => widget.fileData;
}
