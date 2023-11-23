import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:async/async.dart';
import 'package:desktop_adb_file_browser/utils/platform.dart';
import 'package:desktop_adb_file_browser/widgets/browser/file_data.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';

import 'package:path/path.dart' as host_path;

import 'package:path_provider/path_provider.dart';
import 'package:trace/trace.dart';

typedef DownloadProgressCallback = void Function(int current, int total);

abstract class Adb {
  static const String _adbTempFolder = "adb-platform-tools";
  static String? _adbCurrentPath;

  static final _fileListingRegex =
      RegExp(r"([\w-]+) *(\d+) *(\w+) *(\w+) *(\d+) *([\d-]+) *([\d:]+) *(.*)");

  static final Context adbPathContext = Context(style: Style.posix);

  static const String adbDownloadURL =
      "https://dl.google.com/android/repository/platform-tools-latest-";

  static Context get hostPath => host_path.context;

  static Future<void> downloadADB(
      DownloadProgressCallback c, CancelToken cancelToken) async {
    String adbFinalURL = adbDownloadURL;
    if (Platform.isWindows) adbFinalURL += "windows.zip";
    if (Platform.isMacOS) adbFinalURL += "darwin.zip";
    if (Platform.isLinux) adbFinalURL += "linux.zip";

    var downloadPath = await _getDownloadPath();
    await downloadPath.create();

    Trace.verbose("Downloading to ${downloadPath.absolute}");
    Trace.verbose("Downloading from $adbFinalURL");
    var rs = await Dio().get<List<int>>(adbFinalURL,
        options: Options(
            responseType: ResponseType.bytes), // set responseType to `stream`
        onReceiveProgress: c,
        cancelToken: cancelToken);

    var stream = rs.data;
    if (stream == null) throw "Stream is null";

    // Decode the zip from the InputFileStream. The archive will have the contents of the
    // zip, without having stored the data in memory.
    final archive = ZipDecoder().decodeBuffer(InputStream(stream));

    extractArchiveToDisk(archive, downloadPath.path);
    _adbCurrentPath = (await _getADBInstalledExecPath()).path;
    if (!Platform.isWindows) {
      // ignore: avoid_print
      Trace.info("Setting as executable for non-windows platforms");
      await Process.run("chmod", ["+x", _adbCurrentPath!]);
    }
  }

  static Future<Directory> _getDownloadPath() async {
    try {
      return Directory(hostPath.join(
          (await getApplicationSupportDirectory()).path, _adbTempFolder));
    } on MissingPlatformDirectoryException catch (_) {
    } on UnimplementedError catch (_) {}

    return Directory(
        hostPath.join(await PlatformUtils.configPath(_adbTempFolder)));
  }

  static Future<File> _getADBInstalledExecPath() async {
    var downloadPath = await _getDownloadPath();

    var adbExecName = Platform.isWindows ? "adb.exe" : "adb";

    var adbFile =
        File(hostPath.join(downloadPath.path, "platform-tools", adbExecName));

    return adbFile;
  }

  static Future<String> _locateAdbPath() async {
    if (_adbCurrentPath != null) {
      return _adbCurrentPath!;
    }

    var downloadPath = await _getADBInstalledExecPath();
    if (await downloadPath.exists()) {
      _adbCurrentPath = downloadPath.path;
    } else if (Platform.isWindows) {
      // Use adb in path
      _adbCurrentPath = "adb.exe";
    } else {
      // Use adb in path

      _adbCurrentPath = "adb";
    }

    // ignore: avoid_print
    Trace.info("Using adb in $_adbCurrentPath");

    return _adbCurrentPath!;
  }

  static Future<ProcessResult> runAdbCommand(
      String? serial, List<String> args) async {
    var newArgs = serial != null ? ["-s", serial, ...args] : args;

    var adbPath = await _locateAdbPath();

    // ignore: avoid_print
    Trace.info("Running adb command: \"$adbPath $newArgs\"");

    var process = await Process.run(adbPath, newArgs, runInShell: true);
    if (process.stderr != null && process.stderr.toString().isNotEmpty) {
      final error = process.stderr;
      Trace.verbose("Error $error");
      debugPrintStack();
      throw error.toString();
    }

    // if (process.exitCode != 0) throw "Process exit code was not 0!";

    return process;
  }

  static Future<Process> startAdbCommand(
      String? serial, List<String> args) async {
    var newArgs = serial != null ? ["-s", serial, ...args] : args;

    return await Process.start(await _locateAdbPath(), newArgs,
        runInShell: true);
  }

  static String normalizeOutput(String output) {
    return output.replaceAll("\r\n", "\n");
  }

