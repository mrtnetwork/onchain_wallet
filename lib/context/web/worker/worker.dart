import 'dart:async';
import 'package:on_chain_bridge/models/web/types.dart';
import 'package:on_chain_bridge/web/api/api.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/api/api_connection.dart';
import 'package:on_chain_wallet/context/api/resources.dart';
import 'package:on_chain_wallet/context/constants/const.dart';
import 'package:on_chain_wallet/context/core/worker.dart';
import 'package:on_chain_wallet/context/types/channels.dart';
import 'package:on_chain_wallet/context/types/messages.dart';
import 'package:on_chain_wallet/context/web/types/types.dart';
import 'package:on_chain_wallet/context/web/types/port.dart';
import 'package:on_chain_wallet/context/web/worker/channel.dart';
import 'package:on_chain_wallet/context/web/worker/types.dart';

abstract class WorkerApiWeb extends AppWorkerApi {
  final AppResourcesApi resourcesApi;
  WorkerApiWeb({required this.resourcesApi});
  Future<
          IResult<
              DartInitializedWorker<WRITE, READ, RESPONSE,
                  WorkerChannelMain<WRITE, READ>>>>
      createWorker<WRITE extends Object, READ extends Object, RESPONSE extends Object?>({
    WasmModuleInfo? wasmModule,
    String? jsModule,
    required WebIsolateEncodedMessage param,
    required JSIsolateMessagDecoder<READ> decoder,
    required JSIsolateMessageEncoder<WRITE> encoder,
    required CbParseIsolateResponse<RESPONSE> transferParams,
    required AppContextConfigWeb config,
  });
}

class DefaultWorkerApiWeb extends WorkerApiWeb {
  final IAppContextConnectionApi api;
  DefaultWorkerApiWeb({required this.api, required super.resourcesApi});
  static Future<
      IResult<
          DartInitializedWorker<WRITE, READ, RESPONSE,
              WorkerChannelMain<WRITE, READ>>>> createWorkerStatic<WRITE extends Object,
      READ extends Object, RESPONSE extends Object?>({
    WasmModuleInfo? wasmModule,
    String? jsModule,
    required WebIsolateEncodedMessage param,
    required JSIsolateMessagDecoder<READ> decoder,
    required JSIsolateMessageEncoder<WRITE> encoder,
    required CbParseIsolateResponse<RESPONSE> transferParams,
    required AppContextConfigWeb config,
    required AppResourcesApi resourceApi,
  }) async {
    return resourceApi.workerExecutorPath().andThenAsync((workerExcuterPath) async {
      return await WorkerChannelMain.init<WRITE, READ, RESPONSE>(
          wasmModule: wasmModule,
          jsModule: jsModule,
          workerExcuterPath: workerExcuterPath,
          param: param.withConfig(config.toCbor().encode()),
          timeout: AppContextConst.spawnIsolateTimeout,
          decoder: decoder,
          encoder: encoder,
          transferParams: transferParams);
    });
  }

  Future<IResult<JSMessagePort>> _createConnection() async {
    final result = await api.sendRequest<AppContextMessageCreateConnectionResponse>(
        AppContextMessageCreateConnectionRequest());
    return result.map((e) => e.port);
  }

  @override
  Future<
          IResult<
              DartInitializedWorker<WRITE, READ, RESPONSE,
                  WorkerChannelMain<WRITE, READ>>>>
      createWorker<WRITE extends Object, READ extends Object, RESPONSE extends Object?>({
    WasmModuleInfo? wasmModule,
    String? jsModule,
    required WebIsolateEncodedMessage param,
    required JSIsolateMessagDecoder<READ> decoder,
    required JSIsolateMessageEncoder<WRITE> encoder,
    required CbParseIsolateResponse<RESPONSE> transferParams,
    required AppContextConfigWeb config,
  }) async {
    final connection = await _createConnection();
    return connection.andThenAsync((port) async {
      return createWorkerStatic(
          wasmModule: wasmModule,
          jsModule: jsModule,
          resourceApi: resourcesApi,
          param: param.withPort(port),
          decoder: decoder,
          encoder: encoder,
          transferParams: transferParams,
          config: config);
    });
  }
}

class DisabledWorkerWeb extends WorkerApiWeb {
  DisabledWorkerWeb() : super(resourcesApi: DisabledResourcesApi());

  @override
  Future<
          IResult<
              DartInitializedWorker<WRITE, READ, RESPONSE,
                  WorkerChannelMain<WRITE, READ>>>>
      createWorker<WRITE extends Object, READ extends Object, RESPONSE extends Object?>({
    WasmModuleInfo? wasmModule,
    String? jsModule,
    required WebIsolateEncodedMessage param,
    required JSIsolateMessagDecoder<READ> decoder,
    required JSIsolateMessageEncoder<WRITE> encoder,
    required CbParseIsolateResponse<RESPONSE> transferParams,
    required AppContextConfigWeb config,
  }) async {
    return ResultErr.fromException(AppExceptionConst.requiredServiceIsDisabled);
  }
}
