import 'package:flutter/material.dart';

typedef StringBuilderFn = String Function(
    int totalFutures, int remainingFutures);

class ProgressSnackbar extends StatefulWidget {
  const ProgressSnackbar(
      {super.key, required this.futures, required this.stringBuilder});

  final Iterable<Future> futures;
  final StringBuilderFn stringBuilder;

  @override
  State<ProgressSnackbar> createState() => _ProgressSnackbarState();
}

class _ProgressSnackbarState extends State<ProgressSnackbar> {
  late final futuresList = widget.futures.toList();

  int futureCount = 0;

  @override
  void initState() {
    super.initState();
    updateFutureCount();
  }

  void updateFutureCount() async {
    for (int i = 0; i < futuresList.length; i++) {
      await futuresList[futureCount];
      // update state
      setState(() {
        futureCount = i;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String content =
        widget.stringBuilder(futuresList.length, futureCount);

    return Column(
      children: [
        Text(content),
        const SizedBox(height: 20),
        LinearProgressIndicator(
          value: futureCount / futuresList.length,
        )
      ],
    );
    ;
  }
}
