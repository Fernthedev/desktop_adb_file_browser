import 'package:pigeon/pigeon.dart';

// https://github.com/flutter/flutter/issues/108682
@FlutterApi()
abstract class Native2Flutter {
  void onClick(bool forward);
}
