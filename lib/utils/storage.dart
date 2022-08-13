import 'package:shared_preferences/shared_preferences.dart';

extension AppStorage on SharedPreferences {
  Future<List<String>> getShortcutsNames() async {
    var list = getStringList("adb_shortcuts_names");
    if (list != null) {
      return list;
    }
    list = [];
    await setStringList("adb_shortcuts_names", []);
    return list;
  }

  Future<List<String>> getShortcutsPaths() async {
    var list = getStringList("adb_shortcuts_paths");
    if (list != null) {
      return list;
    }
    list = [];
    await setStringList("adb_shortcuts_paths", []);
    return list;
  }

  Future<Map<String, String>> getShortcutsMap() async {
    var names = await getShortcutsNames();
    var paths = await getShortcutsPaths();

    return Map.fromIterables(names, paths);
  }

  Future<void> setShortcutsMap(Map<String, String> map) async {
    final keys = map.keys.toList(growable: false);
    final values = keys.map((e) => map[e]!).toList(growable: false);

    await setStringList("adb_shortcuts_names", keys);
    await setStringList("adb_shortcuts_paths", values);
  }
}
