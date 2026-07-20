import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/api/client/core/client.dart';
import 'package:on_chain_wallet/wallet/api/service/services/default.dart';
import 'package:on_chain_wallet/wallet/api/service/types/network_providers.dart';
import 'package:on_chain_wallet/wallet/api/service/types/provider.dart';
import 'package:on_chain_wallet/wallet/api/service/types/status.dart';
import 'package:on_chain_wallet/wallet/chain/chain/typedef/types.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';

typedef CbCreateNewNetworkClient<
        NETWORK extends WalletNetwork,
        CLIENT extends CLIENTNWORK<NETWORK>,
        NPROVIDER extends NetworkApiProvider<NETWORK, CLIENT>>
    = Future<CLIENT> Function(NPROVIDER);
typedef CbOnClientStatusChanged = void Function(INetworkServiceNotify status);

abstract class DefaultNetworkServiceManager<
    NETWORK extends WalletNetwork,
    CLIENT extends CLIENTNWORK<NETWORK>,
    NPROVIDER extends NetworkApiProvider<NETWORK, CLIENT>> {
  NETWORK get network;
  DefaultNetworkServiceManager();
  late final ClientWithStatus<NETWORK, CLIENT, NPROVIDER> _controller = ClientWithStatus(
      onCreateNewClient: (e) =>
          e.toClient(network: network, createService: clientCreateService),
      onStatusChanged: onClientStatusChanged);
  INetworkServiceNotify get serviceStatus => _controller.status;
  NPROVIDER? get currentProvider => _controller.provider;
  Future<MultiChainServiceClient> clientCreateService(DefaultAPIProvider provider);

  Future<IResult<NPROVIDER?>> getActiveService();
  void onChangeProvider(NPROVIDER? provider) {
    _controller.setProvider(provider);
  }

  Future<IResult<CLIENT>> client() async {
    final provider = _controller.provider;
    if (provider != null) {
      return _controller.connect();
    }
    final newProvider = await getActiveService();
    return await newProvider.andAsync((provider, error) async {
      _controller.setProvider(provider, error: error?.exception);
      return _controller.connect();
    });
  }

  void onClientStatusChanged(INetworkServiceNotify status);
}

class ClientWithStatus<NETWORK extends WalletNetwork, CLIENT extends CLIENTNWORK<NETWORK>,
    NPROVIDER extends NetworkApiProvider<NETWORK, CLIENT>> {
  final CbCreateNewNetworkClient<NETWORK, CLIENT, NPROVIDER> onCreateNewClient;
  ClientWithStatus({required this.onCreateNewClient, required this.onStatusChanged});
  final CbOnClientStatusChanged onStatusChanged;
  NPROVIDER? _provider;
  NPROVIDER? get provider => _provider;
  CLIENT? _client;
  CLIENT? get client => _client;
  final Cancelable _cancelable = Cancelable();
  final lock = SafeAtomicLock();

  INetworkServiceNotify status = INetworkServiceNotifyStatus.noProvider();

  Future<IResult<CLIENT>> _connect(
      NPROVIDER provider, CbOnClientStatus onStatusChanged) async {
    return IResult.block(() async {
      CLIENT? client = _client;
      if (client != null && status.status.isConnected) {
        return ResultOk(client);
      }
      final cl = _client ??= await onCreateNewClient(provider);
      cl.addStatusListener(onStatusChanged);
      final init = await cl.initClient();
      return init.map((e) => cl);
    }, cancelable: _cancelable);
  }

  void _close() {
    _cancelable.cancel();
    _provider = null;
    _client?.dispose();
    _client = null;
  }

  void setProvider(NPROVIDER? provider, {IException? error}) {
    if (_provider != null && provider == _provider) return;
    final isConnected = status.status.isConnected;
    _close();
    _provider = provider;
    status = switch (provider) {
      null => switch (error) {
          null => INetworkServiceNotifyStatus.noProvider(),
          IException error =>
            INetworkServiceNotifyStatus.error(ResultErr.fromException(error)),
        },
      _ => INetworkServiceNotifyStatus.pending()
    };
    if (isConnected) onStatusChanged(status);
    connect();
  }

  Future<IResult<CLIENT>> connect() async {
    return await lock.run(() async {
      final client = _client;
      if (client != null && status.status.isConnected) {
        return ResultOk(client);
      }

      final provider = _provider;

      if (provider == null) {
        return status.error?.cast() ??
            ResultErr.fromException(WalletExceptionConst.noActiveProvider);
      }

      status = INetworkServiceNotifyStatus.pending();
      onStatusChanged(status);
      void onClientStatus(NetworkClientStatus status) {
        if (status case NetworkClientPendingTor()) {
          if (!this.status.status.isPending) return;
          this.status = INetworkServiceNotifyStatus.pendingTor();
          onStatusChanged(this.status);
        }
      }

      final result = await _connect(provider, onClientStatus);

      _client?.removeStatusListener(onClientStatus);
      result.mapErr((e) {
        if (!e.canceled()) {
          status = INetworkServiceNotifyStatus.error(e);
        }
        return e.exception;
      }).map((e) {
        status = INetworkServiceNotifyStatus.connect();
        return e;
      });
      onStatusChanged(status);
      return result;
    });
  }
}
