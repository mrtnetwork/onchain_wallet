import 'dart:async';
import 'dart:isolate';
import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:blockchain_utils/uuid/uuid.dart';
import 'package:on_chain_bridge/dev/dev.dart';
import 'package:on_chain_bridge/native/database/interface/interface.dart';
import 'package:on_chain_bridge/native/net_sdk/core/net_sdk.dart';
import 'package:on_chain_bridge/native/net_sdk/types/config.dart';
import 'package:on_chain_bridge/native/utils/utils.dart';
import 'package:on_chain_bridge/net_sdk/net_sdk.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/constants/const.dart';
import 'package:on_chain_wallet/context/core/sync.dart';
import 'package:on_chain_wallet/context/controller/controller.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/context/database/sync.dart';
import 'package:on_chain_wallet/context/exception/exception.dart';
import 'package:on_chain_wallet/context/native/api/resources.dart';
import 'package:on_chain_wallet/context/native/types/types.dart';
import 'package:on_chain_wallet/context/native/utils/utils.dart';
import 'package:on_chain_wallet/context/native/worker/worker.dart';
import 'package:on_chain_wallet/context/netsdk/connector.dart';
import 'package:on_chain_wallet/context/types/channels.dart';
import 'package:on_chain_wallet/context/types/messages.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/api/disabled.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/cross/native/native.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/cross/native/types.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';

class IsolateAppContextController {
  final IsolateAppContextMainConnectionControllerNative mainConnection;
  IsolateAppContextController({required this.mainConnection});
  static Future<IResult<(IsolateNetSdkNativeConfig, IOISOLATECLOSE)>> init(
      AppContextConfigNative config,
      MessageChannel<ISolateMessageResponse<AppContextMessageResponse>,
              ISolateMessageRequest<AppContextMessageRequest>>
          connector,
      AppContext? _) async {
    final resourceApi = AppResourceNative();
    final torFolderName = resourceApi.torParamsLocation().ok();
    final loggingFolderRelativePath = resourceApi.loggingFileLocation().ok();
    final sqliteLibName = resourceApi.sqliteLibName().ok();
    final netSdkLibName = resourceApi.netSdkLibName().map((e) {
      return OnChainBridgeIoUtils.getDynamicLiberaryPath(e);
    }).ok();
    if (torFolderName == null ||
        loggingFolderRelativePath == null ||
        netSdkLibName == null ||
        sqliteLibName == null) {
      return ResultErr.fromException(AppExceptionConst.resourceNotSupported);
    }

    Logging.init(config.loggingConfig.copyWith(printDebug: true),
        writer: LogWriterFile(
            loggingFolderRelativePath.getAbsolutePath(config.path),
            config.loggingConfig.mode == LoggerMode.debug
                ? LoggerMode.debug
                : LoggerMode.error));
    final database = IDatabseInterfaceIo(
        dbName: resourceApi.dbName(), appPath: config.path, liberaryName: sqliteLibName);
    final init = (await database.openDatabase(config.dbKey)).toResult();
    final dbKey = init.ok();
    if (init.isErr || dbKey == null) {
      final err = init.err()?.exception ?? WalletExceptionConst.dataBaseOperationFailed;
      return ResultErr.fromException(err);
    }
    final channel = ISolateMessageChannel<
            ISolateMessageResponse<AppContextMessageNetSdkResponse>,
            ISolateMessageRequest<AppContextMessageNetSdkRequest>>(
        connector: connector,
        stream: connector.stream.filterMessage(AppContextMessageSection.netSdk));
    final torConfig = NetConfigTor(
      cacheDir: torFolderName.cacheState.getAbsolutePath(config.path),
      stateDir: torFolderName.mainState.getAbsolutePath(config.path),
    );
    final backgroundSdk = NativeNetSdk.init(
      NetSdkConfigNative(
          libUri: netSdkLibName,
          config: NetCreateInstanceConfig(
              logging: true,
              torConifg: torConfig,
              mode: config.loggingConfig.netsdk,
              instanceId: resourceApi.netSdkInstanceId(config.mode),
              freshStart: true)),
    ).transformError((error) => NetSdkException(error));
    return backgroundSdk.andThen((sdk) {
      final contextKey = config.contextKey;
      if (contextKey == null) {
        return ResultErr.fromException(AppInternalError.internalError(
            "IsolateAppContextController.init",
            reason: "Missing app context key."));
      }
      final key = X25519Keypair.generate();
      final sharedKey = key * contextKey;
      final netApi = DefaultNetApi(DefaultNetSdkApi(sdk));
      final context = DefaultAppContext(
          path: config.path,
          resourceApi: resourceApi,
          utils: NativeAppContextUtils(netApi: netApi, path: config.path),
          mode: AppContextMode.backgroundContextController,
          platform: config.platform,
          cryptoLib: DisabledAppBasicCryptoApi(),
          database: SyncAppDatabase(database),
          netApi: DefaultNetApi(DefaultNetSdkApi(sdk)));
      final instance = IsolateAppContextController(
        mainConnection: IsolateAppContextMainConnectionControllerNative(
            connector: connector,
            netsdk: IsolateNetSdkConnector(netSdk: sdk, connector: channel),
            database: database,
            crypto: NativeCryptoResponseBuilder(
                chacha: ChaCha20Poly1305(sharedKey), context: context),
            context: context),
      );
      return ResultOk((
        IsolateNetSdkNativeConfig(
            modes: sdk.modes,
            target: sdk.target,
            databaseKey: dbKey,
            contextKey: key.publicKey),
        instance.onClose
      ));
    });
  }

