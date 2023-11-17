import 'package:desktop_adb_file_browser/pages/browser.dart';
import 'package:flutter/material.dart';

class NewFileDialog extends StatefulWidget {
  final TextEditingController fileNameController;

  final ValueNotifier<FileCreation> fileCreation;
  const NewFileDialog(
      {super.key, required this.fileNameController, required this.fileCreation});

  @override
  State<NewFileDialog> createState() => _NewFileDialogState();
}

class _NewFileDialogState extends State<NewFileDialog> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: widget.fileNameController,
          autocorrect: false,
          autofocus: true,
          decoration: const InputDecoration(hintText: "New file"),
        ),
        Row(
          children: [
            _fileRadio(FileCreation.File),
            _fileRadio(FileCreation.Folder)
          ],
        )
      ],
    );
  }

  Row _fileRadio(FileCreation f) {
    return Row(
      children: [
        Text(f.name),
        Radio<FileCreation>(
            value: f,
            groupValue: widget.fileCreation.value,
            onChanged: ((value) {
              setState(() {
                widget.fileCreation.value = value ?? FileCreation.File;
              });
            })),
      ],
    );
  }
}
