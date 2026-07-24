import 'dart:async';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_bridge/platform_interface.dart';
import 'package:on_chain_bridge/utils/utils.dart';
import 'package:on_chain_bridge/web/api/window/window.dart';
import 'package:on_chain_bridge/web/interface/interface.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/api/api_connection.dart';
import 'package:on_chain_wallet/context/api/resources.dart';
import 'package:on_chain_wallet/context/api/platform_utils.dart';
import 'package:on_chain_wallet/context/api/utils.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/context/api/app_setting.dart';
import 'package:on_chain_wallet/context/database/main.dart';
import 'package:on_chain_wallet/context/types/channels.dart';
import 'package:on_chain_wallet/context/types/messages.dart';
import 'package:on_chain_wallet/context/types/worker.dart';
import 'package:on_chain_wallet/context/web/api/resources.dart';
import 'package:on_chain_wallet/context/web/types/types.dart';
import 'package:on_chain_wallet/context/web/types/port.dart';
import 'package:on_chain_wallet/context/web/utils/platform.dart';
import 'package:on_chain_wallet/context/web/worker/types.dart';
import 'package:on_chain_wallet/context/web/worker/worker.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/api/core.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/core/worker.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/cross/web/browser.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/cross/web/utils.dart';
import 'package:on_chain_wallet/crypto/platform_crypto/api/api.dart';
import 'package:on_chain_wallet/crypto/platform_crypto/platforms/methods.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';

class DefaultAppContextWeb extends MainAppContext {
  @override
  final DefaultAppDatabase database;
  final WorkerApiWeb worker;
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

  final IOnChainBridgeInterface interface;
  @override
  final AppResourcesApi resourceApi;

  @override
  final IAppContextConnectionApi connectionApi;

  @override
  final IAppContextUtils utils;
  @override
  final SafeAtomicLock sync = SafeAtomicLock();
  @override
  IResult<IOnChainBridgeInterface> platformInterface() {
    return ResultOk(interface);
  }

  @override
  IResult<AppPath> platformPath() {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }

  DefaultAppContextWeb(
      {required this.netApi,
      required this.worker,
      required this.database,
      required this.cryptoLib,
      required this.setting,
      required this.platformCrypto,
      required this.platformUtls,
      required this.platform,
      required this.interface,
      required this.connectionApi,
      required this.resourceApi,
      required this.utils});
  static Future<IResult<DefaultAppContextWeb>> init(AppConfig config) async {
    final platform = PlatformInterface.instance as IWebOnChainBridgeInterface;
    String flutterHref = "";
    if (!platform.isExtensionContext) {
      final Uri href = Uri.parse(jsWindow.location.href);
      final segments = href.pathSegments;
      if (segments.isNotEmpty) {
        flutterHref =
            "/${OnChainBridgeUtils.joinPathWithRoot(segments, separator: "/")}/";
      }
    }
    final resourceApi = AppResourceWeb(WebAssetPathResolver(
        href: flutterHref, isExtension: platform.isExtensionContext));
    final contextUrl = resourceApi.contextModule();
    return contextUrl.andThenAsync((contextUrl) async {
      final platformConfig = (await platform.initMain(config)).toResult();

      return platformConfig.andThenAsync((platformConfig) async {
        final contextKey = X25519Keypair.generate();
        final config = AppContextConfigWeb(
            config: Logging.config.copyWith(environment: "context"),
            contextKey: contextKey.publicKey,
            href: resourceApi.resolver.href);
        final result = await DefaultWorkerApiWeb.createWorkerStatic<
                ISolateMessageRequest<AppContextMessageRequest>,
                ISolateMessageResponse<AppContextMessageResponse>,
                AppContextConfigResponse>(
            config: config,
            resourceApi: resourceApi,
            transferParams: (JSDartWorkerMessage message) {
              final buffer = message.buffer;
              if (buffer == null) {
                return ResultErr.fromException(AppInternalError.internalError(
                    "createMainContext",
                    reason: "Invalid public key"));
              }
              return IResult.callSync(
                  () => AppContextConfigResponse.deserialize(bytes: buffer));
            },
            encoder: JSIsolateContextMessageEncoder(),
            param:
                WebIsolateEncodedMessage.empty(IsolateMessageTypes.createMainContext, 0),
            wasmModule: contextUrl,
            decoder: JSIsolateContextResponseMessageDecoder());
        return result.andThenAsync((c) async {
          final connector = c.connector;
          final response = c.response;
          final databaseConnector = ISolateMessageChannel<
                  ISolateMessageRequest<AppContextMessageDatabaseRequest>,
                  ISolateMessageResponse<AppContextMessageDatabaseResponse>>(
              connector: connector,
              stream: connector.stream.filterMessage(AppContextMessageSection.database));
          final api = AppContextConnectionApi(
              connection: ISolateMessageChannel(
                  connector: connector,
                  stream: connector.stream.filterMessages([
                    AppContextMessageSection.lockingTask,
                    AppContextMessageSection.isolateConnection,
                  ])));
          final worker = DefaultWorkerApiWeb(
              api: api, resourcesApi: resourceApi, href: resourceApi.resolver.href);
          final shareKey = contextKey * response.contextKey;
          final cryptoConnector = WebCryptoTransporterMain.init(
              sharedKey: shareKey,
              connector: PortMessageChannel(
                  receive: DefaultMessageChannelStream(connector.stream
                      .filterMessage<AppContextMessageCryptoResponseDefault>(
                          AppContextMessageSection.crypto)
                      .map((e) => WebCryptoApiUtils.resolveMessage(
                          e.message.map((e) => e.message), e.id))),
                  sink: SinkMessageTransform(
                      sink: DefaultMessageChannelSink(connector.add),
                      encoder: JSCryptoIsolateContextMessageEncoder())));
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
              return DefaultAppContextWeb(
                  setting: setting,
                  interface: platform,
                  platform: platformConfig.platform,
                  resourceApi: resourceApi,
                  connectionApi: api,
                  platformUtls: DefaultPlatformUtilsWeb(
                      platform: platform, pathResolver: resourceApi.resolver),
                  platformCrypto: DefaultPlatformCryptoApi(platform),
                  cryptoLib: crypto,
                  worker: worker,
                  utils: utils,
                  database: DefaultAppDatabase(connector: databaseConnector),
                  netApi:
                      DefaultNetApi(DefaultNetSdkApi(DefaultNetSdk(AppEnvironment.web))));
            });
          });
        });
      });
    });
  }

  @override
  AppContextMode get mode => AppContextMode.main;
}
