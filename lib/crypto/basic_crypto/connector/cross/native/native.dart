import 'dart:async';
import 'dart:isolate';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/dev/dev.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_bridge/models/device/models/platform.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/context/core/worker.dart';
import 'package:on_chain_wallet/context/native/types/types.dart';
import 'package:on_chain_wallet/context/native/worker/worker.dart';
import 'package:on_chain_wallet/context/types/channels.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/controller/controller.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/controller/message_controller.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/controller/stream_message_controller.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/core/transporter.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/messages.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/types.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/argruments/argruments.dart';

import 'types.dart';

IResult<CryptoWorkerController> getCryptoWorker(
    AppWorkerApi workerApi, CryptoTransporterMain mainConnector) {
  if (workerApi is! WorkerApiNative || mainConnector is! NativeCryptoTransporterMain) {
    return ResultErr.fromException(
        AppInternalError.internalError("getCryptoWorker", reason: "Invalid parameters."));
  }
  return ResultOk(
      CryptoNativeWorkerController(workerApi: workerApi, mainConnector: mainConnector));
}

class CryptoNativeWorkerController extends CryptoWorkerController<
    IIsolateCryptoMessageNative, IIsolateCryptoMessageNative> {
  final WorkerApiNative workerApi;
  @override
  final NativeCryptoTransporterMain mainConnector;
  // final   CryptoTransporterMain<READ, WRITE> mainControlle;
  CryptoNativeWorkerController({required this.workerApi, required this.mainConnector});

  @override
  Future<
      IResult<
          CryptoTransporterMain<IIsolateCryptoMessageNative,
              IIsolateCryptoMessageNative>>> createMainConnector(CryptoProcessLevel level,
      {bool fresh = false}) async {
    final k = X25519Keypair.generate();
    final connector = await workerApi.createWorker<IIsolateCryptoMessageNative,
        IIsolateCryptoMessageNative, List<int>, _WorkerMessage>(
      entryPoint: _CryptoWorkerBackgroud.init,
      param: _WorkerMessage(pk: k.publicKey),
      config: AppContextConfigNative(
        path: workerApi.path,
        loggingConfig: Logging.config.copyWith(environment: "crypto_main"),
        platform: workerApi.platform,
      ),
    );
    return connector.map((connector) {
      final sharedkey = X25519.scalarMult(k.privateKey, connector.response);
      return NativeCryptoTransporterMain(
          sharedKey: sharedkey, connector: connector.connector, level: level);
    });
  }

  @override
  Future<
      IResult<
          CryptoStreamTransporterMain<IIsolateCryptoMessageNative,
              IIsolateCryptoMessageNative>>> createStreamConnector(
      SyncWorkerMode mode) async {
    final k = X25519Keypair.generate();
    final connector = await workerApi.createWorker<IIsolateCryptoMessageNative,
        IIsolateCryptoMessageNative, List<int>, _WorkerMessage>(
      entryPoint: _CryptoStreamingWorkerBackgroud.init,
      param: _WorkerMessage(pk: k.publicKey),
      config: AppContextConfigNative(
        path: workerApi.path,
        loggingConfig: Logging.config.copyWith(environment: "crypto_${mode.name}"),
        mode: mode,
        platform: workerApi.platform,
      ),
    );
    return connector.map((connector) {
      final sharedkey = X25519.scalarMult(k.privateKey, connector.response);
      return _StreamWorkerConnection(
          sharedKey: sharedkey,
          connector: connector.connector,
          mode: mode,
          controller: this);
    });
  }

  @override
  int get maxSyncThread => 6;
}

abstract mixin class _NativeIsolateCryptoMessageEncoder {
  ChaCha20Poly1305 get chacha;
  IsolateCryptoEncryptedMessageNative toEncryptedMessage(List<int> message, int id) {
    final nonce = QuickCrypto.generateRandom(16);
    final enc = chacha.encrypt(nonce, message);
    return IsolateCryptoEncryptedMessageNative(
        message: TransferableTypedData.fromList([QuickBytesUtils.asUint8List(enc)]),
        nonce: TransferableTypedData.fromList([QuickBytesUtils.asUint8List(nonce)]),
        id: id);
  }

  IIsolateCryptoMessageNative encodeMessage(
      {required List<int> request,
      required bool encrypted,
      required int requestId,
      List<int>? encryptedPart}) {
    if (encrypted) {
      return toEncryptedMessage(request, requestId);
    }
    return IsolateCryptoMessageNative(
        message: TransferableTypedData.fromList([QuickBytesUtils.asUint8List(request)]),
        id: requestId,
        encryptedPart:
            encryptedPart == null ? null : toEncryptedMessage(encryptedPart, requestId));
  }
}

class NativeCryptoRequestBuilder extends CryptoRequestBuilder<IIsolateCryptoMessage,
    IIsolateCryptoMessage, RequestableMessage> with _NativeIsolateCryptoMessageEncoder {
  NativeCryptoRequestBuilder({required super.chacha});
}

