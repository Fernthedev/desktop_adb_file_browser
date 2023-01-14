import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class UploadingFilesWidget extends StatefulWidget {
  final int taskAmount;

  final ValueListenable<double> progressIndications;
  const UploadingFilesWidget(
      {Key? key, required this.taskAmount, required this.progressIndications})
      : super(key: key);

  @override
  State<UploadingFilesWidget> createState() => _UploadingFilesWidgetState();
}

class _UploadingFilesWidgetState extends State<UploadingFilesWidget> {
  @override
  Widget build(BuildContext context) {
    var progressIndications = widget.progressIndications;
    var taskAmount = widget.taskAmount;

    return ValueListenableBuilder<double>(
        valueListenable: progressIndications,
        builder: (BuildContext context, double progress, _) {
          var theme = Theme.of(context);

          return SizedBox(
            height: 50,
            child: Column(
              children: [
                // Reverse calculation because less data needed to be passed!
                Text(
                  "Uploading ${(progress * taskAmount).round()}/$taskAmount (${(progress * 100).round()}%)",
                  style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.snackBarTheme.contentTextStyle?.color),
                ),
                const SizedBox(height: 20),
                LinearProgressIndicator(
                  value: progress,
                  color: Theme.of(context).colorScheme.secondary,
                )
              ],
            ),
          );
        });
  }
}
