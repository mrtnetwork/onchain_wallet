import 'dart:async';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/widgets/parogress.dart';
import 'package:on_chain_wallet/web3/web3/web3.dart';

abstract class Web3GlobalRequestStateContoller<WEB3REQUEST extends Web3Request>
    extends StateController {
  WEB3REQUEST get request;

  final StreamWeb3PageProgressController controller =
      StreamWeb3PageProgressController(initialStatus: Web3RequestStatusProgress());
  StreamSubscription<dynamic>? _statusListener;
  Future<void> initWeb3();
  bool get web3Closed => request.info.isClosed;

  void _onChangeStatus(Web3RequestCompleterEvent? event) {
    if (event == null) return;
    switch (event.type) {
      case Web3RequestCompleterEventType.success:
        controller.successRequest();
        break;
      case Web3RequestCompleterEventType.closed:
        controller.closedRequest(
            error: event.latestError?.message, pageClosed: event.pageClosed);
        break;
      default:
    }
  }

  Future<void> _readyWeb3() async {
    final isReady = await MethodUtils.executeAfterDelay(() async {
      if (web3Closed) {
        controller.closedRequest();
      } else {
        _statusListener = request.info.stream.listen(_onChangeStatus);
        return true;
      }
      return false;
    });
    if (isReady) {
      final initWeb3 = await IResult.call(() => this.initWeb3());
      initWeb3.mapErr((err) {
        controller.errorResponse(error: err.exception);
        final error = Web3RequestExceptionConst.fromException(err.exception);
        request.error(error);
        return err.exception;
      });
    }
  }

  @override
  void ready() {
    super.ready();
    _readyWeb3();
  }

  @override
  void close() {
    _statusListener?.cancel();
    _statusListener = null;
    super.close();
  }
}
