import 'package:blockchain_utils/bip/ecc/keys/ed25519_keys.dart';
import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:on_chain_bridge/web/api/types/types.dart';
import 'package:on_chain_bridge/web/web.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/context/types/channels.dart';
import 'package:on_chain_wallet/context/types/worker.dart';
import 'package:on_chain_wallet/context/web/context/worker.dart';
import 'package:on_chain_wallet/context/web/types/port.dart';
import 'package:on_chain_wallet/context/web/types/types.dart';
import 'package:on_chain_wallet/context/web/utils/js_error.dart';
import 'package:on_chain_wallet/context/web/worker/types.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/controller/controller.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/controller/message_controller.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/controller/stream_message_controller.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/core/transporter.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/messages.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/types.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/argruments/argruments.dart';
import 'dart:js_interop';
import 'codec.dart';

@JS("init_script")
external set init(JSFunction? fn);

@JS("onscriptmessage")
external set onscriptmessage(JSFunction? handler);

@JS("close_script")
external set closeScript(JSFunction? handler);

void stremingCryptoExport() {
  init = initStreamCryptoContext.toJS;
}

void cryptoExport() {
  init = initCryptoContext.toJS;
}

JSPromise<ResultOrErrorJs<JSIsolateEncodedMessage, APPJSUint8Array>>
    initStreamCryptoContext(JSWorkerMessage? config) {
  return _initContextJs(
    config: config,
    create: ({required connector, required context, required sharedKey}) =>
        _StreamingCryptoJs(sharedKey: sharedKey, context: context, connector: connector),
  ).toJS;
}

JSPromise<ResultOrErrorJs<JSIsolateEncodedMessage, APPJSUint8Array>> initCryptoContext(
    JSWorkerMessage? config) {
  return _initContextJs(
    config: config,
    create: ({required connector, required context, required sharedKey}) =>
        _CryptoJs(sharedKey: sharedKey, context: context, connector: connector),
  ).toJS;
}

Future<ResultOrErrorJs<JSIsolateEncodedMessage, APPJSUint8Array>> _initContextJs(
    {required JSWorkerMessage? config,
    required ISolateCryptoWeb Function(
            {required AppContext context,
            required PortMessageChannel<IIsolateCryptoSerializableMessage,
                    IIsolateCryptoSerializableMessage>
                connector,
            required List<int> sharedKey})
        create}) async {
  final result = await _initContext(config: config, create: create);
  return result.toJs(ok: (ok) => ok);
}

Future<IResult<JSIsolateEncodedMessage>> _initContext(
    {required JSWorkerMessage? config,
    required ISolateCryptoWeb Function(
            {required AppContext context,
            required PortMessageChannel<IIsolateCryptoSerializableMessage,
                    IIsolateCryptoSerializableMessage>
                connector,
            required List<int> sharedKey})
        create}) async {
  if (config == null) {
    return ResultErr.fromException(
        AppInternalError.internalError("crypto_initContext", reason: "Missing config"));
  }
  final IResult<(JSMessagePort, AppContextConfigWeb, List<int>, int id)> result =
      config.fold(
    onMissing: (error) => ResultErr.fromException(AppInternalError.internalError(
        "crypto_initContext",
        reason: "Invalid parameters.")),
    fn: (msg) {
      final buffer = msg.buffer;
      final port = msg.port;
      final config = msg.config;
      if (buffer == null ||
          port == null ||
          config == null ||
          buffer.length != Ed25519KeysConst.privKeyByteLen) {
        return null;
      }
      final webConfig = AppContextConfigWeb.deserialize(bytes: config);
      return ResultOk((port, webConfig, buffer, msg.id));
    },
  );

  return result.andThenAsync((params) async {
    final (port, webConfig, key, id) = params;
    final context = await WorkerAppContextWeb.init(port: port, config: webConfig);
    return context.andThenAsync((context) async {
      final k = X25519Keypair.generate();
      final sharedKey = X25519.scalarMult(k.privateKey, key);
      final port = StreamMessageTransform<IIsolateCryptoSerializableMessage,
              MessageEvent<JSWorkerMessage?>>.broadcast(
          name: "_initContext", decoder: JSIsolateCryptoMessageDecoder());
      onscriptmessage = port.listen.toJS;
      final sendPort = SinkMessageTransform<IIsolateCryptoSerializableMessage,
              WebIsolateEncodedMessage>(
          sink: JSMessageChannelSink(port: globalContext as IJSMessagePort),
          encoder: JSIsolateCryptoMessageEncoder());
      final connector = PortMessageChannel<IIsolateCryptoSerializableMessage,
              IIsolateCryptoSerializableMessage>(
          receive: DefaultMessageChannelStream(port.stream), sink: sendPort);
      final instance =
          create(sharedKey: sharedKey, context: context, connector: connector);
      closeScript = instance.onCloseJs.toJS;
      return ResultOk(JSIsolateEncodedMessage.fromBuffer(
          bytes: k.publicKey, type: IsolateMessageTypes.createCryptoConnector, id: id));
    });
  });
}

abstract class ISolateCryptoWeb<MESSAGE extends RequestableMessage>
    extends CryptoTransporterIsolate<IIsolateCryptoSerializableMessage,
        IIsolateCryptoSerializableMessage, MESSAGE> with WebIsolateCryptoMessageEncoder {
  final PortMessageChannel<IIsolateCryptoSerializableMessage,
      IIsolateCryptoSerializableMessage> connector;
  @override
  abstract final IsolateCryptoController<MESSAGE> crypto;
  ISolateCryptoWeb({
    required List<int> sharedKey,
    required super.context,
    required this.connector,
  }) : super(chacha: ChaCha20Poly1305(sharedKey)) {
    connector.stream.listen(onMessage);
  }

  @override
  Future<IResult<void>> add(IIsolateCryptoSerializableMessage msg) async {
    return connector.add(msg);
  }

  @override
  Future<void> onClose() async {
    crypto.close();
    chacha.clean();
  }

  JSPromise<JSAny?> onCloseJs() {
    return onClose().toJS;
  }
}

class _StreamingCryptoJs extends ISolateCryptoWeb<CryptoStreamMessageArgs> {
  @override
  late final StreamIsolateMessageController crypto =
      StreamIsolateMessageController((message, encrypt, id) {
    final encode = encodeMessage(
        request: message.toCbor().encode(), encrypted: encrypt, requestId: id);
    add(encode);
  });

  _StreamingCryptoJs({
    required super.sharedKey,
    required super.context,
    required super.connector,
  });

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

class _CryptoJs extends ISolateCryptoWeb<CryptoMessageArgs> {
  @override
  late final EncryptedIsolateMessageController crypto =
      EncryptedIsolateMessageController();

  _CryptoJs({required super.sharedKey, required super.context, required super.connector});

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
