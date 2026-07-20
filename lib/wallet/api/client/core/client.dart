import 'dart:async';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/api/service/types/provider.dart';
import 'package:on_chain_wallet/wallet/api/service/services/default.dart';
import 'package:on_chain_wallet/wallet/api/service/types/network_providers.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/token/network/token.dart';
import 'package:on_chain_wallet/wallet/models/transaction/core/transaction.dart';

typedef CbOnClientStatus = void Function(NetworkClientStatus status);

abstract class NetworkClient<
    TRANSACTION extends ChainTransaction,
    TOKEN extends BaseNetworkToken,
    NETWORKADDRESS extends IAddress,
    NETWORK extends WalletNetwork> {
  NetworkClient({required this.network});
  final NETWORK network;
  final _lock = SafeAtomicLock();
  NetworkClientStatus _status = NetworkClientPending();
  NetworkApiProvider get networkProvider;
  NetworkType get networkType => network.type;
  List<MultiChainServiceClient> services();
  MultiChainServiceClient? getService(String identifier) =>
      services().firstWhereOrNull((e) => e.provider.identifier == identifier);
  Future<bool> verifyService(DefaultAPIProvider provider);
  final Set<String> _pendingTxes = {};
  final List<CbOnClientStatus> _listeners = [];
  void notifyListeners() {
    final status = _status;
    for (final i in [..._listeners]) {
      i(status);
    }
  }

  void addStatusListener(CbOnClientStatus listener) {
    _listeners.add(listener);
  }

  void removeStatusListener(CbOnClientStatus listener) {
    _listeners.remove(listener);
  }

  void _updateStatus(NetworkClientStatus status) {
    if (_status.disposed) {
      return;
    }
    if (_status != status) {
      _status = status;
      notifyListeners();
    }
  }

  Future<IResult<void>> initClient() async {
    return _lock.run(() async {
      switch (_status) {
        case NetworkClientPending():
        case NetworkClientPendingTor():
          break;
        case NetworkClientVerified():
          return ResultOk(null);
        case NetworkClientFailed(:final error):
          if (error == APIErrorConst.serverUnexpectedResponse ||
              error == APIErrorConst.clientDisposed) {
            return ResultErr.fromException(error);
          }
          break;
      }

      final services = this.services();
      final torService = services.lastWhereOrNull((e) => e.provider.mode.isTor);
      if (torService != null) {
        _updateStatus(NetworkClientPendingTor());
        final result = await torService.initTor();
        if (result.isErr) {
          _updateStatus(NetworkClientFailed(result.unwrapErr().exception));
          return result;
        }
      }
      _updateStatus(NetworkClientPending());
      for (final i in services) {
        final init = await IResult.call(
          () async => await verifyService(i.provider),
          onError: (exception, trace) {
            if (exception is APIError) return null;
            return AppLogData(
                runtime: runtimeType,
                msg: "Unexpected verification service response.",
                function: "initClient",
                err: exception,
                trace: trace.toString());
          },
        );
        final isOk = init.ok();
        if (isOk == null || !isOk) {
          final err = init.err()?.exception ?? APIErrorConst.serverUnexpectedResponse;
          _updateStatus(NetworkClientFailed(err));
          return init.and((_, __) => ResultErr.fromException(err));
        }
      }
      _updateStatus(NetworkClientVerified());
      if (_status.disposed) {
        return ResultErr.fromException(APIErrorConst.clientDisposed);
      }
      return ResultOk(null);
    });
  }

  Future<bool> initSwapClient() async {
    final init = await initClient();
    return init.fold(
      onOk: (_) => true,
      onErr: (error) => throw error.exception,
    );
  }

  Future<WalletTransactionStatus> transactionStatus(TRANSACTION transaction);
  Future<Stream<TRANSACTION>?> trackMempoolTransaction(TRANSACTION transaction) async {
    return _lock.run(() async {
      if (!transaction.status.inMempool || _pendingTxes.contains(transaction.txId)) {
        return null;
      }
      bool closed = false;
      _pendingTxes.add(transaction.txId);
      SafeStreamController<TRANSACTION> controller =
          SafeStreamController(name: "$runtimeType.transactionStatus");

      // Future<WalletTransactionStatus> getTxStatus() async {
      //   try {
      //     return await transactionStatus(transaction);
      //   } catch (e) {
      //     return WalletTransactionStatus.unknown;
      //   }
      // }

      void close() {
        closed = true;
        if (!controller.isClosed) {
          controller.close();
        }
      }

      void listener(NetworkClientStatus status) {
        assert(status.disposed, "unexpected status.");
        if (status.disposed && !closed) {
          close();
        }
      }

      if (_status.disposed) {
        close();
        return null;
      }

      addStatusListener(listener);
      void updateStatus(WalletTransactionStatus status) {
        if (closed || controller.isClosed) return;
        transaction.updateStatus(status);
        controller.add(transaction);
      }

      final maxBlockIntervalSec = network.coinParam.averageBlockTime;
      final maxTxConfirmationBlock = network.coinParam.maxTxConfirmationBlock;
      final totalSec = maxBlockIntervalSec * maxTxConfirmationBlock;
      Future<void> onListen() async {
        Logging.debug(
          fn: () => AppLogData(
              runtime: runtimeType,
              function: "trackMempoolTransaction",
              msg: "start trancking transaction: ${transaction.txId}"),
        );
        while (!closed && !controller.isClosed) {
          final tStatus = await IResult.call(
            () async => await transactionStatus(transaction),
            onError: (exception, trace) => AppLogData(
                runtime: runtimeType,
                function: "transactionStatus",
                err: exception,
                trace: trace.toString()),
          );
          WalletTransactionStatus status = tStatus.unwrapOr(
            (err) => WalletTransactionStatus.unknown,
          );
          if (status.isUnknown || status.inMempool) {
            final end = transaction.time.add(Duration(seconds: totalSec));
            final now = DateTime.now();
            if (end.isAfter(now)) {
              await Future.delayed(Duration(seconds: maxBlockIntervalSec));
              continue;
            }
            status = WalletTransactionStatus.unknown;
          }
          updateStatus(status);
          break;
        }
        Logging.debug(
          fn: () => AppLogData(
              runtime: runtimeType,
              function: "trackMempoolTransaction",
              msg: "tracking status complete: ${transaction.txId}/${transaction.status}"),
        );
        removeStatusListener(listener);
        _pendingTxes.remove(transaction.txId);
        close();
      }

      controller.onListenListener(onListen);
      controller.onCancelListener(() {
        closed = true;
      });
      return controller.stream();
    }, lockId: LockId.two);
  }

  Stream<List<TOKEN>> getAccountTokensStream(NETWORKADDRESS address) {
    throw UnimplementedError();
  }

  void dispose() {
    _updateStatus(NetworkClientFailed(APIErrorConst.clientDisposed));
    _listeners.clear();
    _pendingTxes.clear();
    final services = this.services();
    for (final i in services) {
      i.dispose();
    }
  }

  @override
  String toString() {
    return "Client: ${network.networkName}";
  }

  T cast<T extends NetworkClient>() {
    if (this is! T) {
      throw AppInternalError.internalError("NetworkClient.cast");
    }
    return this as T;
  }
}

sealed class NetworkClientStatus {
  const NetworkClientStatus();
  bool get disposed => false;
}

final class NetworkClientPending extends NetworkClientStatus {}

final class NetworkClientPendingTor extends NetworkClientStatus {}

final class NetworkClientVerified extends NetworkClientStatus {}

final class NetworkClientFailed extends NetworkClientStatus {
  final IException error;
  const NetworkClientFailed(this.error);

  @override
  String toString() {
    return "NetworkClientFailed{error: $error}";
  }

  @override
  bool get disposed => error == APIErrorConst.clientDisposed;
}
