import 'package:shared_preferences/shared_preferences.dart';

const adbShortcutNames = "adb_shortcuts_names";
const adbShortcutsPaths = "adb_shortcuts_paths";
const adbWatcherSrc = "adb_watcher_src";
const adbWatcherDest = "adb_watcher_dest";

typedef HostPath = String;
typedef QuestPath = String;

extension AppStorage on SharedPreferences {
  Map<String, String> getMap(String key, String value) {
    var keys = getStringList(key);
    keys ??= [];
    var values = getStringList(value);
    values ??= [];

    return Map.fromIterables(keys, values);
  }

  Future<void> setMap(String key, String value, Map<String, String> map) async {
    final keys = map.keys.toList(growable: false);
    final values = keys.map((e) => map[e]!).toList(growable: false);

    await setStringList(key, keys);
    await setStringList(value, values);
  }

  Future<Map<String, String>> getShortcutsMap() async {
    return getMap(adbShortcutNames, adbShortcutsPaths);
  }

  Future<void> setShortcutsMap(Map<String, String> map) {
    return setMap(adbShortcutNames, adbShortcutsPaths, map);
  }

  Future<Map<HostPath, QuestPath>> getWatchersMap() async {
    return getMap(adbWatcherSrc, adbWatcherDest);
  }

  Future<void> setWatchersMap(Map<HostPath, QuestPath> map) {
    return setMap(adbWatcherSrc, adbWatcherDest, map);
  }
}
