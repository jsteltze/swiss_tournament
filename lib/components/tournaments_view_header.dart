import 'package:flutter/material.dart';
import 'package:js_flutter/components/number_card.dart';
import 'package:js_flutter/components/view_header.dart';
import 'package:swiss_tournament/data/tournament.dart';

class TournamentsViewHeader extends StatefulWidget {
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
  State<TournamentsViewHeader> createState() => _TournamentsViewHeaderState();
}

class _TournamentsViewHeaderState extends State<TournamentsViewHeader> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final countNotFinished = widget.tournaments
        .where((t) => !t.isFinished())
        .length;
    return ViewHeader(
      padding: EdgeInsets.only(bottom: _isExpanded ? 0 : 10),
      Column(
        children: [
          TextButton(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                Text(
                  'Your Tournaments',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 24,
                  applyTextScaling: true,
                ),
              ],
            ),
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
          Padding(
            padding: .symmetric(horizontal: 10),
            child: IntrinsicHeight(
              child: Row(
                spacing: 8,
                children: [
                  NumberCard(
                    widget.tournaments.length.toString(),
                    isExpanded: _isExpanded,
                    label: 'All',
                    icon: Icon(
                      Icons.emoji_events_outlined,
                      applyTextScaling: true,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  NumberCard(
                    countNotFinished.toString(),
                    isExpanded: _isExpanded,
                    label: 'In Progress',
                    variant: .green,
                    icon: Icon(
                      Icons.change_circle,
                      applyTextScaling: true,
                      color: Colors.green.withAlpha(150),
                    ),
                  ),
                  NumberCard(
                    (widget.tournaments.length - countNotFinished).toString(),
                    label: 'Finished',
                    isExpanded: _isExpanded,
                    icon: Icon(
                      Icons.check,
                      applyTextScaling: true,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (countNotFinished > 0)
            Visibility(
              visible: _isExpanded,
              child: Row(
                mainAxisAlignment: .end,
                spacing: 10,
                children: [
                  Icon(
                    Icons.filter_alt_outlined,
                    color: Theme.of(context).colorScheme.secondary
                        .withAlpha(100),
                    applyTextScaling: true,
                    size: 18,
                  ),
                  Text(
                    'Filter:',
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  FilterChip(
                    label: Text(
                      'not finished ($countNotFinished)',
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSecondaryContainer,
                      ),
                    ),
                    selected: widget.filterNotFinished,
                    onSelected: widget.filterCallback,
                  ),
                  SizedBox(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
