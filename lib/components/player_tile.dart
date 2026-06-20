import 'package:flutter/material.dart';

import '../data/player.dart';

class PlayerTile extends StatelessWidget {
  final Player player;
  final double? points;
  final int index;
  final bool detailed;
  final bool alignLeft;
  final PopupMenuButton? popup;
  final VoidCallback? onTap;

  const PlayerTile({
    super.key,
    required this.player,
    required this.index,
    bool? detailed,
    bool? alignLeft,
    this.points,
    this.popup,
    this.onTap,
  }) : detailed = detailed ?? false,
       alignLeft = alignLeft ?? true;

  @override
  Widget build(BuildContext context) {
    var style = detailed && player.leftAt != null
        ? TextStyle(decoration: TextDecoration.lineThrough)
        : null;
    if (index < 0) {
      style = TextStyle(
        color: Theme.of(context).colorScheme.secondary,
        fontStyle: FontStyle.italic,
      );
    }
    return ListTile(
      onTap: onTap,
      title: Text(player.name, style: style),
      subtitle: index < 0
          ? Text(index == -1 ? '(automatic)' : '(requested)')
          : Wrap(
              spacing: 5,
              children: [
                Text(
                  '#${index + 1}',
                  style: TextStyle(
                    fontFamily: 'RobotoMono',
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                Text(
                  '${detailed ? '| Rating: ' : '('}${player.rating > 0 ? player.rating : 'N/A'}${detailed ? '' : ')'}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
                if (detailed && player.leftAt != null)
                  Expanded(
                    child: Text(
                      'withdrawn ${player.leftAt == 0 ? '' : '(round ${player.leftAt})'}',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                if (detailed && player.joinedAt > 0 && player.leftAt == null)
                  Expanded(
                    child: Text(
                      'joined after round ${player.joinedAt}',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
      leading: alignLeft && index >= 0 ? PlayerIcon(points: points) : null,
      trailing:
          popup ?? (alignLeft || index < 0 ? null : PlayerIcon(points: points)),
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
