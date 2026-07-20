import 'dart:async';
import 'dart:js_interop';

import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:blockchain_utils/uuid/uuid.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_bridge/dev/writer/db.dart';
import 'package:on_chain_bridge/platform_interface.dart';
import 'package:on_chain_bridge/web/api/types/types.dart';
import 'package:on_chain_bridge/web/utils/utils.dart';
import 'package:on_chain_bridge/web/web.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/context/types/worker.dart';
import 'package:on_chain_wallet/context/web/utils/utils.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/constants/const.dart';
import 'package:on_chain_wallet/context/core/sync.dart';
import 'package:on_chain_wallet/context/controller/controller.dart';
import 'package:on_chain_wallet/context/database/sync.dart';
import 'package:on_chain_wallet/context/netsdk/connector.dart';
import 'package:on_chain_wallet/context/types/channels.dart';
import 'package:on_chain_wallet/context/types/messages.dart';
import 'package:on_chain_wallet/context/web/api/resources.dart';
import 'package:on_chain_wallet/context/web/types/types.dart';
import 'package:on_chain_wallet/context/web/types/port.dart';
import 'package:on_chain_wallet/context/web/worker/types.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/api/disabled.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/cross/web/browser.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/messages.dart';

@JS("init_script")
external set init(JSFunction? fn);
@JS("onscriptmessage")
external set onscriptmessage(JSFunction? handler);
@JS("close_script")
external set closeScript(JSFunction? handler);

void appContextExport() {
  init = _init.toJS;
}

Future<ResultOrErrorJs<JSIsolateEncodedMessage, APPJSUint8Array>> initContext(
    JSWorkerMessage? config) async {
  final init = await IsolateAppContextController.init(config);
  return init.fold(
    onErr: (error) => ErrJs<JSIsolateEncodedMessage, APPJSUint8Array>(
        JsUtils.toAppJsUint8Array(error.exception.toCbor().encode())),
    onOk: (value) => OkJs(value),
  );
}

JSPromise<ResultOrErrorJs<JSIsolateEncodedMessage, APPJSUint8Array>> _init(
    JSWorkerMessage? config) {
  return initContext(config).toJS;
}

