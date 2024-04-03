import 'dart:async';
import 'dart:io';

import 'package:desktop_adb_file_browser/utils/adb.dart';
import 'package:desktop_adb_file_browser/utils/platform.dart';
import 'package:file_selector/file_selector.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:routemaster/routemaster.dart';
import 'package:trace/trace.dart';

import '../../utils/scroll.dart';

class LogPage extends StatefulWidget {
  const LogPage({super.key, required this.serial});

  final String serial;

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  final List<String> _logs = [];
  final UniqueKey _listKey = UniqueKey();
  final _scrollController = AdjustableScrollController();

  late final Future<(Process, Stream<String>)> _logFuture =
      Adb.logcat(widget.serial);
  bool _showLogs = false;
  StreamSubscription<String>? _streamSubscription;

  // Since Dart can't keep up fast enough with logcat when spammed,
  // we queue the save for when the stream slows down
  // which we assume is no longer spam
  bool waitForSave = false;
  DateTime lastStreamSend = DateTime.now();

  @override
  void initState() {
    super.initState();
    _logFuture.then(_handleLogFuture).onError((error, stackTrace) {
      Trace.verbose("Error $error");
      Trace.verbose(stackTrace.toString());
      _showError(error.toString());
    });
  }

  FutureOr<Null> _handleLogFuture((Process, Stream<String>) values) {
    final (process, stream) = values;
    try {
      _streamSubscription = stream.listen((event) {
        setState(() {
          var newLogs = event
              .split(PlatformUtils.platformFileEnding)
              .where((element) => element.trim().isNotEmpty);
          _logs.addAll(newLogs);

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
  }

  @override
  void dispose() {
    super.dispose();
    _streamSubscription?.cancel();
    _logFuture.then((value) {
      final (process, _) = value;
      process.kill();
    });
  }

  @override
  Widget build(BuildContext context) {
    var exitButton = IconButton(
      icon: const Icon(
        FluentIcons.arrow_left_24_filled,
        size: 24,
      ),
      onPressed: () {
        Routemaster.of(context).history.back();
      },
    );

    var conditionalExitButton =
        Routemaster.of(context).history.canGoBack ? exitButton : null;

    var visibilityAction = Padding(
        padding: const EdgeInsets.all(8.0),
        child: Wrap(
          alignment: WrapAlignment.spaceAround,
          children: [
            const Text(
              "Show logs",
              style: TextStyle(fontSize: 25),
            ),
            const SizedBox(
              width: 10,
            ),
            Switch(
                value: _showLogs,
                onChanged: (v) => setState(() {
                      _showLogs = v;
                    })),
          ],
        ));
    var saveAction = Padding(
      padding: const EdgeInsets.all(8.0),
      child: IconButton(
          onPressed: _queueSave,
          icon: const Icon(
            FluentIcons.save_28_regular,
            size: 28,
          )),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text("Logcat"),
        leading: conditionalExitButton,
        automaticallyImplyLeading: true,
        actions: [saveAction, visibilityAction],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Visibility(
          visible: _showLogs,
          replacement: _loadingSpinner(),
          child: Container(
            color: Theme.of(context).colorScheme.background,
            child: buildList(),
          ),
        ),
      ),
    );
  }

  Widget _loadingSpinner() {
    return const Center(
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
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Back")),
                FilledButton(
                  autofocus: true,
                  onPressed: _queueSave,
                  child: const Text("Save"),
                )
              ],
            ));
  }

  Widget buildList() {
    if (_streamSubscription == null) {
      return const CircularProgressIndicator();
    }

    return ListView.builder(
      key: _listKey,
      shrinkWrap: true,
      // controller: _scrollController,
      itemBuilder: ((context, index) => SelectableText(
            _logs[index],
            key: ValueKey(index),
          )),
      itemCount: _logs.length,
      findChildIndexCallback: (key) => (key as ValueKey).value,
      prototypeItem: const SelectableText(""),
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

    writer.writeAll(_logs, PlatformUtils.platformFileEnding);
    await writer.flush();
    await writer.close();

    // TODO: user feedback when finished
  }
}
