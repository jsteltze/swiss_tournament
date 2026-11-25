import 'package:js_flutter/components/badge.dart';
import 'package:js_flutter/components/info_panel.dart';
import 'package:js_flutter/components/view_header.dart';
import 'package:material_ui/material_ui.dart';
import 'package:swiss_tournament/data/tournament.dart';

import '../dialogs/rating_distribution_dialog.dart';

class PlayersViewHeader extends StatefulWidget {
  final Tournament tournament;
  final Function(bool) filterCallback;

  const PlayersViewHeader(
    this.tournament, {
    required this.filterCallback,
    super.key,
  });

  @override
  State<PlayersViewHeader> createState() => _PlayersViewHeaderState();
}

class _PlayersViewHeaderState extends State<PlayersViewHeader> {
  bool _filterActive = false;

  @override
  Widget build(BuildContext context) {
    final int playersWithRating = widget.tournament.players
        .where((p) => p.rating > 0)
        .length;
    double averageRating = 0;
    if (playersWithRating > 1) {
      averageRating =
          widget.tournament.players
              .where((p) => p.rating > 0)
              .map((p) => p.rating)
              .fold(0, (a, b) => a + b) /
          playersWithRating;
    }

    return ViewHeader(
      headerTitle: 'PLAYERS:',
      headerIcon: Icon(
        Icons.people,
        size: 24,
        color: Theme.of(context).colorScheme.primary,
      ),
      headerWidgets: [
        MyBadge(widget.tournament.players.length.toString(), variant: .primary),
      ],
      extensionWidgets: [
        InfoPanel(
          Text('Players are read-only because the tournament is finished.'),
        ),
        Row(
          mainAxisAlignment: .spaceBetween,
          children: [
            Padding(
              padding: .symmetric(horizontal: 15),
              child: FilterChip(
                label: Text(
                  'active (${widget.tournament.players.where((p) => p.leftAt == null).length})',
                ),
                selected: _filterActive,
                onSelected: (x) {
                  setState(() {
                    _filterActive = x;
                  });
                  widget.filterCallback.call(x);
                },
              ),
            ),
            if (playersWithRating > 1)
              Padding(
                padding: .symmetric(horizontal: 15),
                child: OutlinedButton(
                  onPressed: () =>
                      openRatingDistributionDialog(widget.tournament, context),
                  child: Column(
                    crossAxisAlignment: .end,
                    children: [
                      Text(
                        'Average rating:',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                      MyBadge(
                        '',
                        variant: .tertiary,
                        child: Stack(
                          alignment: .centerLeft,
                          children: [
                            Text(
                              'o',
                              style: Theme.of(context).textTheme.titleMedium!
                                  .copyWith(
                                    fontFamily: 'RobotoMono',
                                    color: Theme.of(context)
                                        .colorScheme
                                        .tertiary,
                                  ),
                            ),
                            Text(
                              '/',
                              style: Theme.of(context).textTheme.titleMedium!
                                  .copyWith(
                                    fontFamily: 'RobotoMono',
                                    color: Theme.of(context)
                                        .colorScheme
                                        .tertiary,
                                  ),
                            ),
                            Text(
                              '     ${averageRating.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.titleSmall!
                                  .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .tertiary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 2),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