  Future<void> onClose() async {}
}

class IsolateAppContextMainConnectionControllerNative
    extends IsolateAppContextMainConnectionController<
        AppContextMessageCreateConnectionResponseNative,
        IIsolateCryptoMessageNative,
        IsolateAppContextChildConnectionControllerNative> {
  IsolateAppContextMainConnectionControllerNative(
      {required super.connector,
      required super.netsdk,
      required super.database,
      required super.context,
      required super.crypto});
  @override
  Future<IResult<AppContextMessageCreateConnectionResponseNative>>
      createConnection() async {
    final port = ReceivePort();

    final completer =
        Completer<IResult<(String, IsolateAppContextChildConnectionControllerNative)>>();
    String? id;
    port.listen((request) async {
      if (request is! ISolateMessageRequest) return;
      final msg = request.message;
      switch (msg) {
        case AppContextMessageStablishConnectionRequestNative(
            :final port,
            :final contextKey
          ):
          final connectionId = id = UUID.generateUUIDv4();
          final key = X25519Keypair.generate();
          final sharedKey = key * contextKey;
          final controller = SafeStreamController<
                  ISolateMessageRequest<AppContextMessageRequest>>.broadcast(
              name: "AppContextMessageStablishConnectionRequestNative");
          final connector = IsolateBackgroundChannel<
                  ISolateMessageResponse<AppContextMessageResponse>,
                  ISolateMessageRequest<AppContextMessageRequest>>(
              receive: controller, sink: port);
          final channel = ISolateMessageChannel<
                  ISolateMessageResponse<AppContextMessageNetSdkResponse>,
                  ISolateMessageRequest<AppContextMessageNetSdkRequest>>(
              connector: connector,
              stream: connector.stream.filterMessage(AppContextMessageSection.netSdk));
          final backgroundSdk =
              IsolateNetSdkConnector(netSdk: netsdk.netSdk, connector: channel);
          final newConnector = IsolateAppContextChildConnectionControllerNative(
              connector: connector,
              netsdk: backgroundSdk,
              mainConnection: this,
              crypto: NativeCryptoResponseBuilder(
                  chacha: ChaCha20Poly1305(sharedKey), context: context),
              context: context,
              database: database,
              controller: controller);
          final result = await connector.add(ISolateMessageResponse.from(
              request: request,
              response: ResultOk(AppContextMessageStablishConnectionResponse(
                  modes: netsdk.netSdk.modes,
                  netApiTarget: netsdk.netSdk.target,
                  connectionId: connectionId,
                  contextKey: key.publicKey))));
          if (result.isErr || completer.isCompleted) {
            newConnector.shutdown();
            return;
          }
          completer.complete(ResultOk((connectionId, newConnector)));
          break;
        default:
          final connector = connections[id];
          if (connector == null) {
            port.sendPort.send(ISolateMessageResponse.from(
                request: request,
                response: ResultErr<AppContextMessageResponse>.fromException(
                    AppContextError.connectionNotFound)));
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
    completer.future.timeout(
      AppContextConst.createConnectionTimeout,
      onTimeout: () {
        final error = ResultErr<
            (
              String,
              IsolateAppContextChildConnectionControllerNative
            )>.fromException(AppContextError.createConnectionTimeount);
        if (!completer.isCompleted) {
          completer.complete(error);
        }
        return error;
      },
    ).then((e) {
      if (e.isOk) {
        final (id, connector) = e.unwrap();
        connections[id] = connector;
        return;
      }
      port.close();
    });
    return ResultOk(AppContextMessageCreateConnectionResponseNative(port.sendPort));
  }

  @override
  AppContextMessageCryptoResponse<IIsolateCryptoMessageNative> createCryptoResponse(
      IIsolateCryptoMessageNative response) {
    return AppContextMessageCryptoResponseNative(response);
  }
}

class IsolateAppContextChildConnectionControllerNative
    extends IsolateAppContextChildConnectionController<
        AppContextMessageCreateConnectionResponseNative,
        IIsolateCryptoMessageNative,
        IsolateAppContextChildConnectionControllerNative> {
  IsolateAppContextChildConnectionControllerNative(
      {required super.connector,
      required super.netsdk,
      required super.database,
      required super.controller,
      required super.context,
      required super.crypto,
      required super.mainConnection});

  @override
  AppContextMessageCryptoResponse<IIsolateCryptoMessageNative> createCryptoResponse(
      IIsolateCryptoMessageNative response) {
    return AppContextMessageCryptoResponseNative(response);
  }
}
