import 'package:intl/intl.dart';

extension TimestampX on DateTime {
  String toHumanString() => DateFormat('yyyy-MM-dd HH:mm').format(this);

  String toTechString() => DateFormat('yyyyMMdd_HHmmss').format(this);
}
