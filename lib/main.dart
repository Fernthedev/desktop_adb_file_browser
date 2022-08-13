import 'package:desktop_adb_file_browser/pages/ADBCheck.dart';
import 'package:desktop_adb_file_browser/pages/browser.dart';
import 'package:desktop_adb_file_browser/pages/devices.dart';
import 'package:desktop_adb_file_browser/pigeon_impl.dart';
import 'package:desktop_adb_file_browser/routes.dart';
import 'package:desktop_adb_file_browser/utils/adb.dart';
import 'package:dio/dio.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:routemaster/routemaster.dart';

final routes = RouteMap(routes: {
  '/': (_) => const MaterialPage(key: ValueKey("adbcheck"), child: ADBCheck(redirectPage: '/devices',)),

  '/devices': (_) =>
      const MaterialPage(key: ValueKey("devices"), child: DevicesPage()),

  '/browser/:device/:path': (info) => MaterialPage(
      key: const ValueKey("browser"),
      child: DeviceBrowser(
        serial: info.pathParameters['device']!,
        initialAddress: info.pathParameters['path']!,
      ))

  // '/feed': (_) => MaterialPage(child: FeedPage()),
  // '/settings': (_) => MaterialPage(child: SettingsPage()),
  // '/feed/profile/:id': (info) => MaterialPage(
  //     child: ProfilePage(id: info.pathParameters['id'])
  // ),
});

late Native2FlutterImpl native2flutter;

void main() {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });

  runApp(const MyApp());
  debugPrint("Pigeon");
  native2flutter = Native2FlutterImpl();
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerDelegate: RoutemasterDelegate(routesBuilder: (context) => routes),
      routeInformationParser: const RoutemasterParser(),

      title: 'ADB File Manager',
      // https://rydmike.com/flexcolorschemeV4Tut5/#/
      theme: FlexThemeData.light(
        scheme: FlexScheme.sanJuanBlue,
        surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
        blendLevel: 20,
        appBarOpacity: 0.95,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 20,
          blendOnColors: false,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
        // To use the playground font, add GoogleFonts package and uncomment
        fontFamily: GoogleFonts.notoSans().fontFamily,
      ),
      darkTheme: FlexThemeData.dark(
        scheme: FlexScheme.sanJuanBlue,
        surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
        blendLevel: 15,
        appBarStyle: FlexAppBarStyle.background,
        appBarOpacity: 0.90,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 30,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
        // To use the playground font, add GoogleFonts package and uncomment
        fontFamily: GoogleFonts.notoSans().fontFamily,
      ),

      // If you do not have a themeMode switch, uncomment this line
      // to let the device system mode control the theme mode:
      // themeMode: ThemeMode.system,
      themeMode: ThemeMode.dark,
      // theme: ThemeData(
      //   // This is the theme of your application.
      //   //
      //   // Try running your application with "flutter run". You'll see the
      //   // application has a blue toolbar. Then, without quitting the app, try
      //   // changing the primarySwatch below to Colors.green and then invoke
      //   // "hot reload" (press "r" in the console where you ran "flutter run",
      //   // or simply save your changes to "hot reload" in a Flutter IDE).
      //   // Notice that the counter didn't reset back to zero; the application
      //   // is not restarted.
      //   primarySwatch: Colors.blue,
      // ),
    );
  }
}

