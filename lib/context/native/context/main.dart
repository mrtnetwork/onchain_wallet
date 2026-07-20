import 'dart:async';
import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:blockchain_utils/utils/atomic/atomic.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_bridge/platform_interface.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/api/api_connection.dart';
import 'package:on_chain_wallet/context/api/resources.dart';
import 'package:on_chain_wallet/context/api/platform_utils.dart';
import 'package:on_chain_wallet/context/api/utils.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/context/api/app_setting.dart';
import 'package:on_chain_wallet/context/native/api/resources.dart';
import 'package:on_chain_wallet/context/native/context/controller.dart';
import 'package:on_chain_wallet/context/database/main.dart';
import 'package:on_chain_wallet/context/native/types/channel.dart';
import 'package:on_chain_wallet/context/netsdk/main.dart';
import 'package:on_chain_wallet/context/native/types/types.dart';
import 'package:on_chain_wallet/context/types/channels.dart';
import 'package:on_chain_wallet/context/types/messages.dart';
import 'package:on_chain_wallet/context/native/utils/platform.dart';
import 'package:on_chain_wallet/context/native/worker/worker.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/api/core.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/core/worker.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/cross/native/native.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/cross/native/utils.dart';
import 'package:on_chain_wallet/crypto/platform_crypto/api/api.dart';
import 'package:on_chain_wallet/crypto/platform_crypto/platforms/methods.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';

class DefaultAppContextNative extends MainAppContext {
  @override
  final DefaultAppDatabase database;
  final WorkerApiNative worker;
  @override
  final AppBasicCryptoApi cryptoLib;
  @override
  final INetApi netApi;
  @override
  final IAppSettingApi setting;

  @override
  final IPlatformCryptoApi platformCrypto;

  @override
  final IPlatformUtils platformUtls;
  @override
  final AppPlatform platform;

  @override
  final IAppContextConnectionApi connectionApi;
  @override
  final AppResourcesApi resourceApi;

  final AppPath path;
  final IOnChainBridgeInterface interface;
  @override
  final IAppContextUtils utils;
  final ISolateConnector<ISolateMessageRequest<AppContextMessageRequest>,
      ISolateMessageResponse<AppContextMessageResponse>> conntor;
  // final LogWriter logWriter;

  @override
  final SafeAtomicLock sync = SafeAtomicLock();

  @override
  IResult<IOnChainBridgeInterface> platformInterface() {
    return ResultOk(interface);
  }

  @override
  IResult<AppPath> platformPath() {
    return ResultOk(path);
  }

