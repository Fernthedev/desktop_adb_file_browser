import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/pigeon.g.dart',
  dartOptions: DartOptions(),
  cppOptions: CppOptions(
    namespace: "pigeon",
  ),
  cppHeaderOut: 'windows/runner/pigeon.g.h',
  cppSourceOut: 'windows/runner/pigeon.g.cpp',
  objcHeaderOut: 'macos/Runner/pigeon.g.h',
  objcSourceOut: 'macos/Runner/pigeon.g.m',
  // Set this to a unique prefix for your plugin or application, per Objective-C naming conventions.
  objcOptions: ObjcOptions(prefix: 'PGN'),
  // copyrightHeader: 'pigeons/copyright.txt',
  dartPackageName: 'desktop_adb_file_browser',
))

// https://github.com/flutter/flutter/issues/108682
@FlutterApi()
abstract class Native2Flutter {
  void onClick(bool forward);
}
