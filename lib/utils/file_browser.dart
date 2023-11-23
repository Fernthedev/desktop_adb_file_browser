import 'package:desktop_adb_file_browser/utils/adb.dart';
import 'package:desktop_adb_file_browser/utils/stack.dart';
import 'package:flutter/widgets.dart';
import 'package:trace/trace.dart';

typedef FileNavigateEvent = void Function(String newPath);

class FileBrowser {
  final TextEditingController addressBar;

  final StackCollection<String> _historyPaths = StackCollection();

  final StackCollection<String> _forwardPaths = StackCollection();
  FileNavigateEvent? navigateEvent;

  FileBrowser({required this.addressBar});
  String get currentPath => addressBar.text;

  set _currentPath(String val) => addressBar.text = val;

  void refresh() {
    _refreshFiles(newPath: null, addToHistory: false);
  }

  void back() {
    if (_historyPaths.isEmpty) return;
    Trace.verbose("Pushed back $currentPath");

    _forwardPaths.push(currentPath);
    _refreshFiles(newPath: _historyPaths.pop(), addToHistory: false);
  }

  void forward() {
    if (_forwardPaths.isEmpty) return;
    Trace.verbose("Pushed forward ${_forwardPaths.isNotEmpty}");

    _refreshFiles(newPath: _forwardPaths.pop());
  }

  void navigateToDirectory(String directory) {
    _refreshFiles(newPath: directory);
    _forwardPaths.clear();
    Trace.verbose("clear forward");
  }

  void _refreshFiles({String? newPath, bool addToHistory = true}) {
    var oldAddressText = currentPath;

    newPath = newPath == null
        ? null
        : Adb.adbPathContext
            .canonicalize(Adb.fixPath(newPath, addQuotes: false));

    if (newPath != null) {
      if (addToHistory) {
        _historyPaths.push(currentPath);
      }
      _currentPath = newPath;
    }

    /// Don't refresh unnecessarily
    /// This will still allow refreshes when pressing enter
    /// on the address bar because the address bar passes [path] as null
    /// TODO: Remove this or clarify
    if (newPath != null && oldAddressText == newPath) return;

    navigateEvent?.call(newPath ?? currentPath);
  }
}
