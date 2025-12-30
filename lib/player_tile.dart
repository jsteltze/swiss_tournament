import 'package:flutter/material.dart';

import 'data/player.dart';

class PlayerTile extends StatelessWidget {
  final Player player;
  final double? points;
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
    this.points,
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
              '${detailed ? 'Rating: ' : '('}${player.rating > 0 ? player.rating : 'N/A'}${detailed ? '' : ')'}',
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
          if (detailed && player.joinedAt > 0 && player.leftAt == null)
            Text(
              'joined after round ${player.joinedAt}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
      leading: alignLeft ? PlayerIcon(points: points) : null,
      trailing: popup ?? (alignLeft ? null : PlayerIcon(points: points)),
    );
  }
}

class PlayerIcon extends StatelessWidget {
  final double? points;

  const PlayerIcon({super.key, this.points});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.person),
        if (points != null)
          Text(
            points!.toStringAsFixed(1),
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
      ],
    );
  }
}
