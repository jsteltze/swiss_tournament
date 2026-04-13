import 'package:intl/intl.dart';

extension TimestampX on DateTime {
  String toHumanString() =>
      '${DateFormat.yMMMd().format(this)}, ${DateFormat.Hm().format(this)}';

  String toTechString() => DateFormat('yyyyMMdd_HHmmss').format(this);
}
