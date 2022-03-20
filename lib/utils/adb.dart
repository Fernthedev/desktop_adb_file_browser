import 'dart:io';

class Adb {
  static Future<ProcessResult> runAdbCommand(List<String> args) {
    return Process.run("adb.exe", args);
  }

  static String normalizeOutput(String output) =>
      output.replaceAll("\r\n", "\n");

  static Future<List<Device>?> getDevices() async {
    const requiredString = "List of devices attached\n";

    var result = await runAdbCommand(["devices"]);

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
        .map((e) => Device(serialName: e))
        .toList(growable: false);
  }
}

class Device {
  String deviceName;
  String serialName;

  String deviceManufacturer = "";

  Device({this.deviceName = "", required this.serialName});

  @override
  String toString() {
    return 'Device{deviceName: $deviceName, serialName: $serialName, deviceManufacturer: $deviceManufacturer}';
  }
}
