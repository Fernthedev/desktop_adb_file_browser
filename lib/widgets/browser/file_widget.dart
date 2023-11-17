import 'package:desktop_adb_file_browser/widgets/browser/file_data.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

@immutable
class FileCardWidget extends StatefulWidget {
  static const double _iconSplashRadius = 20;

  final FileBrowserDataWrapper fileWrapper;

  final bool isCard;

  const FileCardWidget({
    super.key,
    required this.fileWrapper,
    required this.isCard,
  });

  @override
  State<FileCardWidget> createState() => _FileCardWidgetState();
}

class _FileCardWidgetState extends State<FileCardWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: widget.fileWrapper.navigateToDir,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Flexible(
              flex: 1,
              fit: FlexFit.loose,
              child: ListTile(
                title: Icon(
                  widget.fileWrapper.getIcon(),
                  size: 16 * 3.0,
                ),
                subtitle: Text(
                  widget.fileWrapper.friendlyFileName,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Wrap(
              clipBehavior: Clip.antiAlias,
              children: [
                widget.fileWrapper.fileData.isDirectory
                    ? const Icon(null)
                    : IconButton(
                        icon: const Icon(Icons.download_rounded),
                        onPressed: widget.fileWrapper.saveFileToDesktop,
                      ),
                widget.fileWrapper.fileData.isDirectory
                    ? const Icon(
                        null, // 16 + iconSize
                      )
                    : IconButton(
                        icon:
                            const Icon(FluentIcons.glasses_24_filled, size: 24),
                        onPressed: widget.fileWrapper.watchFile,
                        splashRadius: FileCardWidget._iconSplashRadius,
                        tooltip: "Watch",
                      ),
                widget.fileWrapper.fileData.isDirectory
                    ? const Icon(null)
                    : IconButton(
                        icon: const Icon(FluentIcons.open_24_filled, size: 24),
                        onPressed: widget.fileWrapper.openTempFile,
                        splashRadius: FileCardWidget._iconSplashRadius,
                        tooltip: "Open (temp)",
                      ),
                IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: widget.fileWrapper.copyPathToClipboard),
                IconButton(
                  icon: const Icon(Icons.delete_forever),
                  onPressed: () => widget.fileWrapper.removeFileDialog(context),
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
}
