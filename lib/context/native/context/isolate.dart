import 'dart:async';
import 'dart:isolate';
import 'package:blockchain_utils/crypto/crypto/x25519/x25519.dart';
import 'package:blockchain_utils/utils/atomic/atomic.dart';
import 'package:on_chain_bridge/dev/dev.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_bridge/interface/interface.dart';
import 'package:on_chain_bridge/models/models.dart';
import 'package:on_chain_bridge/native/net_sdk/core/net_sdk.dart';
import 'package:on_chain_bridge/native/net_sdk/types/config.dart';
import 'package:on_chain_bridge/native/utils/utils.dart';
import 'package:on_chain_wallet/context/api/utils.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';
import 'package:on_chain_bridge/net_sdk/core/api.dart';
import 'package:on_chain_bridge/net_sdk/exception/exception.dart';
import 'package:on_chain_bridge/net_sdk/types/config.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/api/resources.dart';
import 'package:on_chain_wallet/context/api/platform_utils.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/context/database/main.dart';
import 'package:on_chain_wallet/context/native/api/resources.dart';
import 'package:on_chain_wallet/context/native/types/channel.dart';
import 'package:on_chain_wallet/context/netsdk/main.dart';
import 'package:on_chain_wallet/context/api/api_connection.dart';
import 'package:on_chain_wallet/context/native/types/types.dart';
import 'package:on_chain_wallet/context/types/channels.dart';
import 'package:on_chain_wallet/context/types/messages.dart';
import 'package:on_chain_wallet/context/native/worker/worker.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/api/core.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/core/worker.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/cross/native/native.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/cross/native/utils.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/types.dart';
import 'package:on_chain_wallet/crypto/platform_crypto/api/api.dart';

class ISolateAppContextNative extends BackgroundAppContext {
  @override
  final DefaultAppDatabase database;
  final WorkerApiNative worker;
  @override
  final AppBasicCryptoApi cryptoLib;
  @override
  final INetApi netApi;
  @override
  final IPlatformCryptoApi platformCrypto;

  @override
  final IPlatformUtils platformUtls = DisabledPlatformUtils();

  @override
  final AppPlatform platform;
  @override
  final String connectionId;

  final AppPath path;
  final SyncWorkerMode? workerMode;

  @override
  final AppResourcesApi resourceApi;
  @override
  final IAppContextConnectionApi connectionApi;
  final LogWriterDefault logWriter;
  final PortMessageChannel<ISolateMessageRequest<AppContextMessageRequest>,
      ISolateMessageResponse<AppContextMessageResponse>> connector;

  @override
  final IAppContextUtils utils;

