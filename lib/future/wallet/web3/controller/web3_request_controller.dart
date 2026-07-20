import 'dart:async';

import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/atomic/atomic.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/uuid/uuid.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_bridge/models/models.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/web3/types/types.dart';
import 'package:on_chain_wallet/wallet/models/others/models/wallet.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/web3.dart';

mixin Web3RequestControllerImpl {
  AppWalletController get walletCore;
  final StreamValue<LastWeb3ActiveClient> latestClient =
      StreamValue(const LastWeb3ActiveClient(), name: "Web3RequestControllerImpl");
  final _lock = SafeAtomicLock();
  List<Web3ActiveClient> get clients => _keys.values.toList();
  final Map<String, Web3ActiveClient> _keys = {};
  final Map<String, List<Web3RequestApplicationInformation>> _clientsRequests = {};
  Future<void> sendMessageToClient(
      {required Web3ActiveClient client, required Web3EncryptedMessage message});

  Web3ClientInfo? createClientInfos(
      {required String? clientId,
      required String? url,
      required String? title,
      required String? faviIcon}) {
    if (url == null || clientId == null) return null;
    APPImage? image = APPImage.network(faviIcon);
    image ??= APPImage.faviIcon(url);
    return Web3ClientInfo.info(url: url, faviIcon: image, name: title);
  }

  JSWalletEventDart toResponseEvent({
    required String id,
    required WalletEventTypes type,
    List<int> data = const [],
    String? requestId,
    String? additional,
    String? platform,
  }) {
    return JSWalletEventDart(
        clientId: id,
        data: data,
        requestId: requestId ?? UUID.generateUUIDv4(),
        type: type,
        additional: additional,
        platform: platform,
        target: WalletEventTarget.wallet);
  }

  Future<Web3ActiveClient> getEncryptionKey(
      {required String clientId,
      required String identifier,
      required Web3ClientInfo client,
      Web3DappInfo? dappInfo}) async {
    if (_keys.containsKey(clientId)) {
      return _keys[clientId]!;
    }
    Web3APPAuthenticationKey? auth = dappInfo?.authentication.token;
    if (auth == null) {
      final appAuth =
          await walletCore.doAction(WalletActionWeb3DappAuthenticated(client: client));
      auth = appAuth.unwrap().token;
    }
    _keys[clientId] = Web3ActiveClient(
        client: client,
        identifier: identifier,
        clientId: clientId,
        selfPublicKey: BytesUtils.toHexString(auth.publicKey),
        sharedKey:
            X25519.scalarMult(auth.privateKey, BytesUtils.fromHexString(clientId)));
    return _keys[clientId]!;
  }

  Future<Web3PageAuthenticatedResponse> createPageAuthenticated({
    required String peerKey,
    required String identifier,
    Web3ClientInfo? info,
  }) async {
    Web3ExceptionMessage? onException;
    Web3ActiveClient? key;
    try {
      if (info == null) {
        throw Web3RequestExceptionConst.invalidHost;
      }
      final auth = await walletCore.doAction(WalletActionWeb3Dapp(client: info));
      final authMessage = Web3ChainMessage(authenticated: auth.unwrap().dappData);
      key = await getEncryptionKey(
          clientId: peerKey,
          client: info,
          identifier: identifier,
          dappInfo: auth.unwrap());
      final encryptMessage = key.encrypt(authMessage);
      final event = toResponseEvent(
          data: encryptMessage.toCbor().encode(),
          id: peerKey,
          type: WalletEventTypes.activation,
          platform: walletCore.config.context.platform.name,
          additional: key.selfPublicKey,
          requestId: '');
      return Web3PageAuthenticatedResponse(event: event, client: key);
    } on Web3RequestException catch (e) {
      onException = e.toResponseMessage();
    } catch (e) {
      onException = Web3RequestExceptionConst.fromException(IExceptionUtils.findError(e))
          .toResponseMessage();
    }
    final event = toResponseEvent(
        id: peerKey,
        type: WalletEventTypes.exception,
        data: onException.toCbor().encode());
    return Web3PageAuthenticatedResponse(event: event, client: key);
  }

  Future<void> updateApplicationAuthenticated(ONUPDATEWEB3PERMISSION onUpdate) async {
    final currentApp = latestClient.value.client;
    if (currentApp == null) return;
    final dapp = await walletCore
        .doAction(WalletActionWeb3DappAuthenticated(client: currentApp.client));
    final request = Web3UpdatePermissionRequest(
        authentication: dapp.unwrap(), client: currentApp.client);
    onUpdate(
      request,
      (update) async {
        final msg = Web3ChainMessage(authenticated: update.appInfo.dappData);
        final encrypted = currentApp.encrypt(msg);
        await sendMessageToClient(message: encrypted, client: currentApp);
        return false;
      },
    );
  }

  Future<void> onRequest(
      {required JSWalletEventDart request,
      required String? identifier,
      required String? url,
      required String? title,
      required String? image,
      required Completer<JSWalletEventDart?> completer}) async {
    await _lock.run(() async {
      Web3ActiveClient key;
      Web3MessageCore? message;
      Web3ClientInfo? client;
      try {
        client = createClientInfos(
            clientId: request.clientId, url: url, faviIcon: image, title: title);
        if (client == null) throw Web3RequestExceptionConst.invalidHost;
        if (identifier == null) throw Web3RequestExceptionConst.invalidRequest;
        key = await getEncryptionKey(
            client: client, identifier: identifier, clientId: request.clientId);
        final decryptedMessage = key.decrypt(request.data);
        message = Web3MessageCore.deserialize(bytes: decryptedMessage);
        if (decryptedMessage == null) {
          throw Web3RequestExceptionConst.missingPermission;
        }
      } catch (e, trace) {
        final exception =
            Web3RequestExceptionConst.fromException(IExceptionUtils.findError(e))
                .toResponseMessage();
        completer.complete(toResponseEvent(
            id: request.clientId,
            type: WalletEventTypes.exception,
            data: exception.toCbor().encode(),
            requestId: request.requestId));
        Logging.error(
            fn: () => AppLogData(
                  runtime: runtimeType,
                  function: "onRequest",
                  err: e,
                  trace: trace.toString(),
                  msg: "Web3 request deserialization failed:",
                ));
        return;
      }
      final walletRequest = Web3RequestApplicationInformation(
          message: message,
          requestId: request.requestId,
          applicationId: client.identifier,
          client: client);
      _clientsRequests[request.clientId] ??= [];
      _clientsRequests[request.clientId]?.add(walletRequest);
      try {
        final result =
            await walletCore.doAction(WalletActionWeb3Request(request: walletRequest));

        JSWalletEventDart event = toResponseEvent(
            id: request.clientId,
            type: WalletEventTypes.message,
            data: key.encrypt(result.unwrap()).toCbor().encode(),
            requestId: request.requestId);
        completer.complete(event);
      } on Web3RequestClosed {
        completer.complete(null);
      } catch (e, trace) {
        final exception =
            Web3RequestExceptionConst.fromException(IExceptionUtils.findError(e))
                .toResponseMessage();
        final event = toResponseEvent(
            id: request.clientId,
            type: WalletEventTypes.message,
            data: key.encrypt(exception).toCbor().encode(),
            requestId: request.requestId);
        completer.complete(event);
        Logging.error(
            fn: () => AppLogData(
                  runtime: runtimeType,
                  function: "onRequest",
                  err: e,
                  trace: trace.toString(),
                  msg: "Web3 request failed:",
                ));
      }
    });
  }

  void completeRequest({
    required String clientId,
    required String requestId,
    required bool result,
  }) {
    final clientRequests = _clientsRequests[clientId];
    final r = clientRequests?.firstWhereNullable((e) => e.requestId == requestId);
    if (r == null) return;
    clientRequests?.remove(r);
    if (result) {
      r.completeSuccess();
    } else {
      r.completeError();
    }
  }

  void onWeb3ClinetDisconnected(Web3ActiveClient? client) {
    if (client == null) return;
    final clientRequests = [
      ..._clientsRequests[client.clientId] ?? <Web3RequestApplicationInformation>[]
    ];
    for (final i in clientRequests) {
      completeRequest(clientId: client.clientId, requestId: i.requestId, result: false);
    }
  }

  void onWeb3ClientRemoved(String? identifier) {
    if (identifier == null) return;
    _keys.removeWhere((k, v) => v.identifier == identifier);
  }

  Future<void> onWalletEvent(WalletEvent event) async {
    if (!event.status.isSuccess) return;
    switch (event.action) {
      case WalletActionEventType.removeWallet:
      case WalletActionEventType.switchWallet:
      case WalletActionEventType.removeAccount:
      case WalletActionEventType.setup:
      case WalletActionEventType.importNetwork:
        final clients = this.clients.clone();
        for (final i in clients) {
          final dapps = await walletCore.doAction(WalletActionWeb3Dapp(client: i.client));
          if (dapps.isErr) continue;
          final message = Web3ChainMessage(authenticated: dapps.unwrap().dappData);
          sendMessageToClient(client: i, message: i.encrypt(message));
        }
        break;
      default:
    }
  }

  bool clientExists(Web3DappInfo dappData) {
    return clients.any((e) => e.client.identifier == dappData.clientInfo.identifier);
  }

  Future<void> updateClientAuthenticated(Web3DappInfo dappData) async {
    final clients = this.clients.clone();
    final relatedClients =
        clients.where((e) => e.client.identifier == dappData.clientInfo.identifier);
    for (final i in relatedClients) {
      final message = Web3ChainMessage(authenticated: dappData.dappData);
      sendMessageToClient(client: i, message: i.encrypt(message));
    }
  }
}
