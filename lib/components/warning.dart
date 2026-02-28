import 'package:flutter/material.dart';

class Warning extends StatelessWidget {
  final String text;

  const Warning(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        border: BoxBorder.all(
          color: Theme.of(context).colorScheme.error.withAlpha(50),
        ),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Text(
        text,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
