import 'package:blockchain_utils/uuid/uuid.dart';
import 'package:on_chain_bridge/models/events/models/wallet_event.dart';
import 'package:on_chain_bridge/platform_interface.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/provider/wallet_provider.dart';
import 'package:on_chain_wallet/wallet/web3/web3.dart';
import 'package:on_chain_wallet/crypto/worker.dart';

mixin Web3RequestControllerImpl on CryptoWokerImpl {
  Future<void> sendMessageToClient(
      Web3EncryptedMessage message, String applicationId);
  Future<void> sendToClient(WalletEvent event);
  Future<Web3ClientInfo?> currentApllicationId();

  WalletCore get walletCore;
  final _lock = SynchronizedLock();
  final Map<String, List<Web3RequestApplicationInformation>> _requets = {};

  Web3ClientInfo? createClientInfos(
      {required String? clientId,
      required String? url,
      required String? title,
      required String? faviIcon}) {
    if (url == null || clientId == null) return null;
    APPImage? image = APPImage.network(faviIcon);
    image ??= APPImage.faviIcon(url);
    return Web3ClientInfo.info(
        clientId: clientId, url: url, faviIcon: image, name: title);
  }

  Future<Web3APPAuthentication?> getCurrentApplication() async {
    final id = await currentApllicationId();
    if (id == null) return null;
    final application = await walletCore.getOrCreateWeb3AppAuthenticated(id);
    return application.result;
  }

  Future<WalletEvent> getPageAuthenticated(
      {required String clientId,
      Web3ClientInfo? info,
      String? additional}) async {
    Web3ExceptionMessage? onException;
    try {
      if (info == null) {
        throw Web3RequestExceptionConst.invalidHost;
      }
      final walletEvent = await walletCore.getWeb3Authenticated(info);
      final message = toResponseEvent(
          data: walletEvent.result.toCbor().encode(),
          id: clientId,
          type: WalletEventTypes.activation,
          platform: PlatformInterface.appPlatform.name,
          additional: additional,
          requestId: '');
      return message;
    } on Web3RequestException catch (e) {
      onException = e.toResponseMessage();
    } catch (e) {
      onException = Web3RequestExceptionConst.internalError.toResponseMessage();
    }
    return toResponseEvent(
        id: clientId,
        type: WalletEventTypes.exception,
        data: onException.message.codeUnits);
  }

  Future<void> onWalletEvent(Web3RequestApplicationInformation request) async {
    _requets[request.applicationId] ??= [];
    _requets[request.applicationId]!.add(request);
    await _doRequest(request);
  }

  WalletEvent toResponseEvent({
    required String id,
    required WalletEventTypes type,
    List<int> data = const [],
    String? requestId,
    String? additional,
    String? platform,
  }) {
    return WalletEvent(
        clientId: id,
        data: data,
        requestId: requestId ?? UUID.generateUUIDv4(),
        type: type,
        additional: additional,
        platform: platform,
        target: WalletEventTarget.wallet);
  }

  void onCloseClinet(String? applicationId) {
    _lock.synchronized(() {
      final List<Web3RequestApplicationInformation> requets =
          _requets[applicationId] ?? [];
      for (final i in requets) {
        i.completeError();
      }
    });
  }

  void _completeRequest(
      Web3RequestApplicationInformation request, WalletEvent event) {
    final r =
        _requets[request.applicationId]?.firstWhereOrNull((e) => e == request);
    final remove = _requets[request.applicationId]?.remove(request);
    assert(remove == true, "request not found ${request.request.requestId}.");
    r?.completeRequest(event);
  }

  void _reject(Web3RequestApplicationInformation request) {
    final r =
        _requets[request.applicationId]?.firstWhereOrNull((e) => e == request);
    final remove = _requets[request.applicationId]?.remove(request);
    assert(remove == true, "request not found.");
    r?.errorRequest();
  }

  Future<void> _doRequest(Web3RequestApplicationInformation request) async {
    await _lock.synchronized(() async {
      if (request.isClosed) {
        throw Web3RejectException.instance;
      }
      WalletEvent response;
      try {
        final result = await walletCore.web3Request(request);
        response = toResponseEvent(
            id: request.request.clientId,
            type: WalletEventTypes.message,
            data: result.result.toCbor().encode(),
            requestId: request.request.requestId);
      } on Web3RejectException {
        _reject(request);
        return;
      } catch (e) {
        Web3ExceptionMessage exception;
        if (e is Web3RequestException) {
          exception = e.toResponseMessage(requestId: request.request.requestId);
        } else {
          exception = Web3RequestExceptionConst.internalError
              .toResponseMessage(requestId: request.request.requestId);
        }
        response = toResponseEvent(
            id: request.request.clientId,
            type: WalletEventTypes.exception,
            data: exception.toCbor().encode(),
            requestId: request.request.requestId);
      }
      _completeRequest(request, response);
    });
  }
}
