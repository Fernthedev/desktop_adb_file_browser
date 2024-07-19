import 'package:desktop_adb_file_browser/utils/adb.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_device.g.dart';

@riverpod
class SelectedDevice extends _$SelectedDevice {
  @override
  Device? build() => null;

  void selectDevice(Device? s) {
    state = s;
  }

  void unselect() {
    state = null;
  }
}
