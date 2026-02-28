import 'package:flutter/material.dart';

class Description extends StatefulWidget {
  final String text;
  final bool isExpandable;

  const Description(this.text, {super.key, bool? isExpandable})
    : isExpandable = isExpandable ?? false;

  @override
  State<Description> createState() => _DescriptionState();
}

class _DescriptionState extends State<Description> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isExpandable) {
      final firstSpaceAfter100 = widget.text.indexOf(' ', 100);
      final shortText = '${widget.text.substring(0, firstSpaceAfter100)}...';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _isExpanded ? widget.text : shortText,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size(50, 15),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              alignment: Alignment.centerLeft,
              textStyle: Theme.of(context).textTheme.bodySmall,
            ),
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                ),
                Text(_isExpanded ? 'Fold' : 'Expand'),
              ],
            ),
          ),
        ],
      );
    } else {
      return Text(
        widget.text,
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
          color: Theme.of(context).colorScheme.secondary,
        ),
      );
    }
  }
}
