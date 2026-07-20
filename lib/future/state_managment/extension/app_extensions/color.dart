import 'dart:ui' show Color;

extension ExtHexColor on Color {
  static Color decodeString(String hexString) {
    final parts = hexString.split('_');
    final a = double.parse(parts[0]);
    final r = double.parse(parts[1]);
    final g = double.parse(parts[2]);
    final b = double.parse(parts[3]);
    return Color.from(alpha: a, red: r, green: g, blue: b);
  }

  String encodeString() {
    return "${a}_${r}_${g}_$b";
  }
}
