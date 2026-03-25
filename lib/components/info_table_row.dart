import 'package:flutter/material.dart';

class InfoRow extends StatelessWidget {
  final String title;
  final String contentText;
  final Widget? contentWidget;
  final Decoration? decoration;
  final double titleWidth;

  const InfoRow(
    this.title,
    this.contentText, {
    super.key,
    double? titleWidth,
    this.decoration,
    this.contentWidget,
  }) : titleWidth = titleWidth ?? 75;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: titleWidth,
          decoration: decoration,
          child: Text(
            title,
            style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
          ),
        ),
        Expanded(
          child: Container(
            decoration: decoration,
            child: contentWidget != null ? contentWidget! : Text(contentText),
          ),
        ),
      ],
    );
  }
}
