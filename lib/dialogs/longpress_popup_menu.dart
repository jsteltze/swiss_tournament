import 'package:flutter/material.dart';

/// A simple long press popup menu.
class LongPressPopupMenu<T> extends StatefulWidget {
  /// The popup menu entries for the long press menu.
  final List<PopupMenuEntry<T>> items;

  /// ValueChanged callback with selected item in the long press menu.
  /// Is null if menu closed without selection by clicking outside the menu.
  final ValueChanged<T?> onSelected;

  /// The child that can be long pressed to activate the long press menu.
  final Widget child;

  /// Default constructor
  const LongPressPopupMenu({
    super.key,
    required this.child,
    required this.items,
    required this.onSelected,
  });

  @override
  State<StatefulWidget> createState() => _LongPressPopupMenuState<T>();
}

class _LongPressPopupMenuState<T> extends State<LongPressPopupMenu<T>> {
  Offset _downPosition = const Offset(0, 0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (TapDownDetails details) {
        _downPosition = details.globalPosition;
      },
      onLongPress: () async {
        final RenderBox? overlay =
            Overlay.of(context).context.findRenderObject() as RenderBox?;
        if (overlay != null) {
          final T? value = await showMenu<T>(
            context: context,
            items: widget.items,
            position: RelativeRect.fromLTRB(
              _downPosition.dx,
              _downPosition.dy,
              overlay.size.width - _downPosition.dx,
              overlay.size.height - _downPosition.dy,
            ),
          );
          widget.onSelected(value);
        }
      },
      child: widget.child,
    );
  }
}