class IsolateAppContextController {
  final IsolateAppContextMainConnectionControllerWeb mainConnection;
  IsolateAppContextController({required this.mainConnection});
  static Future<IResult<JSIsolateEncodedMessage>> init(JSWorkerMessage? config) async {
    if (config == null) {
      return ResultErr.fromException(AppInternalError.internalError(
          "IsolateAppContextController.init",
          reason: "Missing app context config."));
    }
    final webConfig = config.fold<(AppContextConfigWeb, int)>(
      onMissing: (err) => ResultErr.fromException(AppInternalError.internalError(
          "IsolateAppContextController.init",
          reason: "Missing app context config.",
          interalError: err)),
      fn: (msg) {
        final bytes = msg.config;
        if (bytes == null) return null;
        return ResultOk((AppContextConfigWeb.deserialize(bytes: bytes), msg.id));
      },
    );
    return webConfig.andThenAsync((c) async {
      final (webConfig, id) = c;
      final contextKey = webConfig.contextKey;
      if (contextKey == null) {
        return ResultErr.fromException(AppInternalError.internalError(
            "IsolateAppContextController.init",
            reason: "Missing app context key."));
      }
      final port = StreamMessageTransform<ISolateMessageRequest<AppContextMessageRequest>,
              MessageEvent<JSWorkerMessage?>>.broadcast(
          decoder: JSIsolateContextRequestMessageDecoder(),
          name: "IsolateAppContextController");
      final sendPort = SinkMessageTransform<
              ISolateMessageResponse<AppContextMessageResponse>,
              WebIsolateEncodedMessage>(
          sink: JSMessageChannelSink(port: globalContext as IJSMessagePort),
          encoder: JSIsolateContextMessageEncoder());
      onscriptmessage = port.listen.toJS;

      final connector = PortMessageChannel<
              ISolateMessageResponse<AppContextMessageResponse>,
              ISolateMessageRequest<AppContextMessageRequest>>(
          receive: DefaultMessageChannelStream(port.stream), sink: sendPort);
      // final resource = AppResourceConst.webResources;
      final resourceApi = AppResourceWeb();
      return resourceApi.netSdkRustWasm().andThenAsync((netSdkModule) async {
        final database = IDatabseInterfaceJS(resourceApi.dbName(), instanceId: 1);
        final init = (await database.openDatabase()).toResult();
        return init.andThenAsync((_) async {
          Logging.init(webConfig.config,
              writer: LogWriterDatabase(
                  action: database.storageAction,
                  storage: resourceApi.loggingStorageId(),
                  tableId: resourceApi.loggingTableName(),
                  storageActionId: resourceApi.loggingActionId(),
                  mode: webConfig.config.mode == LoggerMode.debug
                      ? LoggerMode.debug
                      : LoggerMode.error));
          final channel = ISolateMessageChannel<
                  ISolateMessageResponse<AppContextMessageNetSdkResponse>,
                  ISolateMessageRequest<AppContextMessageNetSdkRequest>>(
              connector: connector,
              stream: connector.stream.filterMessage(AppContextMessageSection.netSdk));
          // final backgroundSdk = (await WebNetSdk.rustWasm(NetSdkConfigWebWasm(
          //         config: NetCreateInstanceConfig(
          //             logging: true, mode: webConfig.config.netsdk),
          //         info: netSdkModule,
          //         timeout: const Duration(seconds: 10))))
          //     .transformError(
          //   (error) => NetSdkException(error),
          // );
          final key = X25519Keypair.generate();
          final sharedKey = key * contextKey;
          final sdk = DefaultNetSdk(AppEnvironment.web);
          final netApi = DefaultNetApi(DefaultNetSdkApi(sdk));
          final db = SyncAppDatabase(database);
          final utils = WebAppContextUtils(netApi: netApi, database: db);
          final context = DefaultAppContext(
              path: null,
              utils: utils,
              platform: AppPlatform.web,
              resourceApi: resourceApi,
              database: db,
              mode: AppContextMode.backgroundContextController,
              cryptoLib: DisabledAppBasicCryptoApi(),
              netApi: netApi);

          final instance = IsolateAppContextController(
            mainConnection: IsolateAppContextMainConnectionControllerWeb(
                context: context,
                connector: connector,
                crypto: WebCryptoResponseBuilder(
                    chacha: ChaCha20Poly1305(sharedKey), context: context),
                netsdk: IsolateNetSdkConnector(netSdk: sdk, connector: channel),
                database: database),
          );
          closeScript = instance.onClose.toJS;
          final result = AppContextConfigResponse(contextKey: key.publicKey);
          return ResultOk(JSIsolateEncodedMessage.fromBuffer(
              bytes: result.toCbor().encode(),
              type: IsolateMessageTypes.createMainContext,
              id: id));
          // return ResultOk.okVoid.map((sdkModule) {});
        });
      });
    });
  }

  JSPromise<JSAny?> onClose() {
    return Future.value().toJS;
  }
}

