import 'package:flutter/material.dart';

class InfoRow extends StatelessWidget {
  final String title;
  final String contentText;
  final Widget? contentWidget;
  final Decoration? decoration;
  final TextAlign? titleAlign;
  final double titleWidth;

  const InfoRow(
    this.title,
    this.contentText, {
    super.key,
    double? titleWidth,
    this.decoration,
    this.contentWidget,
    this.titleAlign,
  }) : titleWidth = titleWidth ?? 75;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 5,
      children: [
        Container(
          width: titleWidth,
          decoration: decoration,
          child: Text(
            title,
            textAlign: titleAlign,
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
