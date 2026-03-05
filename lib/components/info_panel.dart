import 'package:flutter/material.dart';

class InfoPanel extends StatelessWidget {
  final Widget child;

  const InfoPanel(this.child, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        border: BoxBorder.all(
          color: Theme.of(context).colorScheme.secondary.withAlpha(50),
        ),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: child,
    );
  }
}
