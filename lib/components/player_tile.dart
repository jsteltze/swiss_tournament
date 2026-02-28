import 'package:flutter/material.dart';

import '../data/player.dart';

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
    var style = detailed && player.leftAt != null
        ? TextStyle(decoration: TextDecoration.lineThrough)
        : null;
    if (index == -1) {
      style = TextStyle(
        color: Theme.of(context).colorScheme.secondary,
        fontStyle: FontStyle.italic,
      );
    }
    return ListTile(
      title: Text(player.name, style: style),
      subtitle: index == -1
          ? null
          : Row(
              spacing: 5,
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    '#${index + 1}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${detailed ? '| Rating: ' : '('}${player.rating > 0 ? player.rating : 'N/A'}${detailed ? '' : ')'}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                ),
                if (detailed && player.leftAt != null)
                  Text(
                    'withdraw after round ${player.leftAt}',
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
      leading: alignLeft && index != -1 ? PlayerIcon(points: points) : null,
      trailing:
          popup ??
          (alignLeft || index == -1 ? null : PlayerIcon(points: points)),
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
        Icon(Icons.person, color: Theme.of(context).colorScheme.secondary),
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
