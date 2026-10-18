import 'package:flutter/material.dart';
import 'package:js_flutter/components/badge.dart';

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
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '#${index + 1}',
                  style: TextStyle(
                    fontFamily: 'RobotoMono',
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                MyBadge(
                  '${detailed ? 'Rating: ' : ''}${player.rating > 0 ? player.rating : 'N/A'}',
                  variant: BadgeVariant.tertiary,
                ),
                if (detailed && player.leftAt != null)
                  MyBadge(
                    'withdrawn ${player.leftAt == 0 ? '' : '(round ${player.leftAt})'}',
                  ),
                if (detailed && player.joinedAt > 0 && player.leftAt == null)
                  MyBadge('joined after round ${player.joinedAt}'),
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
            style: Theme.of(context).textTheme.labelSmall!
                .copyWith(color: Theme.of(context).colorScheme.primary),
          ),
      ],
    );
  }
}
