import 'package:flutter/widgets.dart';
import 'package:routemaster/routemaster.dart';

abstract class Routes {
  static NavigationResult<T> browse<T extends Object?>(
      BuildContext context, String serialID,
      [String path = "sdcard"]) {
    return Routemaster.of(context).push<T>(
      '/browser/$serialID/$path',
    );
  }

  static NavigationResult<T> devices<T extends Object?>(BuildContext context) {
    return Routemaster.of(context).push<T>(
      '/devices',
    );
  }

  static NavigationResult<T> log<T extends Object?>(
      BuildContext context, String serialID) {
    return Routemaster.of(context).push<T>(
      '/log/$serialID',
    );
  }
}
