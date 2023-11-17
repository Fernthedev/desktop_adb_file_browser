import 'package:flutter/cupertino.dart';

typedef WidgetBuild = Widget Function();

@immutable
class ConditionalWidget extends StatelessWidget {
  const ConditionalWidget(
      {super.key, required this.show, required this.size, required this.child});

  final bool show;
  final double? size;
  final WidgetBuild child; // TODO: Optimize, ignore if not showing

  @override
  Widget build(BuildContext context) {
    if (!show) {
      if (size == null) return Container();

      return SizedBox(width: size! + 16);
    }

    return child();
  }
}
