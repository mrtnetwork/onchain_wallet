import 'package:blockchain_utils/utils/utils.dart';

final List<int> _logTable = _createLogTable();
final List<int> _expTable = _createExpTable();

int glog(int n) {
  if (n < 1) {
    throw ArgumentError('glog($n)');
  }

  return _logTable[n];
}

int gexp(int n) {
  while (n < 0) {
    n += 255;
  }

  while (n >= 256) {
    n -= 255;
  }

  return _expTable[n];
}

List<int> _createExpTable() {
  final list = List<int>.filled(256, 0);
  for (var i = 0; i < 8; i++) {
    list[i] = 1 << i;
  }
  for (var i = 8; i < 256; i++) {
    list[i] = (list[i - 4] ^ list[i - 5] ^ list[i - 6] ^ list[i - 8]) &
        BinaryOps.mask8;
  }
  return list;
}

List<int> _createLogTable() {
  final list = List<int>.filled(256, 0);
  for (var i = 0; i < 255; i++) {
    list[_expTable[i]] = i;
  }
  return list;
}
