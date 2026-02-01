import 'dart:ui';

extension ColorX on Color {
  String toHexTriplet() =>
      '#${(toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
