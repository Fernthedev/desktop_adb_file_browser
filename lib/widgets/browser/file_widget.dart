import 'dart:math';

import 'package:clipboard/clipboard.dart';
import 'package:desktop_adb_file_browser/utils/adb.dart';
import 'package:filesize/filesize.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef DeleteCallback = Future<void> Function(String source, bool file);

typedef DownloadFileCallback = Future<void> Function(
    String source, String fileName);
typedef RenameFileCallback = Future<void> Function(
    String source, String newName);

@immutable
class FileWidgetUI extends StatefulWidget {
  static const double _iconSplashRadius = 20;

  final Future<DateTime?> modifiedTime;
  final Future<int?> fileSize;
  final String fullFilePath;
  final bool isDirectory;
  final VoidCallback onClick;
  final DownloadFileCallback onWatch;
  final DeleteCallback onDelete;
  final DownloadFileCallback downloadFile;
  final RenameFileCallback renameFileCallback;
  final DownloadFileCallback openTempFile;

  final bool isCard;

  const FileWidgetUI(
      {Key? key,
      required this.fullFilePath,
      required this.isDirectory,
      required this.onClick,
      required this.downloadFile,
      required this.renameFileCallback,
      required this.isCard,
      required this.modifiedTime,
      required this.fileSize,
      required this.onDelete,
      required this.onWatch,
      required this.openTempFile})
      : super(key: key);

  @override
  State<FileWidgetUI> createState() => _FileWidgetUIState();
}

