import 'dart:io';

class Adb {
  static Future<ProcessResult> runAdbCommand(List<String> args) {
    return Process.run("adb.exe", args);
  }

  static String normalizeOutput(String output) =>
      output.replaceAll("\r\n", "\n");

  static Future<List<String>?> getDevicesSerial() async {
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
        .toList(growable: false);
  }

  static Future<String> getDeviceName(String serialName) async {
    var result = await runAdbCommand(
        ["-s", (serialName), "shell", "getprop", "ro.product.model"]);

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
