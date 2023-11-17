import 'package:desktop_adb_file_browser/src/pigeon.g.dart';
import 'package:desktop_adb_file_browser/utils/listener.dart';
import 'package:flutter/services.dart';

class Native2FlutterImpl extends Native2Flutter {
  EventListenable<void> mouseForwardClick = EventListenable();
  EventListenable<void> mouseBackClick = EventListenable();

  Native2FlutterImpl([BinaryMessenger? messenger]) {
    Native2Flutter.setup(this, binaryMessenger: messenger);
  }

  @override
  void onClick(bool forward) async {
    if (forward) {
      mouseForwardClick.invoke(null);
    } else {
      mouseBackClick.invoke(null);
    }
  }
}
