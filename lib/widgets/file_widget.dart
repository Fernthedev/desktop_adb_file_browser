import 'package:clipboard/clipboard.dart';
import 'package:desktop_adb_file_browser/utils/adb.dart';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef DownloadFileCallback = Future<void> Function(
    String source, String fileName);

typedef RenameFileCallback = Future<void> Function(
    String source, String newName);

class FileWidgetUI extends StatefulWidget {
  static const double _iconSplashRadius = 20;

  final String fullFilePath;
  final bool isDirectory;
  final VoidCallback onClick;
  final DownloadFileCallback downloadFile;
  final RenameFileCallback renameFileCallback;

  final bool isCard;

  const FileWidgetUI(
      {Key? key,
      required this.fullFilePath,
      required this.isDirectory,
      required this.onClick,
      required this.downloadFile,
      required this.renameFileCallback,
      required this.isCard})
      : super(key: key);

  @override
  State<FileWidgetUI> createState() => _FileWidgetUIState();
}

class _FileWidgetUIState extends State<FileWidgetUI> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fileNameController;
  final FocusNode _focusNode = FocusNode();

  String get friendlyFileName => Adb.adbPathContext.basename(fullFilePath);
  late String fullFilePath;
  bool editable = false;

  @override
  void initState() {
    super.initState();
    fullFilePath = widget.fullFilePath;
    _fileNameController = TextEditingController(text: friendlyFileName);
  }

  @override
  void dispose() {
    super.dispose();
    _fileNameController.dispose();
  }

  Future<void> copyPathToClipboard() {
    return FlutterClipboard.copy(widget.fullFilePath);
  }

  Future<void> saveToDesktop() {
    return widget.downloadFile(widget.fullFilePath, friendlyFileName);
  }

  Future<void> renameFile() {
    var newName = _fileNameController.text;
    var future = widget.renameFileCallback(fullFilePath, newName);

    // TODO: unspaghetify
    if (newName != friendlyFileName) {
      setState(() {
        fullFilePath = Adb.adbPathContext
            .join(Adb.adbPathContext.dirname(fullFilePath), newName);
      });
    }

    return future;
  }

  String? validateNewName(String? newName) {
    if (newName == null || newName.isEmpty) {
      return "New name cannot be empty";
    }

    if (newName.contains("/")) return "Cannot contain slashes";

    return null;
  }

  void _enterEditMode() {
    setState(() {
      editable = true;
      _focusNode.requestFocus();
    });
  }

  void _exitEditMode() {
    setState(() {
      editable = false;
      _focusNode.unfocus();
      _formKey.currentState?.save();
    });
  }

  Widget _buildListTile(BuildContext context) {
    return ListTile(
        leading: Icon(
          widget.isDirectory
              ? Icons.folder
              : FluentIcons.document_48_regular, // document
        ),
        trailing: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            widget.isDirectory
                ? const Icon(null)
                : IconButton(
                    icon: const Icon(Icons.download_rounded),
                    onPressed: saveToDesktop,
                    splashRadius: FileWidgetUI._iconSplashRadius,
                  ),
            IconButton(
              // TODO: Add user feedback when this occurs
              icon: const Icon(Icons.copy),
              onPressed: copyPathToClipboard,
              splashRadius: FileWidgetUI._iconSplashRadius,
              tooltip: "Copy to clipboard",
            ),
            IconButton(
                splashRadius: FileWidgetUI._iconSplashRadius,
                onPressed: !editable ? _enterEditMode : _exitEditMode,
                icon: Icon(editable ? Icons.check : Icons.edit)),
            const Icon(Icons.delete_forever),
          ],
        ),
        onLongPress: _enterEditMode,
        onTap: widget.onClick,
        title: editable ? _fileNameForm() : Text(friendlyFileName)
        // title: editable
        //     ? ValidatableTextField(
        //         focusNode: _focusNode,
        //         initialValue: friendlyFileName,
        //         onSubmit: renameFile,
        //         fieldValidator: validateNewName,
        //       )
        //     : Text(friendlyFileName),
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


  //  TODO: Fix submit not working on pressing enter
  // I hate this
  Form _fileNameForm() {
    return Form(
      key: _formKey,
      child: TextFormField(
        controller: _fileNameController,
        validator: validateNewName,
        onSaved: (s) => renameFile(),
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

  Widget _buildCard(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: widget.onClick,
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
                widget.isDirectory
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
    return widget.isDirectory ? Icons.folder : FluentIcons.document_48_regular;
  }

  @override
  Widget build(BuildContext context) {
    return widget.isCard ? _buildCard(context) : _buildListTile(context);
  }
}

// TODO:: Remove or move
class ValidatableTextField extends StatefulWidget {
  const ValidatableTextField(
      {Key? key,
      required this.initialValue,
      this.fieldValidator,
      this.onSubmit,
      required this.focusNode})
      : super(key: key);

  final FocusNode focusNode;
  final String initialValue;
  final FormFieldValidator<String>? fieldValidator;
  final ValueChanged<String>? onSubmit;

  @override
  State<ValidatableTextField> createState() => ValidatableTextFieldState();
}

class ValidatableTextFieldState extends State<ValidatableTextField> {
  late final TextEditingController _editingController;

  @override
  void initState() {
    super.initState();
    _editingController = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    super.dispose();
    _editingController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _editingController,
      onChanged: (s) {
        setState(() {});
      },
      onSubmitted: (s) {
        debugPrint("submit");
        widget.onSubmit!(s);
      },
      focusNode: widget.focusNode,
      decoration: InputDecoration(
        errorText: widget.fieldValidator != null
            ? widget.fieldValidator!(_editingController.text)
            : null,
        floatingLabelBehavior: FloatingLabelBehavior.never,
        focusedErrorBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: const UnderlineInputBorder(),
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
    );
  }
}
