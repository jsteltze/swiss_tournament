import 'package:flutter/material.dart';
import 'package:js_flutter/components/number_card.dart';
import 'package:js_flutter/components/view_header.dart';
import 'package:swiss_tournament/data/tournament.dart';

class TournamentsViewHeader extends StatelessWidget {
  final List<Tournament> tournaments;
  final bool filterNotFinished;
  final Function(bool filterNotFinished) filterCallback;

  const TournamentsViewHeader(
    this.tournaments,
    this.filterNotFinished,
    this.filterCallback, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final countNotFinished = tournaments.where((t) => !t.isFinished()).length;
    return ViewHeader(
      padding: const EdgeInsets.only(),
      ExpansionTile(
        title: Text(
          'Your Tournaments',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        childrenPadding: EdgeInsets.all(5),
        shape: BoxBorder.all(color: Colors.transparent),
        children: [
          IntrinsicHeight(
            child: Row(
              spacing: 8,
              children: [
                NumberCard(
                  tournaments.length.toString(),
                  label: 'All',
                  icon: Icon(
                    Icons.emoji_events_outlined,
                    applyTextScaling: true,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                NumberCard(
                  countNotFinished.toString(),
                  label: 'In Progress',
                  variant: .green,
                  icon: Icon(
                    Icons.change_circle,
                    applyTextScaling: true,
                    color: Colors.green.withAlpha(150),
                  ),
                ),
                NumberCard(
                  (tournaments.length - countNotFinished).toString(),
                  label: 'Finished',
                  icon: Icon(
                    Icons.check,
                    applyTextScaling: true,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          if (countNotFinished > 0)
            Row(
              mainAxisAlignment: .end,
              spacing: 10,
              children: [
                Icon(
                  Icons.filter_alt_outlined,
                  color: Theme.of(context).colorScheme.secondary.withAlpha(100),
                  applyTextScaling: true,
                  size: 18,
                ),
                Text(
                  'Filter:',
                  style: Theme.of(context).textTheme.labelMedium!
                      .copyWith(color: Theme.of(context).colorScheme.secondary),
                ),
                FilterChip(
                  label: Text(
                    'not finished ($countNotFinished)',
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  selected: filterNotFinished,
                  onSelected: filterCallback,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
