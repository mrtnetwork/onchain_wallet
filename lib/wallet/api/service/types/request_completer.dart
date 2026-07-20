import 'dart:async';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:on_chain_bridge/dev/dev.dart';
import 'package:on_chain_wallet/app/core.dart';

class SocketRequestCompleter {
  SocketRequestCompleter(this.params, this.id);
  final Completer<IResult<Map<String, dynamic>>> _completer = Completer();
  final List<int> params;
  final int id;
  void complete(Map<String, dynamic> data) {
    Logging.info(
        when: () => _completer.isCompleted,
        fn: () => AppLogData(
            runtime: runtimeType,
            function: "complete",
            msg: "Message already completed."));
    if (_completer.isCompleted) return;
    _completer.complete(ResultOk(data));
  }

  Future<IResult<Map<String, dynamic>>> wait(Duration timeout) =>
      _completer.future.timeout(timeout, onTimeout: () {
        error(APIErrorConst.timeoutException);
        return ResultErr.fromException(APIErrorConst.timeoutException);
      });

  void error(IException err) {
    Logging.info(
        when: () => _completer.isCompleted,
        fn: () => AppLogData(
            runtime: runtimeType, function: "error", msg: "Message already completed."));
    if (_completer.isCompleted) return;
    _completer.complete(ResultErr.fromException(err));
  }
}
