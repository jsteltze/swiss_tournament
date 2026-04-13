import 'package:flutter/material.dart';

class DialogAction {
  final String title;
  final VoidCallback? onPressed;
  final Icon? icon;
  final bool isDestructive;

  DialogAction({
    required this.title,
    this.onPressed,
    this.icon,
    this.isDestructive = false,
  });
}

void openDialog(
  BuildContext context, {
  required String title,
  required Widget Function(BuildContext, void Function(void Function())) child,
  Icon? titleIcon,
  DialogAction? mainAction,
  List<DialogAction>? secondaryActions,
  String? closeButtonTitle = 'Cancel',
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            insetPadding: EdgeInsets.all(20),
            icon: titleIcon,
            title: Text(
              title,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            content: SingleChildScrollView(
              child: child(context, setDialogState),
            ),
            actions: <Widget>[
              if (closeButtonTitle != null)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(closeButtonTitle),
                ),
              ...?secondaryActions?.map(
                (a) => TextButton.icon(
                  onPressed: a.onPressed,
                  style: TextButton.styleFrom(
                    foregroundColor: a.isDestructive
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                  ),
                  label: Text(a.title),
                  icon: a.icon,
                ),
              ),
              if (mainAction != null)
                ElevatedButton.icon(
                  onPressed: mainAction.onPressed,
                  style: TextButton.styleFrom(
                    backgroundColor: mainAction.isDestructive
                        ? Theme.of(context).colorScheme.errorContainer
                        : Theme.of(context).colorScheme.primary.withAlpha(
                            mainAction.onPressed == null ? 30 : 255,
                          ),
                    foregroundColor: mainAction.isDestructive
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.onPrimary,
                  ),
                  label: Text(mainAction.title),
                  icon: mainAction.icon,
                ),
            ],
          );
        },
      );
    },
  );
}
