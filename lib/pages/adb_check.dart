import 'package:desktop_adb_file_browser/utils/adb.dart';
import 'package:dio/dio.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:trace/trace.dart';

class ADBCheck extends StatefulWidget {
  const ADBCheck({super.key, required this.redirectPage});

  final String redirectPage;

  @override
  State<ADBCheck> createState() => _ADBCheckState();
}

class _ADBCheckState extends State<ADBCheck> {
  @override
  void initState() {
    super.initState();
    checkAndPromptADB(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class ADBDownloadDialog extends StatefulWidget {
  const ADBDownloadDialog({
    super.key,
  });

  @override
  State<ADBDownloadDialog> createState() => _ADBDownloadDialogState();
}

class _ADBDownloadDialogState extends State<ADBDownloadDialog> {
  int? current;
  int? total;
  CancelToken cancelToken = CancelToken();
  Exception? _error;

  @override
  Widget build(BuildContext context) {
    if (current == null || total == null) return _promptDownloadState();
    if (_error != null) return _errorState();

    return _loadingState();
  }

  AlertDialog _loadingState() {
    return AlertDialog(
      title: const Text("Downloading ADB"),
      content: LinearProgressIndicator(
        value: current!.toDouble() / total!.toDouble(),
      ),
    );
  }

  Widget _promptDownloadState() {
    return AlertDialog(
      title: const Text("ADB not found"),
      content: const Text("Do you want to download ADB?"),
      actions: [
        FilledButton(
          autofocus: true,
          onPressed: _download,
          child: const Text("Ok"),
        )
      ],
    );
  }

  Widget _errorState() {
    String messages = "Do you wish to continue anyways?";

    if (_error != null) {
      messages += "\nMessage: $_error";
    }

    return AlertDialog(
      icon: const Icon(FluentIcons.error_circle_48_regular),
      title: const Text("Suffered error downloading"),
      content: Text(messages),
      actions: [
        FilledButton(
          autofocus: true,
          onPressed: _continue,
          child: const Text("Continue anyways"),
        )
      ],
    );
  }

  void _download() async {
    try {
      await Adb.downloadADB((c, t) {
        setState(() {
          current = c;
          total = t;
        });
      }, cancelToken);

      if (!mounted) return;
      _continue();
    } catch (e) {
      // ignore: avoid_print
      Trace.info("Suffered error while downloading!\n$e");
      if (e is Exception) {
        setState(() {
          _error = e;
        });
      }
    }
  }

  void _continue() {
    Navigator.of(context).pop();
  }
}

Future<void> checkAndPromptADB(BuildContext context) async {
  try {
    await Adb.runAdbCommand(null, ["start-server"]);
  } catch (e) {
    if (!context.mounted) {
      return;
    }

    await showDialog(
      builder: (context) => const ADBDownloadDialog(),
      context: context,
      barrierDismissible: false,
    );
  }
}
