import 'package:flutter/cupertino.dart';

class ConditionalWidget extends StatelessWidget {
  const ConditionalWidget(
      {Key? key, required this.show, required this.size, required this.child})
      : super(key: key);

  final bool show;
  final double size;
  final Widget child; // TODO: Optimize, ignore if not showing

  @override
  Widget build(BuildContext context) {
    if (!show) return SizedBox(width: size + 16);

    return child;
  }
}
