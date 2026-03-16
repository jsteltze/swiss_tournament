import 'package:flutter/material.dart';

void showSnackbar(BuildContext ctx, String text, [bool isError = false]) {
  if (ctx.mounted) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: TextStyle(
            color: isError
                ? Theme.of(ctx).colorScheme.onErrorContainer
                : Theme.of(ctx).colorScheme.onPrimaryContainer,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError
            ? Theme.of(ctx).colorScheme.errorContainer
            : Theme.of(ctx).colorScheme.primaryContainer,
      ),
    );
  }
}
