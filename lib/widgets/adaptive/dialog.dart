import 'dart:io';

import 'package:flutter/material.dart';

// import 'package:fluent_ui/fluent_ui.dart' as fluent;
// import 'package:macos_ui/macos_ui.dart' as macos;

Future<T?> showAdaptiveDialog<T extends Object?>(
    {required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true}) async {
  // if (Platform.isWindows) {
  //   return fluent.showDialog<T>(
  //     context: context,
  //     builder: builder,
  //     barrierDismissible: barrierDismissible,
  //   );
  // }

  // if (Platform.isMacOS) {
  //   return macos.showMacosAlertDialog<T>(
  //     context: context,
  //     builder: builder,
  //     barrierDismissible: barrierDismissible,
  //   );
  // }

  return showDialog<T>(
    context: context,
    builder: builder,
    barrierDismissible: barrierDismissible,
  );
}
