import 'package:flutter/material.dart';

class InfoRow extends StatelessWidget {
  final String title;
  final String contentText;
  final Widget? contentWidget;
  final double titleWidth;

  const InfoRow(
    this.title,
    this.contentText, {
    super.key,
    double? titleWidth,
    this.contentWidget,
  }) : titleWidth = titleWidth ?? 75;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: titleWidth,
          child: Text(
            title,
            style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
          ),
        ),
        Expanded(
          child: contentWidget != null
              ? contentWidget!
              : Text(
                  contentText,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
        ),
      ],
    );
  }
}
