import 'package:intl/intl.dart';

extension TimestampX on DateTime {
  String toHumanString() => DateFormat('yyyy-MM-dd HH:mm').format(this);
}