class _FileWidgetUIState extends State<FileWidgetUI> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fileNameController;
  final FocusNode _focusNode = FocusNode();

  late String fullFilePath;
  bool editable = false;
  String get friendlyFileName => Adb.adbPathContext.basename(fullFilePath);

  @override
  Widget build(BuildContext context) {
    return widget.isCard ? _buildCard(context) : _buildListTile(context);
  }

  @override
  void dispose() {
    super.dispose();
    _fileNameController.dispose();
    _focusNode.dispose();
  }

  @override
  void initState() {
    super.initState();
    fullFilePath = widget.fullFilePath;
    _fileNameController = TextEditingController(text: friendlyFileName);
    // Exit rename mode when clicked away/unfocused
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) _exitEditMode(save: true);
    });
  }

  Widget _buildCard(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: widget.onClick,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Flexible(
              flex: 1,
              fit: FlexFit.loose,
              child: ListTile(
                title: Icon(
                  _getIcon(),
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
                widget.isDirectory
                    ? const Icon(null)
                    : IconButton(
                        icon: const Icon(Icons.download_rounded),
                        onPressed: _saveToDesktop,
                      ),
                widget.isDirectory
                    ? const Icon(
                        null, // 16 + iconSize
                      )
                    : IconButton(
                        icon:
                            const Icon(FluentIcons.glasses_24_filled, size: 24),
                        onPressed: _watchFile,
                        splashRadius: FileWidgetUI._iconSplashRadius,
                        tooltip: "Watch",
                      ),
                widget.isDirectory
                    ? const Icon(null)
                    : IconButton(
                        icon: const Icon(FluentIcons.open_24_filled, size: 24),
                        onPressed: _openTempFile,
                        splashRadius: FileWidgetUI._iconSplashRadius,
                        tooltip: "Open (temp)",
                      ),
                IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: _copyPathToClipboard),
                IconButton(
                  icon: const Icon(Icons.delete_forever),
                  onPressed: _deleteSelf,
                  splashRadius: FileWidgetUI._iconSplashRadius,
                  tooltip: "Delete",
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(BuildContext context) {
    return ListTile(
        leading: Icon(
            widget.isDirectory
                ? Icons.folder
                : FluentIcons.document_24_regular, // document
            size: 24),
        trailing: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            _dateTime(),
            ..._column(child: _fileSizeText()),

            // icons

            widget.isDirectory
                ? const SizedBox(
                    width: 16 + 24, // 16 + iconSize
                  )
                : IconButton(
                    icon: const Icon(Icons.download_rounded, size: 24),
                    onPressed: _saveToDesktop,
                    enableFeedback: false,
                    splashRadius: FileWidgetUI._iconSplashRadius,
                  ),
            widget.isDirectory
                ? const SizedBox(
                    width: 16 + 24, // 16 + iconSize
                  )
                : IconButton(
                    icon: const Icon(FluentIcons.glasses_24_filled, size: 24),
                    onPressed: _watchFile,
                    splashRadius: FileWidgetUI._iconSplashRadius,
                    tooltip: "Watch",
                  ),
            widget.isDirectory
                ? const SizedBox(
                    width: 16 + 24, // 16 + iconSize
                  )
                : IconButton(
                    icon: const Icon(FluentIcons.open_24_filled, size: 24),
                    onPressed: _openTempFile,
                    splashRadius: FileWidgetUI._iconSplashRadius,
                    tooltip: "Open (temp)",
                  ),
            IconButton(
              // TODO: Add user feedback when this occurs
              icon: const Icon(Icons.copy),
              onPressed: _copyPathToClipboard,
              splashRadius: FileWidgetUI._iconSplashRadius,
              tooltip: "Copy to clipboard",
            ),

            IconButton(
                splashRadius: FileWidgetUI._iconSplashRadius,
                onPressed: !editable ? _enterEditMode : _exitEditMode,
                icon: Icon(editable ? Icons.check : Icons.edit)),
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: _deleteSelf,
              splashRadius: FileWidgetUI._iconSplashRadius,
              tooltip: "Delete",
            ),
          ],
        ),
        onLongPress: _enterEditMode,
        onTap: widget.onClick,
        title: editable ? _fileNameForm() : Text(friendlyFileName));
  }

  List<Widget> _column({required Widget child}) {
    return [
      child,
      Container(
        width: 2,
        color: Theme.of(context).colorScheme.inverseSurface,
      )
    ];
  }

  Future<void> _copyPathToClipboard() {
    return FlutterClipboard.copy(widget.fullFilePath);
  }

  Padding _dateTime() {
    // date time
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: FutureBuilder<DateTime?>(
          future: widget.modifiedTime,
          builder: ((context, snapshot) {
            String text = snapshot.error?.toString() ?? "...";

            var date = snapshot.data?.toLocal();
            if (date != null) {
              var year = date.year;
              var day = date.day.toString().padLeft(2, '0');
              var month = date.month.toString().padLeft(2, '0');
              var hour = max(date.hour % 12, 1).toString().padLeft(2, '0');
              var minute = date.minute.toString().padLeft(2, '0');
              var second = date.second.toString().padLeft(2, '0');
              text = "$year-$month-$day $hour:$minute:$second";
            }

            return Text(
              text,
              style: Theme.of(context).textTheme.subtitle2,
            );
          })),
    );
  }

  Future<void> _deleteSelf() {
    return widget.onDelete(widget.fullFilePath, !widget.isDirectory);
  }

  void _enterEditMode() {
    setState(() {
      editable = true;
      _focusNode.requestFocus();
    });
  }

  void _exitEditMode({bool save = true}) {
    setState(() {
      editable = false;
      _focusNode.unfocus();
      if (save) {
        _formKey.currentState?.save();
      }
    });
  }

  // I hate this
  Form _fileNameForm() {
    return Form(
      key: _formKey,
      child: TextFormField(
        controller: _fileNameController,
        validator: _validateNewName,
        onEditingComplete: () {
          _renameFile();
          _exitEditMode(save: false);
        },
        // onSaved: (s) => _renameFile(),
        focusNode: _focusNode,
        decoration: const InputDecoration(
          floatingLabelBehavior: FloatingLabelBehavior.never,
          focusedErrorBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: UnderlineInputBorder(),
          border: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          fillColor: null,
          filled: false,
        ),
        enabled: true,
        autofocus: false,
        maxLines: 1,
        autocorrect: false,
        enableSuggestions: false,
        maxLengthEnforcement: MaxLengthEnforcement.truncateAfterCompositionEnds,
      ),
    );
  }

  Padding _fileSizeText() {
    // date time
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: FutureBuilder<int?>(
          future: widget.fileSize,
          builder: ((context, snapshot) => Text(
                snapshot.error?.toString() ??
                    (snapshot.data != null ? filesize(snapshot.data) : "..."),
                style: Theme.of(context).textTheme.subtitle2,
                textAlign: TextAlign.left,
              ))),
    );
  }

  IconData _getIcon() {
    return widget.isDirectory ? Icons.folder : FluentIcons.document_48_regular;
  }

  Future<void> _openTempFile() async {
    return widget.openTempFile(widget.fullFilePath, friendlyFileName);
  }

  Future<void> _renameFile() async {
    var newName = _fileNameController.text;
    var future = widget.renameFileCallback(fullFilePath, newName);

    // TODO: unspaghetify
    if (newName != friendlyFileName) {
      setState(() {
        fullFilePath = Adb.adbPathContext
            .join(Adb.adbPathContext.dirname(fullFilePath), newName);
      });
    }
    await future;
  }

  Future<void> _saveToDesktop() {
    return widget.downloadFile(widget.fullFilePath, friendlyFileName);
  }

  String? _validateNewName(String? newName) {
    if (newName == null || newName.isEmpty) {
      return "New name cannot be empty";
    }

    if (newName.contains("/")) return "Cannot contain slashes";

    return null;
  }

  Future<void> _watchFile() async {
    return widget.onWatch(widget.fullFilePath, friendlyFileName);
  }
}
