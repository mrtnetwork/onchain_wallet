import 'dart:async';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/service/models/params.dart';
import 'package:on_chain/ethereum/src/rpc/core/core.dart';
import 'package:on_chain/ethereum/src/rpc/core/methods.dart' show EthereumMethods;
import 'package:on_chain/ethereum/src/rpc/methds/ethereum/dynamic.dart';
import 'package:on_chain/ethereum/src/rpc/methds/subscribes/methods/subscribe.dart';
import 'package:on_chain/ethereum/src/rpc/provider/provider.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/context.dart';
import 'package:on_chain_wallet/wallet/api/provider/provider.dart';
import 'package:on_chain_wallet/wallet/api/service/services/default.dart';
import 'package:on_chain_wallet/wallet/api/service/types/provider.dart';

import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/exception/exception.dart'
    show Web3RequestException;
import 'package:on_chain_wallet/web3/web3/networks/ethereum/constant/exception.dart';

typedef ONETHSubsribe = void Function(Map<String, dynamic>);

class JSEthereumClient {
  final DefaultProvider<EthereumProvider<MultiChainServiceClient>, EthereumRequestDetails>
      client;
  final Map<int, Completer> _completers = {};
  int _id = 0;
  bool _isConnect = true;
  bool get isConnect => _isConnect;
  bool get supportSubscribe =>
      client.service.client.protocol == ServiceProtocol.websocket;
  final List<ONETHSubsribe> _listeners = [];
  final Map<String, StreamSubscription> _subscribtions = {};
  JSEthereumClient._(this.client);
  factory JSEthereumClient(
      {required DefaultAPIProvider provider,
      required AppContext context,
      Duration? requestTimeout}) {
    return JSEthereumClient._(DefaultProvider(EthereumProvider(
        MultiChainServiceClient.fromProvider(
            provider: provider, netApi: context.netApi))));
  }

  void _onSubscribtion(EthereumGenericSbuscriptionResponse event) {
    for (final i in [..._listeners]) {
      i(event.event);
    }
  }

  void addSubscriptionListener(ONETHSubsribe listener) {
    if (!supportSubscribe || !isConnect) return;
    _listeners.add(listener);
  }

  Future<String> _subscribe({List<dynamic> params = const []}) async {
    if (!supportSubscribe) {
      throw Web3RequestExceptionConst.methodDoesNotSupport;
    }
    try {
      final result = await client.inner
          .requestSubscribtion(EthereumRequestETHSubscribeGeneric(params));
      if (isConnect) {
        _subscribtions[result.identifier] = result.stream.listen(
          _onSubscribtion,
          onDone: () {
            _subscribtions.remove(result.identifier);
          },
        );
      }
      return result.identifier;
    } on Web3RequestException {
      rethrow;
    } on APIError catch (e) {
      throw Web3RequestExceptionConst.fromException(e);
    } catch (e) {
      throw Web3RequestExceptionConst.disconnectProvider;
    }
  }

  Future<dynamic> _dynamicCall(String method, dynamic params) async {
    return await client
        .requestDynamic(EthereumRequestDynamic(methodName: method, params: params));
  }

  Future<void> addRequest({
    required int id,
    required EthereumMethods method,
    required List<dynamic> params,
  }) async {
    try {
      dynamic result;
      if (method == EthereumMethods.subscribe) {
        result = await _subscribe(params: params);
      } else {
        result = await _dynamicCall(method.value, params);
        if (method == EthereumMethods.ethUnsubscribe) {
          var id = params.elementAtOrNull(0);
          if (id is String) {
            final sub = _subscribtions.remove(id);
            sub?.cancel();
          }
        }
      }
      final completer = _completers.remove(id);
      completer?.complete(result);
    } catch (e, s) {
      final completer = _completers.remove(id);
      completer?.completeError(e, s);
    }
  }

  Future<dynamic> call(String methodName, List<dynamic> params) async {
    if (!isConnect) {
      throw Web3EthereumExceptionConst.disconnectedChain;
    }
    final method = EthereumMethods.fromName(methodName);
    if (method == null) {
      throw Web3RequestExceptionConst.methodDoesNotExist;
    }
    try {
      final id = _id++;
      final completer = Completer();
      _completers[id] = completer;
      addRequest(id: id, method: method, params: params);
      return await completer.future;
    } on Web3RequestException {
      rethrow;
    } on RPCError catch (e) {
      throw Web3RequestExceptionConst.fromException(e);
    } catch (e) {
      throw Web3RequestExceptionConst.disconnectProvider;
    }
  }

  void close() {
    _isConnect = false;
    final completers = _completers.keys;
    final subs = _subscribtions.clone();
    _subscribtions.clear();
    for (final i in subs.values) {
      i.cancel();
    }
    for (final i in completers) {
      final completer = _completers.remove(i);
      if (completer == null || completer.isCompleted) continue;
      try {
        completer.completeError(Web3RequestExceptionConst.disconnectProvider);
      } catch (_) {}
    }
    _listeners.clear();
    client.service.dispose();
  }
}
