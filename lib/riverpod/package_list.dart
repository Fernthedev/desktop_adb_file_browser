import 'dart:collection';

import 'package:desktop_adb_file_browser/riverpod/selected_device.dart';
import 'package:desktop_adb_file_browser/utils/adb.dart';
import 'package:desktop_adb_file_browser/utils/stack.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:trace/trace.dart';

part 'package_list.g.dart';
part 'package_list.freezed.dart';

@freezed
class PackageMetadata with _$PackageMetadata {
  const factory PackageMetadata({
    required String packageName,
    required String packageId,
    required String version,
  }) = _PackageMetadata;
}

@riverpod
class PackageList extends _$PackageList {
  @override
  Future<List<String>> build() async {
    final serial = ref.watch(selectedDeviceProvider);

    var list = await Adb.getPackageList(serial?.serialName);

    list.sort();

    return list;
  }

  void installToDevice(String path) {}

  void deletePackage(String id) {}
}

@riverpod
Future<PackageMetadata> packageInfo(PackageInfoRef ref, String id) async {
  final device = ref.watch(selectedDeviceProvider);

  return Adb.getPackageInfo(device?.serialName, id);
}