  @override
  IResult<IOnChainBridgeInterface> platformInterface() {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  @override
  final SafeAtomicLock sync = SafeAtomicLock();

  @override
  IResult<AppPath> platformPath() {
    return ResultOk(path);
  }

  ISolateAppContextNative(
      {required this.netApi,
      required this.worker,
      required this.database,
      required this.cryptoLib,
      required this.platformCrypto,
      required this.platform,
      required this.path,
      required this.logWriter,
      required this.connector,
      required this.connectionId,
      required this.connectionApi,
      required this.resourceApi,
      required this.utils,
      this.workerMode}) {
    logWriter.stream.listen((msg) {
      connector.sink.send(
          ISolateMessageRequest(id: 0, message: AppContextMessageLoggingRequest(msg)));
    });
  }
  static Future<IResult<ISolateAppContextNative>> init({
    required SendPort port,
    required AppContextConfigNative config,
  }) async {
    final resourcesApi = AppResourceNative();
    final ReceivePort receivePort = ReceivePort();
    final contextPort =
        DefaultMessageChannelSink<ISolateMessageRequest<AppContextMessageRequest>>(
            (msg) => port.send(msg));
    final PortMessageChannel<ISolateMessageRequest<AppContextMessageRequest>,
            ISolateMessageResponse<AppContextMessageResponse>> connector =
        PortMessageChannel(
            receive: DefaultMessageChannelStream.broadcast(receivePort),
            sink: contextPort);
    final api = AppContextConnectionApi(
        connection: ISolateMessageChannel<ISolateMessageRequest<AppContextMessageRequest>,
                ISolateMessageResponse<AppContextMessageResponse>>(
            connector: connector,
            stream: connector.stream.filterMessages([
              AppContextMessageSection.lockingTask,
              AppContextMessageSection.isolateConnection,
            ])));
    final key = X25519Keypair.generate();
    final message = AppContextMessageStablishConnectionRequestNative(
        port: receivePort.sendPort, contextKey: key.publicKey);
    final response =
        await api.sendRequest<AppContextMessageStablishConnectionResponse>(message);
    return response.andThen((response) {
      final databaseConnector = ISolateMessageChannel<
              ISolateMessageRequest<AppContextMessageDatabaseRequest>,
              ISolateMessageResponse<AppContextMessageDatabaseResponse>>(
          connector: connector,
          stream: connector.stream.filterMessage(AppContextMessageSection.database));
      final logWriter = LogWriterDefault(config.loggingConfig.mode);
      Logging.init(config.loggingConfig.copyWith(printDebug: false), writer: logWriter);
      final sharedKey = key * response.contextKey;
      final cryptoConnector = NativeCryptoTransporterMain.init(
          sharedKey: sharedKey,
          connector: PortMessageChannel(
              receive: DefaultMessageChannelStream(connector.stream
                  .filterMessage<AppContextMessageCryptoResponseNative>(
                      AppContextMessageSection.crypto)
                  .map((e) => NativeCryptoApiUtils.resolveMessage(
                      e.message.map((e) => e.message), e.id))),
              sink: SinkMessageTransform(
                  sink: DefaultMessageChannelSink(connector.add),
                  encoder: NativeCryptoIsolateContextMessageEncoder())));
      final workerApi =
          DisabledWorkerApiNative(path: config.path, platform: config.platform);
      final crypto = IsolateAppBasicCryptoApi.instance(workerApi, cryptoConnector);

      final utils = MainAppContextUtils(
          connection: ISolateMessageChannel<
                  ISolateMessageRequest<AppContextMessageUtilsRequest>,
                  ISolateMessageResponse<AppContextMessageResponse>>(
              connector: connector,
              stream: connector.stream.filterMessage(AppContextMessageSection.utils)));

      return crypto.andThen((crypto) {
        final mode = config.mode;

        if (mode != null) {
          return resourcesApi.torParamsLocation().andThen((torFolderName) {
            final torConfig = NetConfigTor(
              cacheDir: torFolderName.cacheState.getAbsolutePath(config.path),
              stateDir: torFolderName.mainState.getAbsolutePath(config.path),
            );
            return resourcesApi.netSdkLibName().andThen((e) {
              final netSdkLibName = OnChainBridgeIoUtils.getDynamicLiberaryPath(e);
              if (netSdkLibName == null) {
                return ResultErr.fromException(AppExceptionConst.resourceNotSupported);
              }
              final backgroundSdk = NativeNetSdk.init(
                NetSdkConfigNative(
                  libUri: netSdkLibName,
                  config: NetCreateInstanceConfig(
                      logging: true,
                      torConifg: torConfig,
                      mode: config.loggingConfig.netsdk,
                      instanceId: resourcesApi.netSdkInstanceId(mode)),
                ),
              ).transformError((error) => NetSdkException(error));
              return backgroundSdk.map((sdk) {
                return ISolateAppContextNative(
                    connectionId: response.connectionId,
                    cryptoLib: crypto,
                    connectionApi: api,
                    worker: workerApi,
                    resourceApi: resourcesApi,
                    platformCrypto: DisabledPlatformCryptoApi(),
                    database: DefaultAppDatabase(connector: databaseConnector),
                    path: config.path,
                    platform: config.platform,
                    netApi: DefaultNetApi(DefaultNetSdkApi(sdk)),
                    logWriter: logWriter,
                    utils: utils,
                    connector: connector,
                    workerMode: mode);
              });
            });
          });
        }

        final channel = ISolateMessageChannel<
                ISolateMessageRequest<AppContextMessageNetSdkRequest>,
                ISolateMessageResponse<AppContextMessageNetSdkResponse>>(
            connector: connector,
            stream: connector.stream.filterMessage(AppContextMessageSection.netSdk));
        return ResultOk(ISolateAppContextNative(
            connectionId: response.connectionId,
            resourceApi: resourcesApi,
            cryptoLib: crypto,
            worker: workerApi,
            utils: utils,
            platformCrypto: DisabledPlatformCryptoApi(),
            database: DefaultAppDatabase(connector: databaseConnector),
            path: config.path,
            connectionApi: api,
            platform: config.platform,
            workerMode: mode,
            netApi: DefaultNetApi(DefaultNetSdkApi(MainNetSdkConnector(
                connector: channel,
                modes: response.modes,
                target: response.netApiTarget,
                environment: AppEnvironment.native))),
            logWriter: logWriter,
            connector: connector));
      });
    });
  }

  @override
  Future<void> shutdown() async {
    Logging.debug(
        fn: () => AppLogData(
              runtime: runtimeType,
              function: "shutdown",
              msg: "Connection shutdown",
            ));
    Logging.init(LoggingConfig.debug(printDebug: true));

    if (workerMode != null) {
      await netApi.netSdk().mapAsync((e) async {
        await e.closeInstance();
      });
    }
    await connector.add(ISolateMessageRequest(
        id: 0, message: AppContextMessageShutdownRequest(connectionId)));
    connector.dispose();
  }

  @override
  AppContextMode get mode => AppContextMode.background;
}
