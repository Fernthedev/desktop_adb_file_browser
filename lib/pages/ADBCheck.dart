import 'package:desktop_adb_file_browser/utils/adb.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';

class ADBCheck extends StatefulWidget {
  const ADBCheck({Key? key, required this.redirectPage}) : super(key: key);

  final String redirectPage;

  @override
  State<ADBCheck> createState() => _ADBCheckState();
}

class _ADBCheckState extends State<ADBCheck> {
  @override
  void initState() {
    super.initState();
    _showADBDownload(context);
  }

  Future<void> _showADBDownload(BuildContext context) async {
    try {
      await Adb.runAdbCommand(null, ["start-server"]);
    } catch (e) {
      await showDialog(
          builder: (context) => const ADBDownloadDialog(), context: context);
    }
    if (!mounted) return;
    Routemaster.of(context).replace(widget.redirectPage);
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
    Key? key,
  }) : super(key: key);

  @override
  State<ADBDownloadDialog> createState() => _ADBDownloadDialogState();
}

class _ADBDownloadDialogState extends State<ADBDownloadDialog> {
  int? current;
  int? total;
  CancelToken cancelToken = CancelToken();

  @override
  Widget build(BuildContext context) {
    if (current == null || total == null) return _initialDownloadDialog();

    return AlertDialog(
        title: const Text("Downloading ADB"),
        content: LinearProgressIndicator(
          value: current!.toDouble() / total!.toDouble(),
        ));
  }

  Widget _initialDownloadDialog() {
    return AlertDialog(
      title: const Text("ADB not found"),
      content: const Text("Do you want to download ABD?"),
      actions: [
        TextButton(
            onPressed: () async {
              await Adb.downloadADB((c, t) {
                setState(() {
                  current = c;
                  total = t;
                });
              }, cancelToken);

              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Ok"))
      ],
    );
  }
}
