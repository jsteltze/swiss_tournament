import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:js_flutter/utils/dialog_utils.dart';
import 'package:js_flutter/utils/logger.dart';
import 'package:swiss_tournament/data/tournament.dart';

void openRatingDistributionDialog(Tournament t, BuildContext ctx) {
  bool onlyActive = false;

  openDialog(
    ctx,
    title: 'Rating distribution',
    closeButtonTitle: 'Close',
    child: (ctx, setDialogState, toggleMainAction) => Column(
      children: [
        Padding(
          padding: EdgeInsetsGeometry.only(bottom: 100),
          child: SizedBox(
            height: 400,
            width: 400,
            child: BarChart(
              mainData(ctx, t, onlyActive),
              duration: Duration(milliseconds: 300), // Optional
              curve: Curves.bounceIn, // Optional,
            ),
          ),
        ),
        FilterChip(
          selected: onlyActive,
          onSelected: (x) => {setDialogState(() => onlyActive = x)},
          label: const Text('only active Players '),
        ),
      ],
    ),
  );
}

BarChartData mainData(BuildContext ctx, Tournament t, bool onlyActive) {
  const stepSize = 100;
  final players = t.players
      .where((p) => !onlyActive || p.leftAt == null)
      .toList();

  final int playersWithRating = players.where((p) => p.rating > 0).length;
  double avgRating =
      players
          .where((p) => p.rating > 0)
          .map((p) => p.rating)
          .fold(0, (a, b) => a + b) /
      playersWithRating;

  int minRating = players
      .where((p) => p.rating > 0)
      .map((p) => p.rating)
      .reduce(min);
  int maxRating = players.map((p) => p.rating).reduce(max);
  int minColumn = (minRating / stepSize).floor() * stepSize;
  int maxColumn = (maxRating / stepSize).floor() * stepSize;
  int avgColumn = -1;

  List<BarChartGroupData> spots = [];
  for (int i = minColumn; i <= maxColumn; i += stepSize) {
    int countRatingRange = players
        .where((p) => p.rating >= i && p.rating < i + stepSize)
        .length;
    if (avgRating >= i && avgRating < i + stepSize) {
      avgColumn = i;
    }
    spots.add(makeGroupData(ctx, i, countRatingRange.toDouble()));
  }
  FileLogger.log('spots: $spots');
  FileLogger.log('avgColumn: $avgColumn');

  return BarChartData(
    gridData: FlGridData(
      horizontalInterval: 1,
      drawVerticalLine: false,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: Theme.of(ctx).colorScheme.secondary,
          dashArray: const [4, 4],
          strokeWidth: 0.5,
        );
      },
    ),
    minY: 0,
    extraLinesData: ExtraLinesData(verticalLines: [VerticalLine(x: 1580)]),
    barTouchData: BarTouchData(
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (touchedSpot) =>
            Theme.of(ctx).colorScheme.surfaceTint.withAlpha(200),
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          int numberPlayers = rod.toY.floor();
          return BarTooltipItem(
            '$numberPlayers Player${numberPlayers > 1 ? 's' : ''}\n',
            Theme.of(ctx).textTheme.titleLarge!
                .copyWith(color: Theme.of(ctx).colorScheme.onInverseSurface),
            children: <TextSpan>[
              TextSpan(
                text: '${group.x} - ${group.x + stepSize}',
                style: Theme.of(ctx).textTheme.titleMedium!.copyWith(
                  color: Theme.of(ctx).colorScheme.onInverseSurface,
                ),
              ),
            ],
          );
        },
      ),
    ),
    titlesData: FlTitlesData(
      show: true,
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: bottomTitleWidgets(
        ctx,
        spots,
        minRating,
        maxRating,
        avgRating.round(),
        minColumn,
        maxColumn,
        avgColumn,
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1,
          reservedSize: 42,
          minIncluded: false,
        ),
      ),
    ),
    borderData: FlBorderData(
      show: true,
      border: Border(
        bottom: BorderSide(color: Theme.of(ctx).colorScheme.outline),
      ),
    ),
    barGroups: spots,
  );
}

BarChartGroupData makeGroupData(
  BuildContext ctx,
  int x,
  double y, {
  bool isTouched = false,
  double width = 22,
  List<int> showTooltips = const [],
}) {
  return BarChartGroupData(
    x: x,
    barRods: [
      BarChartRodData(
        toY: y,
        rodStackItems: [
          BarChartRodStackItem(
            0,
            y,
            Theme.of(ctx).colorScheme.primaryContainer,
          ),
        ],
        color: Theme.of(ctx).colorScheme.primaryContainer,
        width: width,
        borderSide: BorderSide(color: Theme.of(ctx).colorScheme.outline),
      ),
    ],
    showingTooltipIndicators: showTooltips,
  );
}

AxisTitles bottomTitleWidgets(
  BuildContext ctx,
  List<BarChartGroupData> spots,
  int minRating,
  int maxRating,
  int avgRating,
  int minColumn,
  int maxColumn,
  int avgColumn,
) {
  return AxisTitles(
    sideTitleAlignment: .inside,
    drawBelowEverything: false,
    sideTitles: SideTitles(
      showTitles: true,
      getTitlesWidget: (value, meta) => SideTitleWidget(
        meta: meta,
        angle: -pi / 2.0,
        space: 0,
        child: Stack(
          children: [
            if (value == minColumn || value == maxColumn || value == avgColumn)
              Container(
                width: 90,
                height: 100,
                transform: Matrix4.translationValues(0.0, -7.0, 0.0),
                child: Column(
                  children: [
                    if (value == minColumn) ...[
                      Text(
                        'min. Rating',
                        style: Theme.of(ctx).textTheme.labelSmall!.copyWith(
                          color: Theme.of(ctx).colorScheme.tertiary,
                        ),
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Theme.of(ctx).colorScheme.tertiary,
                      ),
                      Text(
                        minRating.toString(),
                        style: Theme.of(ctx).textTheme.labelSmall!.copyWith(
                          color: Theme.of(ctx).colorScheme.tertiary,
                        ),
                      ),
                    ],
                    if (value == maxColumn) ...[
                      Text(
                        'max. Rating',
                        style: Theme.of(ctx).textTheme.labelSmall!.copyWith(
                          color: Theme.of(ctx).colorScheme.tertiary,
                        ),
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Theme.of(ctx).colorScheme.tertiary,
                      ),
                      Text(
                        maxRating.toString(),
                        style: Theme.of(ctx).textTheme.labelSmall!.copyWith(
                          color: Theme.of(ctx).colorScheme.tertiary,
                        ),
                      ),
                    ],
                    if (value == avgColumn) ...[
                      Text(
                        'avg. Rating',
                        style: Theme.of(ctx).textTheme.labelSmall!.copyWith(
                          color: Theme.of(ctx).colorScheme.tertiary,
                        ),
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Theme.of(ctx).colorScheme.tertiary,
                      ),
                      Text(
                        avgRating.toString(),
                        style: Theme.of(ctx).textTheme.labelSmall!.copyWith(
                          color: Theme.of(ctx).colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            //Column(children: [Text('Rating'), Text('5')]),
            Padding(
              padding: EdgeInsetsGeometry.only(left: 100, bottom: 0, top: 2),
              child: SizedBox(
                width: 110,
                height: 100,
                child: spots.any((s) => s.x == value && s.barRods.first.toY > 0)
                    ? Text(
                        '${value.toStringAsFixed(0)} - ${(value + 100).toStringAsFixed(0)}',
                        style: Theme.of(ctx).textTheme.bodySmall!.copyWith(
                          color: Theme.of(ctx).colorScheme.onPrimaryContainer,
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
