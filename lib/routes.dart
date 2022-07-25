import 'package:desktop_adb_file_browser/utils/adb.dart';
import 'package:flutter/widgets.dart';
import 'package:routemaster/routemaster.dart';

abstract class Routes {
  static NavigationResult<T> browse<T extends Object?>(BuildContext context, String serialID) {
    return Routemaster.of(context).push<T>(
      '/browser/$serialID/sdcard',
    );
  }

  static NavigationResult<T> devices<T extends Object?>(
      BuildContext context) {
    return Routemaster.of(context).push<T>(
      '/devices',
    );
  }

}
