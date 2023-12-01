import 'dart:async';
import 'dart:io';

import 'package:desktop_adb_file_browser/utils/adb.dart';
import 'package:desktop_adb_file_browser/utils/platform.dart';
import 'package:file_selector/file_selector.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';
import 'package:trace/trace.dart';

import '../utils/scroll.dart';

class LogPage extends StatefulWidget {
  LogPage({super.key, required String serial}) : logFuture = Adb.logcat(serial);

  final Future<Stream<String>> logFuture;
  final scrollController = AdjustableScrollController();

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  final List<String> logs = [];
  bool showLogs = false;
  StreamSubscription<String>? _streamSubscription;

  // Since Dart can't keep up fast enough with logcat when spammed,
  // we queue the save for when the stream slows down
  // which we assume is no longer spam
  bool waitForSave = false;
  DateTime lastStreamSend = DateTime.now();

  @override
  void initState() {
    super.initState();
    widget.logFuture.then((stream) {
      try {
        _streamSubscription = stream.listen((event) {
          setState(() {
            var newLogs = event
                .split(PlatformUtils.platformFileEnding)
                .where((element) => element.trim().isNotEmpty);
            logs.addAll(newLogs);

            if (waitForSave) {
              var timeSinceSend = DateTime.now().difference(lastStreamSend);
              if (timeSinceSend.inMilliseconds > 30) {
                _saveLog();
                waitForSave = false;
              }
            }

            lastStreamSend = DateTime.now();
          });
        });
        _streamSubscription?.onError((e) {
          Trace.verbose(e);
          _showError(e);
        });
        _streamSubscription?.onDone(() {
          Trace.verbose("Done");
        });
      } catch (e) {
        Trace.verbose(e.toString());
        _showError(e.toString());
      }
    }).onError((error, stackTrace) {
      Trace.verbose("Error $error");
      Trace.verbose(stackTrace.toString());
      _showError(error.toString());
    });
  }

  @override
  void dispose() {
    super.dispose();
    _streamSubscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Logcat"),
        leading: IconButton(
          icon: const Icon(
            FluentIcons.arrow_left_24_filled,
            size: 24,
          ),
          onPressed: () {
            Routemaster.of(context).history.back();
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
                onPressed: _queueSave,
                icon: const Icon(
                  FluentIcons.save_28_regular,
                  size: 28,
                )),
          ),
          Padding(
              padding: const EdgeInsets.all(8.0),
              child: Switch(
                  value: showLogs,
                  onChanged: (v) => setState(() {
                        showLogs = v;
                      })))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Visibility(
          visible: showLogs,
          replacement: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
                Text("Reading from logcat")
              ],
            ),
          ),
          child: Container(
            color: Theme.of(context).colorScheme.background,
            child: buildList(),
          ),
        ),
      ),
    );
  }

  Future<AlertDialog?> _showError(String error) {
    return showDialog<AlertDialog>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Error while streaming logcat"),
              content: Text(error),
              actions: [
                TextButton(
                  autofocus: true,
                  onPressed: _queueSave,
                  child: const Text("Save"),
                ),
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Back"))
              ],
            ));
  }

  Widget buildList() {
    if (_streamSubscription == null) {
      return const CircularProgressIndicator();
    }

    return ListView.builder(
      key: ValueKey(logs.length),
      shrinkWrap: true,
      controller: widget.scrollController,
      itemBuilder: ((context, index) => SelectableText(
            logs[index],
            key: ValueKey(index),
          )),
      itemCount: logs.length,
    );
  }

  void _queueSave() {
    waitForSave = true;
  }

  void _saveLog() async {
    const String fileName = 'log.txt';
    final path = await getSaveLocation(suggestedName: fileName);

    if (path == null) return;

    var file = File(path.path);
    var writer = file.openWrite();

    writer.writeAll(logs, PlatformUtils.platformFileEnding);
    await writer.flush();
    await writer.close();

    // TODO: user feedback when finished
  }
}
