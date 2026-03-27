import 'package:expandable_search_bar_plus/expandable_search_bar_plus.dart';
import 'package:flutter/material.dart';

class SearchField extends StatefulWidget {
  final Function(String) onSearch;

  const SearchField({super.key, required this.onSearch});

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  bool _isExpanded = false;
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ExpandableSearchBarPlus(
      controller: controller,
      hintText: 'Search player',
      iconColor: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      iconBackgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      icon: _isExpanded ? Icon(Icons.close) : Icon(Icons.search),
      textStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      onTap: (isExpanded) {
        setState(() {
          _isExpanded = isExpanded;
        });
        if (!isExpanded) {
          controller.clear();
          widget.onSearch.call('');
        }
      },
      onChanged: (value) {
        widget.onSearch.call(value);
      },
    );
  }
}