  static String? normalizeOutputAndError(String output) {
    String result = output.replaceAll("\r\n", "\n");
    if (result.contains("no devices/emulators found") ||
        (result.contains("device ") && result.contains(" not found"))) {
      return null;
    }

    return result;
  }

  static String fixPath(String path, {bool addQuotes = true}) {
    if (!path.startsWith("/")) path = "/$path";

    if (addQuotes) {
      path = "\"$path\"";
    }
    return path;

    // return path
    //     .replaceAll('\\', '/')
    //     .replaceAll("'", "\\'")
    //     .replaceAll(" ", "\\ ")
    //     .replaceAll("(", "\\(")
    //     .replaceAll(")", "\\)")
    //     .replaceAll("&", "\\&")
    //     .replaceAll("|", "\\|");
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

  //
  static List<FileListingData> parsePathsWithMoreData(
      String str, String path, bool onlyNames) {
    // Remove unnecessary padding that ADB adds to get purely the paths
    var rawPaths = str.split("\n");
    /*
total 1002
drwxrwx--x 10 u0_a140 sdcard_rw   3488 2023-11-03 21:18 .
drwxrwx--x  4 u0_a140 sdcard_rw   3488 2023-11-03 21:09 ..
-rw-rw----  1 u0_a140 sdcard_rw    953 2023-11-01 10:44 AvatarData.dat
-rw-rw----  1 u0_a140 sdcard_rw    953 2023-11-01 10:44 AvatarData.dat.bak
-rw-rw----  1 u0_a140 sdcard_rw    953 2023-11-01 10:44 AvatarData.dat.tmp
-rw-rw----  1 u0_a140 sdcard_rw     24 2023-11-03 21:09 LocalDailyLeaderboards.dat
-rw-rw----  1 u0_a140 sdcard_rw     24 2023-11-03 21:09 LocalLeaderboards.dat
-rw-rw----  1 u0_a140 sdcard_rw  13424 2023-11-03 21:18 PlayerData.dat
-rw-rw----  1 u0_a140 sdcard_rw  13424 2023-11-03 21:16 PlayerData.dat.bak
drwxrwx--x  4 u0_a140 sdcard_rw   3488 2023-11-01 10:45 Unity
drwxrwx--x  5 u0_a140 sdcard_rw   3488 2023-11-01 10:44 il2cpp
drwxrwx--x  2 u0_a140 sdcard_rw   3488 2023-11-03 18:51 libs
drwxrwx--x  2 u0_a140 sdcard_rw   3488 2023-11-01 10:45 libs_old
drwxrwx--x  3 u0_a140 sdcard_rw   3488 2023-11-01 10:45 lldb
drwxrwx--x  3 u0_a140 sdcard_rw   3488 2023-11-03 21:09 logs
drwxrwx--x  2 u0_a140 sdcard_rw   3488 2023-11-03 21:09 mods
drwxrwx--x  2 u0_a140 sdcard_rw   3488 2023-11-01 10:45 mods_old
-rw-rw----  1 u0_a140 sdcard_rw   1547 2023-11-03 21:09 settings.cfg
-rw-rw----  1 u0_a140 sdcard_rw   1548 2023-11-01 10:44 settings.cfg.bak
-rw-rw----  1 u0_a140 sdcard_rw   1547 2023-11-03 21:09 settings.cfg.tmp
-rw-rw----  1 u0_a140 sdcard_rw 288566 2023-11-03 20:54 tombstone_00
-rw-rw----  1 u0_a140 sdcard_rw 332903 2023-11-03 20:54 tombstone_01
-rw-rw----  1 u0_a140 sdcard_rw 289307 2023-11-03 20:51 tombstone_02
-rw-rw----  1 u0_a140 sdcard_rw   8440 2023-11-01 10:44 videoplayer.player

     */

    var parsedPaths = rawPaths.sublist(1, rawPaths.length - 1).map((entry) {
      var matches = _fileListingRegex.firstMatch(entry)!;

      var permission = matches[1]!;
      var user = matches[3]!;
      var size = int.parse(matches[5]!);
      var date = matches[6]!;
      var hour24 = matches[7]!;
      var fileName = matches[8]!;

      var dateTime = DateTime.parse("$date $hour24");

      var pathEntry =
          onlyNames ? fileName : adbPathContext.join(path, fileName);

      // https://regex101.com/r/80ZN8E/1
      // group 1 -> permission
      // group 2 -> user id?
      // group 3 -> user name
      // group 4 -> user group
      // group 5 -> size
      // group 6 -> date
      // group 7 -> 24 hour time
      // group 8 -> file name

      return FileListingData(
        date: dateTime,
        path: pathEntry,
        permission: permission,
        size: size,
        user: user,
      );
    }).toList(growable: false);

    return parsedPaths;
  }

  static Future<List<String>> getFileNamesInDirectory(
      String? serialName, String path) async {
    var result =
        await runAdbCommand(serialName, ["shell", "ls -p -a ${fixPath(path)}"]);

    return parsePaths(
        normalizeOutput(result.stdout), fixPath(path, addQuotes: false), false);
  }

  static Future<List<FileListingData>> getFilesInDirectory(
      String? serialName, String path) async {
    var result =
        await runAdbCommand(serialName, ["shell", "ls -pLla ${fixPath(path)}"]);

    return parsePathsWithMoreData(
        normalizeOutput(result.stdout), fixPath(path, addQuotes: false), false);
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

  static Future<Stream<String>> logcat(String? serialName) async {
    await runAdbCommand(serialName, ["logcat", "-c"]); // flush

    var result = await startAdbCommand(serialName, ["logcat"]);

    return StreamGroup.mergeBroadcast([
      result.stderr.transform(utf8.decoder),
      result.stdout.transform(utf8.decoder),
    ]);
    // .transform(const LineSplitter());
  }

  static Future<String?> getDeviceName(String? serialName) async {
    var result = await runAdbCommand(
        serialName, ["shell", "getprop", "ro.product.model"]);

    return normalizeOutputAndError(result.stdout);
  }

  static Future<String> moveFile(
      String? serialName, String source, String dest) async {
    source = fixPath(source, addQuotes: true);
    dest = fixPath(dest, addQuotes: true);
    var result = await runAdbCommand(serialName, ["shell", "mv", source, dest]);

    return normalizeOutput(result.stdout);
  }

  static Future<String> downloadFile(
      String? serialName, String source, String destination) async {
    var result = await runAdbCommand(null, [
      "pull",
      fixPath(source, addQuotes: false),
      destination,
    ]);

    return normalizeOutput(result.stdout);
  }

  static Future<String> uploadFile(
      String serialName, String source, String destination) async {
    var result = await runAdbCommand(serialName, [
      "push",
      source,
      fixPath(destination, addQuotes: false),
    ]);

    return normalizeOutput(result.stdout);
  }

  static Future<Device> getDevice(String serialName) async {
    var deviceModelName = await getDeviceName(serialName);

    if (deviceModelName == null) {
      throw "Device not found";
    }

    return Device(serialName: serialName, modelName: deviceModelName);
  }

  static Future<List<Device>> getDevices() async {
    return await Future.wait(
        (await getDevicesSerial())!.map((e) async => await getDevice(e)));
  }

  static Future<DateTime?> getFileModifiedDate(
      String serialName, String path) async {
    var out = await runAdbCommand(
        serialName, ["shell", "stat -c %Y ${fixPath(path)}"]);

    String? result = normalizeOutputAndError(out.stdout);

    if (result == null) return null;

    return DateTime.fromMillisecondsSinceEpoch(int.parse(result) * 1000);
  }

  static Future<int?> getFileSize(String serialName, String path) async {
    var out = await runAdbCommand(
        serialName, ["shell", "stat -c %s ${fixPath(path)}"]);

    String? result = normalizeOutputAndError(out.stdout);

    if (result == null) return null;

    return int.parse(result);
  }

  static Future<void> createDirectory(String serialName, String path) async {
    await runAdbCommand(serialName, ["shell", "mkdir -p ${fixPath(path)}"]);
  }

  static Future<void> createFile(String serialName, String path) async {
    await runAdbCommand(serialName, ["shell", "touch ${fixPath(path)}"]);
  }

  static Future<void> removeFile(String serialName, String path) async {
    await runAdbCommand(serialName, ["shell", "rm ${fixPath(path)}"]);
  }

  static Future<void> removeDirectory(String serialName, String path) async {
    await runAdbCommand(serialName, ["shell", "rm -r ${fixPath(path)}"]);
  }

  static Future<void> enableWireless(String serialName) async {
    await runAdbCommand(serialName, ["tcpip", "5555"]);
  }

  static Future<void> connectWireless(String ip, int port) async {
    await runAdbCommand(null, ["connect", "$ip:$port"]);
  }
}

@immutable
class Device {
  final String serialName;
  final String? deviceManufacturer;
  final String modelName;

  Device(
      {required this.serialName,
      this.deviceManufacturer,
      required this.modelName});
}

@immutable
class FileListingData {
  final String permission;
  final String user;
  final int size;
  final DateTime date;
  final String path;

  FileListingData(
      {required this.permission,
      required this.user,
      required this.size,
      required this.date,
      required this.path});
}
