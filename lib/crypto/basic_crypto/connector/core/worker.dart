import 'dart:async';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/context/core/worker.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/types.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/argruments/argruments.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/api/core.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import '../cross/cross.dart'
    if (dart.library.js_interop) '../cross/web/browser.dart'
    if (dart.library.io) '../cross/native/native.dart';
import 'transporter.dart';

class IsolateAppBasicCryptoApi implements AppBasicCryptoApi {
  const IsolateAppBasicCryptoApi._(this.connector);
  final CryptoWorkerController connector;
  static IResult<IsolateAppBasicCryptoApi> instance(
      AppWorkerApi api, CryptoTransporterMain mainConnector) {
    final connector = getCryptoWorker(api, mainConnector);
    return connector.map((connector) => IsolateAppBasicCryptoApi._(connector));
  }

  @override
  int get maxSyncThread {
    return connector.maxSyncThread;
  }

  Future<IResult<T>> _call<T>(
      {required Future<IResult<T>> Function() onIsolate,
      required FutureOr<IResult<T>> Function() onMain,
      required String method,
      bool useIsolate = true}) async {
    if (!useIsolate) {
      return IResult.block<T>(
        () async => await onMain(),
        onError: (exception, trace) {
          return AppLogData(
              runtime: runtimeType,
              function: "_call",
              msg: "$method request failed: ",
              trace: trace.toString(),
              err: exception);
        },
      );
    }
    return await IResult.block(
      () async => await onIsolate(),
      onError: (exception, trace) {
        return AppLogData(
            runtime: runtimeType,
            function: "_call",
            msg: "$method request failed: ",
            trace: trace.toString(),
            err: exception);
      },
    );
  }

  @override
  Future<IResult<T>> excute<T extends CborTagSerializable>(
    CryptoArgsCompleter<T> message, {
    List<int>? encryptionPart,
    CryptoProcessLevel? level,
  }) async {
    if (encryptionPart != null && message.isEncrypted) {
      return ResultErr.fromException(AppInternalError.internalError("Invalid request"));
    }
    return _call(
        method: message.method.tag.name,
        onIsolate: () async {
          final response = await _sendRequest(
              message: message, encryptPart: encryptionPart, level: level);
          return response.map((e) => message.parsResult(e));
        },
        onMain: () async {
          return ResultErr.fromException(AppInternalError.internalError("excute"));
        },
        useIsolate: true);
  }

  @override
  Future<IResult<T>> excuteSync<T extends CborTagSerializable>(
      {required CryptoArgsCompleter<T> message, required AppContext context}) async {
    return IResult.call(() async => await message.result(context));
  }

  @override
  Future<IResult<StreamCryptoRequestController<T, S>>> excuteStreamRequest<T, S>(
    IsolateStreamRequest<T, S> message, {
    SyncWorkerMode? mode,
  }) async {
    final response = await connector.getStreamConnector(message: message, mode: mode);
    return response.andThenAsync((response) async {
      final streamId = response.id.streamId;
      final mode = response.mode;
      return ResultOk(StreamCryptoRequestController(
        message: message,
        sendMessage: (msg, encryptedPart) =>
            _sendStreamMessage(message: msg, mode: mode, encryptPart: encryptedPart),
        streamId: streamId,
        stream: response.stream.map(message.parsResult),
      ));
    });
  }

  @override
  Future<IResult<T>> excuteWallet<T extends CborTagSerializable>({
    required WalletArgsCompleter<T> message,
    required TransfableMemoryWallet memoryWallet,
    CryptoProcessLevel? level,
  }) async {
    final args =
        WalletArgs<T, WalletArgsCompleter<T>>(args: message, memoryWallet: memoryWallet);
    return _call(
        method: message.method.tag.name,
        onIsolate: () async {
          final response = await _sendRequest(message: args, level: level);
          return response.mapAsync((e) => message.parsResult(e));
        },
        onMain: () async {
          return ResultErr.fromException(AppInternalError.internalError("excuteWallet"));
        },
        useIsolate: true);
  }

  Future<IResult<MessageArgsComplete>> _sendRequest({
    required RequestableMessage message,
    List<int>? encryptPart,
    CryptoProcessLevel? level,
  }) async {
    final connector = await this.connector.getConnector(level: level ?? message.level);
    return await connector.andThenAsync(
        (connector) => connector.getResult(args: message, encryptPart: encryptPart));
  }

  Future<IResult<MessageArgsComplete>> _sendStreamMessage(
      {required MessageArgsStream message,
      required SyncWorkerMode mode,
      List<int>? encryptPart}) async {
    final connector = this.connector.getSyncConnector(mode);
    if (connector == null) {
      return ResultErr.fromException(
          AppCryptoExceptionConst.failedToConnectToCryptoService);
    }
    return connector.getResult(
      args: message,
      encryptPart: encryptPart,
    );
  }
}
