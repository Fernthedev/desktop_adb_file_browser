import 'package:desktop_adb_file_browser/riverpod/file_browser.dart';
import 'package:desktop_adb_file_browser/utils/adb.dart';
import 'package:desktop_adb_file_browser/widgets/browser/file_data.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class FileCardWidget extends ConsumerStatefulWidget {
  static const double _iconSplashRadius = 20;

  final FileListingData fileData;
  final void Function() onWatch;

  final bool isCard;

  const FileCardWidget({
    super.key,
    required this.fileData,
    required this.isCard,
    required this.onWatch,
  });

  @override
  ConsumerState<FileCardWidget> createState() => _FileCardWidgetState();
}

class _FileCardWidgetState extends ConsumerState<FileCardWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          final fileBrowser = ref.read(fileBrowserProvider.notifier);
          fileBrowser.navigateToDirectory(widget.fileData.path);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Flexible(
              flex: 1,
              fit: FlexFit.loose,
              child: ListTile(
                title: Icon(
                  widget.fileData.getIcon(),
                  size: 16 * 3.0,
                ),
                subtitle: Text(
                  widget.fileData.friendlyFileName,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Wrap(
              clipBehavior: Clip.antiAlias,
              children: [
                widget.fileData.isDirectory
                    ? const Icon(
                        null, // 16 + iconSize
                      )
                    : IconButton(
                        icon:
                            const Icon(FluentIcons.glasses_24_filled, size: 24),
                        onPressed: () => widget.onWatch(),
                        splashRadius: FileCardWidget._iconSplashRadius,
                        tooltip: "Watch",
                      ),
                widget.fileData.isDirectory
                    ? const Icon(null)
                    : IconButton(
                        icon: const Icon(FluentIcons.open_24_filled, size: 24),
                        onPressed: () => widget.fileData.openTempFile(ref),
                        splashRadius: FileCardWidget._iconSplashRadius,
                        tooltip: "Open (temp)",
                      ),
                IconButton(
                  icon: const Icon(Icons.download_rounded),
                  onPressed: () => widget.fileData.saveFileToDesktop(ref),
                ),
                IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: widget.fileData.copyPathToClipboard),
                IconButton(
                  icon: const Icon(Icons.delete_forever),
                  onPressed: () => widget.fileData.removeFileDialog(context),
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
