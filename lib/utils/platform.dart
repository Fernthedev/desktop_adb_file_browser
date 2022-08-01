// https://github.com/flutter/flutter/blob/ac1aa511ca94f46c7e80b94dafd521de35e808e5/packages/flutter_tools/lib/src/base/config.dart#L184-L207

// Reads the process environment to find the current user's home directory.
//
// If the searched environment variables are not set, '.' is returned instead.
//
// Note that this is different from FileSystemUtils.homeDirPath.
import 'dart:io';

import 'package:path/path.dart' as host_path;


abstract class PlatformUtils {
  /// The default directory name for Flutter's configs.
  /// Configs will be written to the user's config path. If there is already a
  /// file with the name `.${kConfigDir}_$name` in the user's home path, that
  /// file will be used instead.
  static const String kConfigDir = 'flutter';

  /// Environment variable specified in the XDG Base Directory
  /// [specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
  /// to specify the user's configuration directory.
  static const String kXdgConfigHome = 'XDG_CONFIG_HOME';

  /// Fallback directory in the user's home directory if `XDG_CONFIG_HOME` is
  /// not defined.
  static const String kXdgConfigFallback = '.config';

  /// The default name for the Flutter config file.
  static const String kFlutterSettings = 'settings';

  static String userHomePath() {
    final String envKey = Platform.isWindows ? 'APPDATA' : 'HOME';
    return Platform.environment[envKey] ?? '.';
  }

  static Future<String> configPath(String name) async {
    final String homeDirFile =
        host_path.join(userHomePath(), '.${kConfigDir}_$name');
    if (Platform.isLinux || Platform.isMacOS) {
      if (await File(homeDirFile).exists()) {
        return homeDirFile;
      }
      final String configDir = Platform.environment[kXdgConfigHome] ??
          host_path.join(userHomePath(), '.config', kConfigDir);
      return host_path.join(configDir, name);
    }
    return homeDirFile;
  }
}
