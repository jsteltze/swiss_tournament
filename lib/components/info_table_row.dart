import 'package:flutter/material.dart';

class InfoRow {
  final String title;
  final String contentText;
  final Widget? contentWidget;

  const InfoRow(this.title, this.contentText, {this.contentWidget});

  TableRow build(BuildContext context) {
    return TableRow(
      children: [
        Text(
          title,
          style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
        ),
        contentWidget != null ? contentWidget! : Text(contentText),
      ],
    );
  }
}