class IsolateAppContextMainConnectionControllerWeb
    extends IsolateAppContextMainConnectionController<
        AppContextMessageCreateConnectionResponse,
        IIsolateCryptoSerializableMessage,
        IsolateAppContextChildConnectionControllerWeb> {
  IsolateAppContextMainConnectionControllerWeb(
      {required super.connector,
      required super.netsdk,
      required super.database,
      required super.context,
      required super.crypto});
  @override
  AppContextMessageCryptoResponse<IIsolateCryptoSerializableMessage> createCryptoResponse(
      IIsolateCryptoSerializableMessage response) {
    return AppContextMessageCryptoResponseDefault(response);
  }

  @override
  Future<IResult<AppContextMessageCreateConnectionResponse>> createConnection() async {
    final jsChannel = JSMessageChannel();
    final port = StreamMessageTransform<ISolateMessageRequest<AppContextMessageRequest>,
            MessageEvent<JSWorkerMessage?>>.broadcast(
        decoder: JSIsolateContextRequestMessageDecoder(),
        name: "IsolateAppContextMainConnectionControllerWeb.createConnection");
    final sendPort = SinkMessageTransform<
            ISolateMessageResponse<AppContextMessageResponse>, WebIsolateEncodedMessage>(
        sink: JSMessageChannelSink(port: jsChannel.port1),
        encoder: JSIsolateContextMessageEncoder());
    jsChannel.port1.onmessage = port.listen.toJS;

    final completer =
        Completer<IResult<(String, IsolateAppContextChildConnectionControllerWeb)>>();
    final id = UUID.generateUUIDv4();
    port.stream.listen((request) async {
      final msg = request.message;
      switch (msg) {
        case AppContextMessageStablishConnection(:final contextKey):
          final key = X25519Keypair.generate();
          final sharedKey = key * contextKey;
          final controller = SafeStreamController<
                  ISolateMessageRequest<AppContextMessageRequest>>.broadcast(
              name: "AppContextMessageStablishConnection");
          final connector = PortMessageChannel<
                  ISolateMessageResponse<AppContextMessageResponse>,
                  ISolateMessageRequest<AppContextMessageRequest>>(
              receive: DefaultMessageChannelStream(port.stream), sink: sendPort);
          final channel = ISolateMessageChannel<
                  ISolateMessageResponse<AppContextMessageNetSdkResponse>,
                  ISolateMessageRequest<AppContextMessageNetSdkRequest>>(
              connector: connector,
              stream: connector.stream
                  .where((e) => switch (e.message) {
                        AppContextMessageNetSdkRequest() => true,
                        _ => false
                      })
                  .map((e) => e.as<AppContextMessageNetSdkRequest>()));
          final backgroundSdk =
              IsolateNetSdkConnector(netSdk: netsdk.netSdk, connector: channel);
          final newConnector = IsolateAppContextChildConnectionControllerWeb(
              connector: connector,
              netsdk: backgroundSdk,
              database: database,
              mainConnection: this,
              crypto: WebCryptoResponseBuilder(
                  chacha: ChaCha20Poly1305(sharedKey), context: context),
              context: context,
              controller: controller);
          final result = await connector.add(ISolateMessageResponse.from(
              request: request,
              response: ResultOk(AppContextMessageStablishConnectionResponse(
                  connectionId: id,
                  modes: [
                    NetMode.clearnet,
                  ],
                  netApiTarget: NetApiTarget.rust,
                  contextKey: key.publicKey))));
          if (result.isErr || completer.isCompleted) {
            newConnector.shutdown();
            return;
          }
          completer.complete(ResultOk((id, newConnector)));
          break;
        default:
          final connector = connections[id];
          if (connector == null) {
            sendPort.send(ISolateMessageResponse.from(
                request: request,
                response: ResultErr<AppContextMessageResponse>.fromException(
                    AppInternalError.internalError("Connection not found."))));
          } else {
            connector.controller.add(request);
            if (request.message case AppContextMessageShutdownRequest(:final connectionId)
                when connectionId == id) {
              port.close();
              return;
            }
          }
          break;
      }
    });
    jsChannel.port1.start();
    completer.future.timeout(
      AppContextConst.defaultConnectionRequestTimeout,
      onTimeout: () {
        if (!completer.isCompleted) {
          completer.complete(ResultErr.fromException(AppExceptionConst.timeout));
        }
        return ResultErr.fromException(AppExceptionConst.timeout);
      },
    ).then((e) {
      if (e.isOk) {
        final (id, connector) = e.unwrap();
        connections[id] = connector;
        return;
      }
      port.close();
    });
    return ResultOk(AppContextMessageCreateConnectionResponse(port: jsChannel.port2));
  }
}

class IsolateAppContextChildConnectionControllerWeb
    extends IsolateAppContextChildConnectionController<
        AppContextMessageCreateConnectionResponse,
        IIsolateCryptoSerializableMessage,
        IsolateAppContextChildConnectionControllerWeb> {
  IsolateAppContextChildConnectionControllerWeb(
      {required super.connector,
      required super.netsdk,
      required super.database,
      required super.controller,
      required super.context,
      required super.crypto,
      required super.mainConnection});
  @override
  AppContextMessageCryptoResponse<IIsolateCryptoSerializableMessage> createCryptoResponse(
      IIsolateCryptoSerializableMessage response) {
    return AppContextMessageCryptoResponseDefault(response);
  }
}
