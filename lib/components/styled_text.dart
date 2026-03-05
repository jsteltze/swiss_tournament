import 'package:flutter/material.dart';

class StyledText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const StyledText(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final segments = text.split('**');
    var isBold = true;

    return Text.rich(
      TextSpan(
        children: segments.map<TextSpan>((s) {
          isBold = !isBold;
          final fontWeight = isBold ? FontWeight.bold : FontWeight.normal;
          return TextSpan(
            text: s,
            style: style == null
                ? TextStyle(fontWeight: fontWeight)
                : style!.copyWith(fontWeight: fontWeight),
          );
        }).toList(),
      ),
    );
  }
}
