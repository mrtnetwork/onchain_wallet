import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/network/bridge/controller/pairing.dart';
import 'package:on_chain_wallet/network/bridge/controller/seashion.dart';
import 'package:on_chain_wallet/network/bridge/exception/exception.dart';
import 'package:on_chain_wallet/network/bridge/types/bridge/client.dart';
import 'package:on_chain_wallet/network/bridge/types/server/types.dart';
import 'package:on_chain_wallet/network/bridge/controller/event.dart';
import 'package:on_chain_wallet/network/bridge/controller/socket.dart';
import 'package:on_chain_wallet/network/bridge/core/core.dart';
import 'package:on_chain_wallet/network/bridge/types/bridge/socket.dart';
import 'package:on_chain_wallet/network/bridge/types/bridge/types.dart';
import 'package:on_chain_wallet/network/bridge/onchain/types/types.dart';
import 'package:on_chain_wallet/network/bridge/types/bridge/topic_message.dart';
import 'package:on_chain_wallet/network/bridge/types/wallet_connect/types.dart';
import 'package:on_chain_wallet/network/bridge/utils/utils.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/crypto/requests/chacha.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/crypto/requests/jwt.dart';

typedef TypeCbGetBridgeSession = Future<IBridgeSession?> Function(String topic);

///
class BridgeClientDefault extends IBridgeCore
    with
        IBridgePairingController,
        IBridgeSesshionController,
        IBridgeEventController,
        IBridgeSocketController
    implements IBridgeClient {
  final BridgeClientConfig config;
  final TypeCbGetBridgeSession onGetSession;
  @override
  AppContext get context => config.context;
  BridgeClientDefault({required this.onGetSession, required this.config});

  @override
  Future<List<int>?> decryptMessage(
      {required List<int> message,
      required List<int> key,
      required List<int> nonce}) async {
    final decode = await context.cryptoLib.excuteSync(
        message: CryptoRequestDecryptChacha(message: message, key: key, nonce: nonce),
        context: context);
    return decode.fold(
      onOk: (value) => value.decrypted,
      onErr: (error) {
        if (error.exception == WalletExceptionConst.decryptionFailed) return null;
        throw error.exception;
      },
    );
  }

  @override
  Future<List<int>> encryptMessage(
      {required List<int> message,
      required List<int> key,
      required List<int> nonce}) async {
    final encrypt = await context.cryptoLib.excuteSync(
        message: CryptoRequestEncryptChacha(message: message, key: key, nonce: nonce),
        context: context);
    return encrypt.unwrap().encrypted;
  }

  @override
  void onReponseMessage(TopicMessageResponse message) {}

  @override
  Future<IResult<BridgeServerUrl>> generateUrl(BridgeProtocol protocol) async {
    final uri = Uri.parse(config.wcBridgeUrl);
    final cryptoRequest = CryptoRequestGenerateJwt(
        aud: Uri(host: uri.host, scheme: uri.scheme).normalizePath().toString());
    final jwt = await context.cryptoLib.excute(cryptoRequest);
    return jwt.map((jwt) {
      final uri = BridgeUtils.wcGenerateRelayUrl(
          relayUrl: config.wcBridgeUrl, auth: jwt.data, projectId: config.wcProjectId);

      return BridgeServerUrl(url: uri, expire: cryptoRequest.expiry);
    });
  }

  @override
  Future<IBridgeSession?> getSession(String topic) async {
    final session = await super.getSession(topic);
    if (session == null) return onGetSession(topic);
    return session;
  }

  @override
  Future<IResult<RESPONSE>> sendRequestAndGetResponse<RESPONSE extends Object?>(
      {required IBrdigeAction<RESPONSE> action,
      PublishMessageStorageType? storage,
      String? topic,
      IBridgeSession? session,
      int? fixedId}) async {
    if (topic == null && session == null) {
      return ResultErr.fromException(BridgeExceptionConst.clientNotFound);
    }
    session ??= await getSession(topic!);
    if (session == null) {
      return ResultErr.fromException(BridgeExceptionConst.clientNotFound);
    }
    final message = BridgeRequestMessage.action(
        action: action,
        fixedId: fixedId,
        session: session,
        mode: PublishMessageMode.publishAndResult,
        storage: storage);
    final result = await publish(message);
    return result.map<RESPONSE>((e) => action.onResponse(e));
  }

  @override
  Future<IResult<RESPONSE?>> sendOnChainRequest<RESPONSE extends Object?>({
    required WCMAction<RESPONSE> action,
    String? topic,
    IBridgeSession? session,
  }) async {
    if (topic == null && session == null) {
      return ResultErr.fromException(BridgeExceptionConst.clientNotFound);
    }
    session ??= await getSession(topic!);
    if (session == null) {
      return ResultErr.fromException(BridgeExceptionConst.clientNotFound);
    }
    final message = BridgeRequestMessage.action(
        action: action,
        fixedId: action.requestId,
        session: session,
        mode: action.mode,
        storage: action.storageType);
    final result = await publish(message);
    return result.map<RESPONSE?>((e) {
      if (action.mode.requiredResult) {
        return action.onResponse(e);
      }
      return null;
    });
  }

  @override
  Future<IResult<RESPONSE>> sendOnChainRequestAndGetResult<RESPONSE extends Object?>({
    required WCMAction<RESPONSE> action,
    String? topic,
    IBridgeSession? session,
  }) async {
    if (topic == null && session == null) {
      return ResultErr.fromException(BridgeExceptionConst.clientNotFound);
    }
    session ??= await getSession(topic!);
    if (session == null) {
      return ResultErr.fromException(BridgeExceptionConst.clientNotFound);
    }
    assert(
        action.mode == PublishMessageMode.publishAndResult, "Bad action publish mode.");
    final message = BridgeRequestMessage.action(
        action: action,
        fixedId: action.requestId,
        session: session,
        mode: PublishMessageMode.publishAndResult,
        storage: action.storageType);
    final result = await publish(message);
    return result.map<RESPONSE>((e) => action.onResponse(e));
  }

  @override
  Future<IResult<bool?>> sendWeb3Request(
      {required WCAction action,
      String? topic,
      IBridgeSession? session,
      PublishMessageMode mode = PublishMessageMode.publish,
      PublishMessageStorageType? storage}) async {
    if (topic == null && session == null) {
      return ResultErr.fromException(BridgeExceptionConst.clientNotFound);
    }
    session ??= await getSession(topic!);
    if (session == null) {
      return ResultErr.fromException(BridgeExceptionConst.clientNotFound);
    }
    final message = BridgeRequestMessage.action(
        action: action, fixedId: null, session: session, mode: mode, storage: storage);
    final result = await publish(message);
    return result.map((e) {
      if (mode.requiredResult) {
        return action.onResponse(e);
      }
      return null;
    });
  }

  @override
  Future<void> dispose({List<BridgeProtocol> protocols = BridgeProtocol.values}) async {
    await super.dispose(protocols: protocols);
  }
}