class NativeCryptoTransporterMain extends CryptoTransporterMain<
    IIsolateCryptoMessageNative,
    IIsolateCryptoMessageNative> with _NativeIsolateCryptoMessageEncoder {
  NativeCryptoTransporterMain(
      {required super.sharedKey, required super.connector, required super.level});
  static NativeCryptoTransporterMain init(
      {required List<int> sharedKey,
      required MessageChannel<IIsolateCryptoMessageNative, IIsolateCryptoMessageNative>
          connector}) {
    return NativeCryptoTransporterMain(
        sharedKey: sharedKey, connector: connector, level: CryptoProcessLevel.normal);
  }

  @override
  AppEnvironment get environment => AppEnvironment.native;
}

class _StreamWorkerConnection extends CryptoStreamTransporterMain<
    IIsolateCryptoMessageNative,
    IIsolateCryptoMessageNative> with _NativeIsolateCryptoMessageEncoder {
  _StreamWorkerConnection(
      {required super.sharedKey,
      required super.connector,
      required super.mode,
      required super.controller});

  @override
  AppEnvironment get environment => AppEnvironment.native;
}

class NativeCryptoResponseBuilder extends MainCryptoResponseBuilder<
    IIsolateCryptoMessageNative,
    IIsolateCryptoMessageNative> with _NativeIsolateCryptoMessageEncoder {
  @override
  final EncryptedIsolateMessageController crypto = EncryptedIsolateMessageController();
  NativeCryptoResponseBuilder({required super.chacha, required super.context});

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

abstract class ISolateCryptoNative<MESSAGE extends RequestableMessage>
    extends CryptoTransporterIsolate<IIsolateCryptoMessage, IIsolateCryptoMessage,
        MESSAGE> with _NativeIsolateCryptoMessageEncoder {
  final MessageChannel<IIsolateCryptoMessage, IIsolateCryptoMessage> connector;
  @override
  abstract final IsolateCryptoController<MESSAGE> crypto;
  ISolateCryptoNative({
    required List<int> sharedKey,
    required super.context,
    required this.connector,
  }) : super(chacha: ChaCha20Poly1305(sharedKey)) {
    connector.stream.listen(onMessage);
  }

  @override
  Future<IResult<void>> add(IIsolateCryptoMessage msg) async {
    return connector.add(msg);
  }

  @override
  Future<void> onClose() async {
    Logging.debug(
        fn: () => AppLogData(
            runtime: runtimeType,
            function: "onClose",
            msg: "Isolate terminated ${Isolate.current.debugName}"));
    crypto.close();
  }
}

class _CryptoStreamingWorkerBackgroud
    extends ISolateCryptoNative<CryptoStreamMessageArgs> {
  @override
  late final StreamIsolateMessageController crypto =
      StreamIsolateMessageController((message, encrypt, id) {
    final encrypted = encodeMessage(
        request: message.toCbor().encode(), encrypted: encrypt, requestId: id);
    connector.add(encrypted);
  });
  _CryptoStreamingWorkerBackgroud(
      {required super.sharedKey, required super.context, required super.connector});

  static Future<IResult<(List<int>, IOISOLATECLOSE)>> init(
      _WorkerMessage config,
      MessageChannel<IIsolateCryptoMessageNative, IIsolateCryptoMessageNative> connector,
      AppContext? context) async {
    if (context == null) {
      return ResultErr.fromException(AppInternalError.internalError(
          "_CryptoWorkerBackgroud",
          reason: "Missing app context"));
    }
    final key = X25519Keypair.generate();
    final sharedKey = X25519.scalarMult(key.privateKey, config.pk);
    final instance = _CryptoStreamingWorkerBackgroud(
        sharedKey: sharedKey, connector: connector, context: context);
    return ResultOk((key.publicKey, instance.onClose));
  }

  @override
  IResult<CryptoStreamMessageArgs> decodeMessage(List<int> bytse) {
    return IResult.callSync(
      () => CryptoStreamMessageArgs.deserialize(bytse),
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

class _CryptoWorkerBackgroud extends ISolateCryptoNative<CryptoMessageArgs> {
  @override
  final EncryptedIsolateMessageController crypto = EncryptedIsolateMessageController();
  _CryptoWorkerBackgroud(
      {required super.sharedKey, required super.context, required super.connector});

  static Future<IResult<(List<int>, IOISOLATECLOSE)>> init(
      _WorkerMessage config,
      MessageChannel<IIsolateCryptoMessageNative, IIsolateCryptoMessageNative> connector,
      AppContext? context) async {
    if (context == null) {
      return ResultErr.fromException(AppInternalError.internalError(
          "_CryptoWorkerBackgroud",
          reason: "Missing app context"));
    }
    final key = X25519Keypair.generate();
    final sharedKey = X25519.scalarMult(key.privateKey, config.pk);
    final instance = _CryptoWorkerBackgroud(
        sharedKey: sharedKey, connector: connector, context: context);
    return ResultOk((key.publicKey, instance.onClose));
  }

  @override
  Future<void> onClose() async {}

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

class _WorkerMessage {
  final List<int> pk;
  const _WorkerMessage({required this.pk});
}
