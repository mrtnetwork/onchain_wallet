import 'dart:async';
import 'dart:js_interop';
import 'package:blockchain_utils/crypto/crypto/x25519/x25519.dart';
import 'package:blockchain_utils/utils/atomic/atomic.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_bridge/platform_interface.dart';
import 'package:on_chain_bridge/web/web.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/api/resources.dart';
import 'package:on_chain_wallet/context/api/platform_utils.dart';
import 'package:on_chain_wallet/context/api/utils.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/context/database/main.dart';
import 'package:on_chain_wallet/context/api/api_connection.dart';
import 'package:on_chain_wallet/context/types/channels.dart';
import 'package:on_chain_wallet/context/types/messages.dart';
import 'package:on_chain_wallet/context/web/api/resources.dart';
import 'package:on_chain_wallet/context/web/types/port.dart';
import 'package:on_chain_wallet/context/web/types/types.dart';
import 'package:on_chain_wallet/context/web/worker/types.dart';
import 'package:on_chain_wallet/context/web/worker/worker.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/api/core.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/core/worker.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/cross/web/browser.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/cross/web/utils.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/types.dart';
import 'package:on_chain_wallet/crypto/platform_crypto/api/api.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';

class WorkerAppContextWeb extends AppContext {
  @override
  final DefaultAppDatabase database;
  final WorkerApiWeb worker;
  @override
  final AppBasicCryptoApi cryptoLib;
  @override
  final INetApi netApi;
  @override
  final IPlatformCryptoApi platformCrypto;

  @override
  final IPlatformUtils platformUtls = DisabledPlatformUtils();

  @override
  final AppPlatform platform = AppPlatform.web;

  final LogWriterDefault logWriter;
  final SinkMessageTransform<ISolateMessageRequest<AppContextMessageRequest>,
      WebIsolateEncodedMessage> contextPort;

  @override
  final SafeAtomicLock sync = SafeAtomicLock();

  @override
  final IAppContextConnectionApi connectionApi;
  @override
  final AppResourcesApi resourceApi;

  final SyncWorkerMode? workerMode;
  @override
  final IAppContextUtils utils;

  @override
  IResult<IOnChainBridgeInterface> platformInterface() {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  IResult<AppPath> platformPath() {
    return ResultErr.fromException(
        AppInternalError.internalError("WorkerAppContextWeb.platformPath"));
  }

  WorkerAppContextWeb(
      {required this.netApi,
      required this.worker,
      required this.database,
      required this.cryptoLib,
      required this.platformCrypto,
      required this.logWriter,
      required this.contextPort,
      required this.connectionApi,
      required this.resourceApi,
      required this.workerMode,
      required this.utils}) {
    logWriter.stream.listen((msg) {
      contextPort.send(
          ISolateMessageRequest(id: 0, message: AppContextMessageLoggingRequest(msg)));
    });
  }
  static Future<IResult<WorkerAppContextWeb>> init(
      {required JSMessagePort port, required AppContextConfigWeb config}) async {
    final resourceApi = AppResourceWeb(WebAssetPathResolver(href: config.href));
    // final moduleUrl =
    final receive = StreamMessageTransform<
            ISolateMessageResponse<AppContextMessageResponse>,
            MessageEvent<JSWorkerMessage?>>.broadcast(
        decoder: JSIsolateContextResponseMessageDecoder(), name: "WorkerAppContextWeb");
    port.onmessage = receive.listen.toJS;
    port.start();
    final contextPort = SinkMessageTransform<
            ISolateMessageRequest<AppContextMessageRequest>, WebIsolateEncodedMessage>(
        sink: JSMessageChannelSink(port: port),
        encoder: JSIsolateContextMessageEncoder());
    final PortMessageChannel<ISolateMessageRequest<AppContextMessageRequest>,
            ISolateMessageResponse<AppContextMessageResponse>> connector =
        PortMessageChannel(
            receive: DefaultMessageChannelStream(receive.stream), sink: contextPort);
    final api = AppContextConnectionApi(
        connection: ISolateMessageChannel(
            connector: connector,
            stream: connector.stream.filterMessages([
              AppContextMessageSection.lockingTask,
              AppContextMessageSection.isolateConnection,
            ])));
    final key = X25519Keypair.generate();
    final message = AppContextMessageStablishConnection(key.publicKey);
    final response =
        await api.sendRequest<AppContextMessageStablishConnectionResponse>(message);
    return response.andThenAsync((response) {
      final sharedKey = key * response.contextKey;
      final cryptoConnector = WebCryptoTransporterMain.init(
          sharedKey: sharedKey,
          connector: PortMessageChannel(
              receive: DefaultMessageChannelStream(connector.stream
                  .filterMessage<AppContextMessageCryptoResponseDefault>(
                      AppContextMessageSection.crypto)
                  .map((e) => WebCryptoApiUtils.resolveMessage(
                      e.message.map((e) => e.message), e.id))),
              sink: SinkMessageTransform(
                  sink: DefaultMessageChannelSink(connector.add),
                  encoder: JSCryptoIsolateContextMessageEncoder())));

      final databaseConnector = ISolateMessageChannel<
              ISolateMessageRequest<AppContextMessageDatabaseRequest>,
              ISolateMessageResponse<AppContextMessageDatabaseResponse>>(
          connector: connector,
          stream: connector.stream.filterMessage(AppContextMessageSection.database));
      // final logging = config.loggingMode;
      final logWriter = LogWriterDefault(config.config.mode);
      final workerApi = DisabledWorkerWeb();
      final crypto = IsolateAppBasicCryptoApi.instance(workerApi, cryptoConnector);
      final utils = MainAppContextUtils(
          connection: ISolateMessageChannel<
                  ISolateMessageRequest<AppContextMessageUtilsRequest>,
                  ISolateMessageResponse<AppContextMessageResponse>>(
              connector: connector,
              stream: connector.stream.filterMessage(AppContextMessageSection.utils)));
      return crypto.andThenAsync((crypto) async {
        return ResultOk(WorkerAppContextWeb(
            cryptoLib: crypto,
            worker: workerApi,
            resourceApi: resourceApi,
            workerMode: config.mode,
            connectionApi: api,
            utils: utils,
            platformCrypto: DisabledPlatformCryptoApi(),
            database: DefaultAppDatabase(connector: databaseConnector),
            contextPort: contextPort,
            logWriter: logWriter,
            netApi: DefaultNetApi(DefaultNetSdkApi(DefaultNetSdk(AppEnvironment.web)))));
      });
    });
  }

  @override
  AppContextMode get mode => AppContextMode.background;
}
