import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:js_flutter/utils/dialog_utils.dart';
import 'package:js_flutter/utils/logger.dart';
import 'package:swiss_tournament/data/tournament.dart';

void openRatingDistributionDialog(Tournament t, BuildContext ctx) {
  bool onlyActive = false;
  final haveWithdrawn = t.players.any((p) => p.leftAt != null);

  openDialog(
    ctx,
    maxWidth: true,
    title: 'Rating distribution',
    closeButtonTitle: 'Close',
    child: (ctx, setDialogState, toggleMainAction) => Column(
      children: [
        Padding(
          padding: EdgeInsetsGeometry.only(bottom: 100),
          child: SizedBox(
            height: 400,
            width: .infinity,
            child: BarChart(
              key: ValueKey<bool>(onlyActive),
              chartRendererKey: ValueKey<bool>(onlyActive),
              mainData(ctx, t, onlyActive),
              duration: Duration(milliseconds: 300), // Optional
              curve: Curves.bounceIn, // Optional,
            ),
          ),
        ),
        if (haveWithdrawn)
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

  Widget? getLabels(double value) {
    if (value == minColumn || value == maxColumn || value == avgColumn) {
      var label = '';
      var number = 0;
      if (value == maxColumn) {
        label = 'max. Rating';
        number = maxRating;
      } else if (value == minColumn) {
        label = 'min. Rating';
        number = minRating;
      } else if (value == avgColumn) {
        label = 'avg. Rating';
        number = avgRating.round();
      }
      return Container(
        width: 90,
        height: 100,
        transform: Matrix4.translationValues(0.0, -7.0, 0.0),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(ctx).colorScheme.tertiary,
              ),
              textScaler: TextScaler.linear(1.0),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(ctx).colorScheme.tertiary,
            ),
            Text(
              number.toString(),
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(ctx).colorScheme.tertiary,
              ),
              textScaler: TextScaler.linear(1.0),
            ),
          ],
        ),
      );
    }
    return null;
  }

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
      bottomTitles: bottomTitleWidgets(ctx, spots, getLabels),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1,
          reservedSize: 42,
          minIncluded: false,
          getTitlesWidget: (value, meta) => SideTitleWidget(
            meta: meta,
            child: Text(
              value.toStringAsFixed(0),
              style: Theme.of(ctx).textTheme.titleMedium!
                  .copyWith(color: Theme.of(ctx).colorScheme.tertiary),
            ),
          ),
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
  Function(double) getLabels,
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
            ?getLabels(value),
            Padding(
              padding: EdgeInsetsGeometry.only(left: 100, bottom: 0, top: 2),
              child: SizedBox(
                width: 110,
                height: 100,
                child: spots.any((s) => s.x == value && s.barRods.first.toY > 0)
                    ? Text(
                        '${value.toStringAsFixed(0)} - ${(value + 100).toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(ctx).colorScheme.onPrimaryContainer,
                        ),
                        textScaler: TextScaler.linear(1.0),
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
