extension ExtQuickNum on BigInt {
  String get toRadix16 => "0x${toRadixString(16)}";
}

extension ExtQuickListNum on Iterable<BigInt> {
  BigInt get sum => fold(BigInt.zero, (p, c) => p + c);
}

extension ExtQuickIntListNum on Iterable<int> {
  BigInt get sumBig => fold(BigInt.zero, (p, c) => p + BigInt.from(c));
  int get sum => fold(0, (p, c) => p + c);
}

extension ExtQuicIntkNum on int {
  String get toRadix16 => "0x${toRadixString(16)}";
}
