import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

class FileFolderCard extends StatelessWidget {
  const FileFolderCard(
      {Key? key,
      required this.fileName,
      required this.isDirectory,
      required this.onClick})
      : super(key: key);

  final String fileName;
  final bool isDirectory;
  final VoidCallback onClick;

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
                fileName,
                textAlign: TextAlign.center,
              ),
            ),
            Wrap(
              clipBehavior: Clip.antiAlias,
              children: [
                isDirectory
                    ? const Icon(null)
                    : const Icon(Icons.download_rounded),
                const Icon(Icons.copy),
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

class FileFolderListTile extends StatelessWidget {
  const FileFolderListTile(
      {Key? key,
      required this.fileName,
      required this.isDirectory,
      required this.onClick})
      : super(key: key);

  final String fileName;
  final bool isDirectory;
  final VoidCallback onClick;

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
          isDirectory ? const Icon(null) : const Icon(Icons.download_rounded),
          const Icon(Icons.copy),
          const Icon(Icons.delete_forever),
        ],
      ),
      onTap: onClick,
      title: Text(fileName),
    );
  }
}