  DefaultAppContextNative(
      {required this.netApi,
      required this.worker,
      required this.database,
      required this.cryptoLib,
      required this.setting,
      required this.platformCrypto,
      required this.platformUtls,
      required this.platform,
      required this.path,
      required this.interface,
      required this.connectionApi,
      required this.conntor,
      required this.resourceApi,
      required this.utils}) {
    final config = Logging.config;
    Logging.init(config.copyWith(printDebug: false),
        writer: LogWriterDefault(config.mode));
    if (Logging.writer case LogWriterDefault(:var stream)) {
      stream.listen((e) {
        conntor.add(
            ISolateMessageRequest(id: 0, message: AppContextMessageLoggingRequest(e)));
      });
    }
  }
  static Future<IResult<DefaultAppContextNative>> init(AppConfig config) async {
    final resourcesApi = AppResourceNative();
    final platform = PlatformInterface.instance;
    final platformConfig = (await platform.initMain(config)).toResult();
    return platformConfig.andThenAsync((platformConfig) async {
      final path = await platform.path(resourcesApi.applicationId());
      return await path.toResult().andThenAsync((path) async {
        final platformStorage = platform.platformStorage();
        return platformStorage.toResult().andThenAsync((storage) async {
          final key = await storage.readStorage(resourcesApi.dbName());
          final contextKey = X25519Keypair.generate();
          final config = AppContextConfigNative(
              path: path,
              dbKey: key,
              loggingConfig: Logging.config.copyWith(environment: "context"),
              platform: platformConfig.platform,
              contextKey: contextKey.publicKey);
          final result = await DefaultWorkerApiNative.createWorkerStatic<
                  ISolateMessageRequest<AppContextMessageRequest>,
                  ISolateMessageResponse<AppContextMessageResponse>,
                  IsolateNetSdkNativeConfig,
                  AppContextConfigNative>(
              entryPoint: IsolateAppContextController.init,
              param: config,
              config: config);
          return result.andThenAsync((c) async {
            final response = c.response;
            final connector = c.connector;
            if (response.databaseKey != key) {
              await storage.writeSecure(resourcesApi.dbName(), response.databaseKey);
            }
            final netSdkConnector = ISolateMessageChannel<
                    ISolateMessageRequest<AppContextMessageNetSdkRequest>,
                    ISolateMessageResponse<AppContextMessageNetSdkResponse>>(
                connector: connector,
                stream: connector.stream.filterMessage(AppContextMessageSection.netSdk));
            final databaseConnector = ISolateMessageChannel<
                    ISolateMessageRequest<AppContextMessageDatabaseRequest>,
                    ISolateMessageResponse<AppContextMessageDatabaseResponse>>(
                connector: connector,
                stream:
                    connector.stream.filterMessage(AppContextMessageSection.database));
            final api = AppContextConnectionApi(
                connection: ISolateMessageChannel<
                        ISolateMessageRequest<AppContextMessageRequest>,
                        ISolateMessageResponse<AppContextMessageResponse>>(
                    connector: connector,
                    stream: connector.stream.filterMessages([
                      AppContextMessageSection.lockingTask,
                      AppContextMessageSection.isolateConnection,
                    ])));

            final worker = DefaultWorkerApiNative(
                api: api, path: path, platform: platformConfig.platform);

            final shareKey = contextKey * response.contextKey;
            final cryptoConnector = NativeCryptoTransporterMain.init(
                sharedKey: shareKey,
                connector: PortMessageChannel(
                    receive: DefaultMessageChannelStream(connector.stream
                        .filterMessage<AppContextMessageCryptoResponseNative>(
                            AppContextMessageSection.crypto)
                        .map((e) => NativeCryptoApiUtils.resolveMessage(
                            e.message.map((e) => e.message), e.id))),
                    sink: SinkMessageTransform(
                        sink: DefaultMessageChannelSink(connector.add),
                        encoder: NativeCryptoIsolateContextMessageEncoder())));
            final crypto = IsolateAppBasicCryptoApi.instance(worker, cryptoConnector);
            final database = DefaultAppDatabase(connector: databaseConnector);
            final utils = MainAppContextUtils(
                connection: ISolateMessageChannel<
                        ISolateMessageRequest<AppContextMessageUtilsRequest>,
                        ISolateMessageResponse<AppContextMessageResponse>>(
                    connector: connector,
                    stream:
                        connector.stream.filterMessage(AppContextMessageSection.utils)));
            return crypto.andThenAsync((crypto) async {
              final setting = await DefaultAppSettingApi.init(
                  database: database, config: platformConfig);

              return setting.map((setting) {
                return DefaultAppContextNative(
                    setting: setting,
                    interface: platform,
                    resourceApi: resourcesApi,
                    connectionApi: api,
                    platform: platformConfig.platform,
                    utils: utils,
                    path: path,
                    platformUtls: DefaultPlatformUtilsNative(platform),
                    platformCrypto: DefaultPlatformCryptoApi(platform),
                    conntor: connector,
                    cryptoLib: crypto,
                    worker: worker,
                    database: DefaultAppDatabase(connector: databaseConnector),
                    netApi: DefaultNetApi(DefaultNetSdkApi(MainNetSdkConnector(
                        connector: netSdkConnector,
                        modes: response.modes,
                        target: response.target,
                        environment: AppEnvironment.native))));
              });
            });
          });
        });
      });
    });
  }

  @override
  AppContextMode get mode => AppContextMode.main;
}
