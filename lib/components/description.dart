import 'package:flutter/material.dart';

class Description extends StatefulWidget {
  final String text;
  final bool isExpandable;
  final int expandChars;

  const Description(
    this.text, {
    super.key,
    bool? isExpandable,
    int? expandChars,
  }) : isExpandable = isExpandable ?? false,
       expandChars = expandChars ?? 80;

  @override
  State<Description> createState() => _DescriptionState();
}

class _DescriptionState extends State<Description> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isExpandable && widget.text.length > widget.expandChars) {
      final foldIndex = widget.text.indexOf(' ', widget.expandChars);
      final shortText = '${widget.text.substring(0, foldIndex)}...';
      return SizedBox(
        width: double.maxFinite,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              curve: Curves.easeInOut,
              alignment: Alignment.topLeft,
              duration: Duration(milliseconds: 500),
              child: Text(
                _isExpanded ? widget.text : shortText,
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
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
            ),
          ],
        ),
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
