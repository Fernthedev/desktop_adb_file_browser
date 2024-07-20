import 'dart:convert';

import 'package:desktop_adb_file_browser/utils/adb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trace/trace.dart';

part 'settings.g.dart';
part 'settings.freezed.dart';

@freezed
class SettingsData with _$SettingsData {
  const factory SettingsData({@Default(10) int multipleAdbInstances}) =
      _SettingsData;

  factory SettingsData.fromJson(Map<String, Object?> json) =>
      _$SettingsDataFromJson(json);
}

@Riverpod(keepAlive: true)
SharedPreferences preferences(PreferencesRef ref) {
  throw UnimplementedError();
}

@Riverpod(keepAlive: true)
class Settings extends _$Settings {
  @override
  SettingsData build() {
    // hook into ADB
    ref.listenSelf((old, newV) {
      Trace.info("Listen self");

      Adb.settings = newV;
      if (old != newV) {
        save();
      }
    });

    final json = ref.watch(preferencesProvider).getString("settings");
    if (json == null) return const SettingsData();

    return SettingsData.fromJson(jsonDecode(json));
  }

  Future<void> save() async {
    var prefs = ref.read(preferencesProvider);

    await prefs.setString("settings", jsonEncode(state.toJson()));

    Trace.info("Saving prefs");
  }

  void update(SettingsData settings) {
    state = settings;
  }
}
