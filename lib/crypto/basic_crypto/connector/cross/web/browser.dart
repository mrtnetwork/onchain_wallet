import 'dart:async';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_bridge/models/device/models/platform.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/worker.dart';
import 'package:on_chain_wallet/context/types/channels.dart';
import 'package:on_chain_wallet/context/types/worker.dart';
import 'package:on_chain_wallet/context/web/types/types.dart';
import 'package:on_chain_wallet/context/web/worker/types.dart';
import 'package:on_chain_wallet/context/web/worker/worker.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/controller/message_controller.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/core/transporter.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/messages.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/types.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/argruments/argruments.dart';

import 'codec.dart';

IResult<CryptoWorkerController> getCryptoWorker(
    AppWorkerApi workerApi, CryptoTransporterMain mainConnector) {
  if (workerApi is! WorkerApiWeb || mainConnector is! WebCryptoTransporterMain) {
    return ResultErr.fromException(
        AppInternalError.internalError("getCryptoWorker", reason: "Invalid parameters."));
  }
  return ResultOk(
      CryptoWebWorkerController(api: workerApi, mainConnector: mainConnector));
}

class CryptoWebWorkerController extends CryptoWorkerController<
    IIsolateCryptoSerializableMessage, IIsolateCryptoSerializableMessage> {
  final WorkerApiWeb api;
  @override
  final CryptoTransporterMain<IIsolateCryptoSerializableMessage,
      IIsolateCryptoSerializableMessage> mainConnector;
  CryptoWebWorkerController({required this.api, required this.mainConnector});

  @override
  Future<
          IResult<
              CryptoTransporterMain<IIsolateCryptoSerializableMessage,
                  IIsolateCryptoSerializableMessage>>>
      createMainConnector(CryptoProcessLevel level, {bool fresh = false}) async {
    return api.resourcesApi.cryptoWasm().andThenAsync((wasmModule) async {
      final k = X25519Keypair.generate();
      final init = (await api.createWorker<IIsolateCryptoSerializableMessage,
              IIsolateCryptoSerializableMessage, List<int>>(
          param: WebIsolateEncodedMessage.bytes(
              bytes: k.publicKey, type: IsolateMessageTypes.createCryptoConnector, id: 0),
          wasmModule: wasmModule,
          config: AppContextConfigWeb(
              config: Logging.config.copyWith(environment: "main"), href: api.href),
          decoder: JSIsolateCryptoMessageDecoder(),
          encoder: JSIsolateCryptoMessageEncoder(),
          transferParams: (JSDartWorkerMessage message) {
            final bytes = message.buffer;
            if (bytes != null) return ResultOk(bytes);
            return ResultErr.fromException(AppInternalError.internalError(
                "createMainConnector",
                reason: "Invalid public key"));
          }));
      return init.map((response) {
        final sharedKey = X25519.scalarMult(k.privateKey, response.response);
        return WebCryptoTransporterMain(
            sharedKey: sharedKey, connector: response.connector, level: level);
      });
    });
  }

  @override
  int get maxSyncThread => 3;

  @override
  Future<
      IResult<
          CryptoStreamTransporterMain<IIsolateCryptoSerializableMessage,
              IIsolateCryptoSerializableMessage>>> createStreamConnector(
      SyncWorkerMode mode) async {
    return api.resourcesApi.streamCryptoWasm().andThenAsync((wasmModule) async {
      final k = X25519Keypair.generate();
      final init = (await api.createWorker<IIsolateCryptoSerializableMessage,
              IIsolateCryptoSerializableMessage, List<int>>(
          param: WebIsolateEncodedMessage.bytes(
              bytes: k.publicKey, type: IsolateMessageTypes.createCryptoConnector, id: 0),
          wasmModule: wasmModule,
          decoder: JSIsolateCryptoMessageDecoder(),
          encoder: JSIsolateCryptoMessageEncoder(),
          config: AppContextConfigWeb(
              mode: mode,
              config: Logging.config.copyWith(environment: mode.name),
              href: api.href),
          transferParams: (JSDartWorkerMessage message) {
            final bytes = message.buffer;
            if (bytes != null) return ResultOk(bytes);
            return ResultErr.fromException(AppInternalError.internalError(
                "createStreamConnector",
                reason: "Invalid public key"));
          }));
      return init.map((response) {
        final sharedKey = X25519.scalarMult(k.privateKey, response.response);
        return _StreamWorkerConnection(
            sharedKey: sharedKey,
            connector: response.connector,
            controller: this,
            mode: mode);
      });
    });
  }
}

class WebCryptoTransporterMain extends CryptoTransporterMain<
    IIsolateCryptoSerializableMessage,
    IIsolateCryptoSerializableMessage> with WebIsolateCryptoMessageEncoder {
  static WebCryptoTransporterMain init(
      {required List<int> sharedKey,
      required MessageChannel<IIsolateCryptoSerializableMessage,
              IIsolateCryptoSerializableMessage>
          connector}) {
    return WebCryptoTransporterMain(
        sharedKey: sharedKey, connector: connector, level: CryptoProcessLevel.normal);
  }

  WebCryptoTransporterMain(
      {required super.sharedKey, required super.connector, required super.level});

  @override
  Future<IResult<void>> post(IIsolateCryptoSerializableMessage data) {
    return connector.add(data);
  }

  @override
  AppEnvironment get environment => AppEnvironment.web;
}

class WebCryptoResponseBuilder extends MainCryptoResponseBuilder<
    IIsolateCryptoSerializableMessage,
    IIsolateCryptoSerializableMessage> with WebIsolateCryptoMessageEncoder {
  @override
  final EncryptedIsolateMessageController crypto = EncryptedIsolateMessageController();
  WebCryptoResponseBuilder({required super.chacha, required super.context});

  @override
  IResult<CryptoMessageArgs> decodeMessage(List<int> bytse) {
    return IResult.callSync(
      () => CryptoMessageArgs.deserialize(bytse),
      onError: (exception, trace) {
        return AppLogData(
            runtime: runtimeType,
            trace: trace.toString(),
            err: exception,
            function: "decodeMessage");
      },
    );
  }
}

class _StreamWorkerConnection extends CryptoStreamTransporterMain<
    IIsolateCryptoSerializableMessage,
    IIsolateCryptoSerializableMessage> with WebIsolateCryptoMessageEncoder {
  _StreamWorkerConnection(
      {required super.sharedKey,
      required super.connector,
      required super.controller,
      required super.mode});

  @override
  Future<IResult<void>> post(IIsolateCryptoSerializableMessage data) {
    return connector.add(data);
  }

  @override
  AppEnvironment get environment => AppEnvironment.web;
}
