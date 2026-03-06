import 'package:flutter/material.dart';

class InputTitle extends StatelessWidget {
  final String text;

  const InputTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall!.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
