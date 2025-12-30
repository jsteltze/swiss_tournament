import 'package:flutter/material.dart';

import 'data/player.dart';

class PlayerTile extends StatelessWidget {
  final Player player;
  final int index;
  final bool detailed;
  final bool alignLeft;
  final PopupMenuButton? popup;

  const PlayerTile({
    super.key,
    required this.player,
    required this.index,
    bool? detailed,
    bool? alignLeft,
    this.popup,
  }) : detailed = detailed ?? false,
       alignLeft = alignLeft ?? true;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        player.name,
        style: detailed && player.leftAt != null
            ? TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: Row(
        spacing: 5,
        children: [
          Text(
            '#${index + 1}',
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          ),
          Expanded(
            child: Text(
              'Rating: ${player.rating > 0 ? player.rating : 'N/A'}',
              style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
            ),
          ),
          if (detailed && player.leftAt != null)
            Text(
              'left after round ${player.leftAt}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
      leading: alignLeft ? const Icon(Icons.person) : null,
      trailing: popup ?? (alignLeft ? null : const Icon(Icons.person)),
    );
  }
}
