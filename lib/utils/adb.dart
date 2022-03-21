import 'dart:io';

import 'package:path/path.dart';

import 'package:path/path.dart' as hostPath;

abstract class Adb {
  static final Context adbPathContext = Context(style: Style.posix);

  static Future<ProcessResult> runAdbCommand(
      String? serial, List<String> args) {
    return Process.run(
        "adb.exe", serial != null ? ["-s", serial, ...args] : args);
  }

  static String normalizeOutput(String output) =>
      output.replaceAll("\r\n", "\n");

  static String fixPath(String path) {
    if (!path.startsWith("/")) path = "/" + path;
    return path.replaceAll('\\', '/');
  }

  // https://github.com/Lauriethefish/QuestPatcher/blob/37d6ee872bbc44f47b4994e5b95a7d0902797939/QuestPatcher.Core/AndroidDebugBridge.cs#L361
  static List<String> parsePaths(String str, String path, bool onlyNames) {
    // Remove unnecessary padding that ADB adds to get purely the paths
    var rawPaths = str.split("\n");
    List<String> parsedPaths = [];
    for (int i = 0; i < rawPaths.length - 1; i++) {
      var currentPath = rawPaths[i];
      if (currentPath.substring(0, currentPath.length - 1) ==
          ':') // Directories within this one that aren't the first index lead to this
      {
        break;
      }

      if (onlyNames) {
        parsedPaths.add(currentPath);
      } else {
        parsedPaths.add(adbPathContext.join(path, currentPath));
      }
    }

    return parsedPaths;
  }

  static Future<List<String>?> getFilesInDirectory(
      String? serialName, String path) async {
    path = fixPath(path);
    var result = await runAdbCommand(serialName, ["shell", "ls -p \"$path\""]);

    return parsePaths(normalizeOutput(result.stdout), path, false);
  }

  static Future<List<String>?> getDevicesSerial() async {
    const requiredString = "List of devices attached\n";

    var result = await runAdbCommand(null, ["devices"]);

    var ret = normalizeOutput(result.stdout);

    if (!ret.startsWith(requiredString)) {
      return null;
    }

    return ret
        .substring(requiredString.length)
        .split("\n")
        .where((e) => e.isNotEmpty)
        .map((e) => e.substring(0, e.indexOf("\t")).replaceAll("\n", "").trim())
        .where((element) => element.isNotEmpty)
        .toList(growable: false);
  }

  static Future<String> getDeviceName(String? serialName) async {
    var result = await runAdbCommand(
        serialName, ["shell", "getprop", "ro.product.model"]);

    return normalizeOutput(result.stdout);
  }

  static Future<String> downloadFile(
      String? serialName, String source, String destination) async {
    var result = await runAdbCommand(null, [
      "pull",
      fixPath(source),
      destination,
    ]);

    return normalizeOutput(result.stdout);
  }

  static Future<String> uploadFile(
      String serialName, String source, String destination) async {
    var result = await runAdbCommand(serialName, [
      "push",
      "\"$source\"",
      "\"${fixPath(destination)}\"",
    ]);

    return normalizeOutput(result.stdout);
  }

  static Future<Device> getDevice(String serialName) async {
    return Device(
        serialName: serialName, modelName: await getDeviceName(serialName));
  }

  static Future<List<Device>> getDevices() async {
    return await Future.wait(
        (await getDevicesSerial())!.map((e) async => await getDevice(e)));
  }
}

class Device {
  String serialName;
  String? deviceManufacturer;
  String modelName;

  Device(
      {required this.serialName,
      this.deviceManufacturer,
      required this.modelName});
}
