import 'package:on_chain_wallet/app/stream/live.dart';

class LivePercentProgressBar {
  int _total = 0;
  int _counter = 0;

  /// emits only stepped percent: 0, 10, 20, ...
  final StreamValue<double> progress = StreamValue(0, name: "LivePercentProgressBar");
  bool get isClosed => progress.isClosed;
  int _lastStep = -1;

  void init(int total) {
    _total = total;
    _counter = 0;

    _lastStep = -1;
    progress.value = 0;
  }

  void _update() {
    if (_total == 0) return;

    final percent = (_counter * 100) / _total;

    // round down to nearest 10%
    final step = (percent ~/ 10) * 10;

    if (step != _lastStep) {
      _lastStep = step;
      progress.value = percent / 100;
    }
  }

  void counter() {
    _counter++;
    if (_counter > _total) _counter = _total;
    _update();
  }

  void add(int value) {
    _counter += value;
    if (_counter > _total) _counter = _total;
    _update();
  }

  void set(int value) {
    _counter = value;
    if (_counter > _total) _counter = _total;
    _update();
  }

  void dispose() {
    progress.dispose();
  }
}
