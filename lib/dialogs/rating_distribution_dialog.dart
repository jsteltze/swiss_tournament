import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:js_flutter/utils/dialog_utils.dart';
import 'package:js_flutter/utils/logger.dart';
import 'package:swiss_tournament/data/tournament.dart';

final animationDuration = 500;
final animationDelay = 300;

void openRatingDistributionDialog(Tournament t, BuildContext ctx) {
  bool onlyActive = false;
  bool triggerAnimation = false;
  bool triggerLabels = false;
  final haveWithdrawn = t.players.any((p) => p.leftAt != null);

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
  int maxY = 0;

  List<BarChartGroupData> spots = [];
  List<BarChartGroupData> spotsZero = [];
  for (int i = minColumn; i <= maxColumn; i += stepSize) {
    int countRatingRange = players
        .where((p) => p.rating >= i && p.rating < i + stepSize)
        .length;
    if (countRatingRange > maxY) {
      maxY = countRatingRange;
    }
    if (avgRating >= i && avgRating < i + stepSize) {
      avgColumn = i;
    }
    spots.add(makeGroupData(ctx, i, countRatingRange.toDouble()));
    spotsZero.add(makeGroupData(ctx, i, 0));
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
        height: 150,
        transform: Matrix4.translationValues(0.0, 3.0, 0.0),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
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
                fontSize: 15,
                color: Theme.of(ctx).colorScheme.tertiary,
                fontWeight: .bold,
              ),
              textScaler: TextScaler.linear(1.0),
            ),
          ],
        ),
      );
    }
    return null;
  }

  openDialog(
    ctx,
    maxWidth: true,
    title: 'Rating distribution',
    closeButtonTitle: 'Close',
    /*onShowingDelay: 2000,
    onShowingCallback: (setDialogState) {
      print('onShowingCallback');
      setDialogState(() {
        triggerAnimation = true;
      });
    },*/
    child: (ctx, setDialogState, toggleMainAction) {
      if (!triggerAnimation) {
        Future.delayed(Duration(milliseconds: animationDelay), () {
          setDialogState(() {
            triggerAnimation = true;
          });
        });
        Future.delayed(
          Duration(milliseconds: animationDelay + animationDuration),
          () {
            setDialogState(() {
              triggerLabels = true;
            });
          },
        );
      }
      return Column(
        children: [
          Padding(
            padding: EdgeInsetsGeometry.only(bottom: 100),
            child: SizedBox(
              height: 400,
              width: .infinity,
              child: BarChart(
                BarChartData(
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
                  maxY: maxY + 0.5,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (touchedSpot) =>
                          Theme.of(ctx).colorScheme.surfaceTint.withAlpha(200),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        int numberPlayers = rod.toY.floor();
                        return BarTooltipItem(
                          '$numberPlayers Player${numberPlayers > 1 ? 's' : ''}\n',
                          Theme.of(ctx).textTheme.titleLarge!.copyWith(
                            color: Theme.of(ctx).colorScheme.onInverseSurface,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: '${group.x} - ${group.x + stepSize}',
                              style: Theme.of(ctx).textTheme.titleMedium!
                                  .copyWith(
                                    color: Theme.of(ctx)
                                        .colorScheme
                                        .onInverseSurface,
                                  ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: bottomTitleWidgets(
                      ctx,
                      spots,
                      triggerLabels,
                      getLabels,
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 42,
                        minIncluded: false,
                        maxIncluded: false,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          child: Text(
                            value.toStringAsFixed(0),
                            style: Theme.of(ctx).textTheme.titleMedium!
                                .copyWith(
                                  color: Theme.of(ctx).colorScheme.tertiary,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(ctx).colorScheme.outline,
                      ),
                    ),
                  ),
                  barGroups: triggerAnimation ? spots : spotsZero,
                ),
                curve: Curves.easeIn,
                duration: Duration(milliseconds: animationDuration),
              ),
            ),
          ),
          if (haveWithdrawn)
            FilterChip(
              selected: onlyActive,
              onSelected: (bool x) {
                setDialogState(() {
                  onlyActive = x;
                  //triggerAnimation = !triggerAnimation;
                });
              },
              label: const Text('only active Players '),
            ),
        ],
      );
    },
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
  bool triggerLabels,
  Function(double) getLabels,
) {
  return AxisTitles(
    sideTitleAlignment: .inside,
    drawBelowEverything: false,
    sideTitles: SideTitles(
      showTitles: true,
      reservedSize: 50,
      getTitlesWidget: (value, meta) => SideTitleWidget(
        meta: meta,
        angle: -pi / 2.0,
        space: 0,
        child: AnimatedOpacity(
          opacity: triggerLabels ? 1 : 0,
          duration: Duration(milliseconds: animationDuration),
          child: Stack(
            children: [
              ?getLabels(value),
              Padding(
                padding: EdgeInsetsGeometry.only(left: 100, bottom: 0, top: 14),
                child: SizedBox(
                  width: 130,
                  height: 50,
                  child:
                      spots.any((s) => s.x == value && s.barRods.first.toY > 0)
                      ? Text(
                          '${value.toStringAsFixed(0)} - ${(value + 100).toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 15,
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
    ),
  );
}
