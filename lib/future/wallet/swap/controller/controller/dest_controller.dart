import 'dart:async';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/networks/address/utils.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/others/models/receipt_address.dart';
import 'package:on_chain_wallet/wallet/models/swap/swap/models.dart';

typedef ONSELECTDESTACCOUNT = Future<ReceiptAddress?> Function(Chain);
mixin SwapDestinationController on StreamStateController {
  List<Chain> get chains;
  APPSwapAssets? _destinationAsset;
  APPSwapAssets? get destinationAsset => _destinationAsset;
  ReceiptAddress? _destinationAddress;
  ReceiptAddress? get destinationAddress => _destinationAddress;
  bool _destSupported = false;
  bool get destSupported => _destSupported;

  Map<WalletNetwork, Set<APPSwapAssets>> _destinationAssets = {};
  Map<WalletNetwork, Set<APPSwapAssets>> get destinationAssets => _destinationAssets;

  Chain? _destinationChain;
  Chain? get destinationChain => _destinationChain;

  Future<void> setDestAssets(Map<WalletNetwork, Set<APPSwapAssets>> assets,
      {APPSwapAssets? sourceAsset}) async {
    _destinationAssets = assets;
    if (!_destinationAssets.values.any((e) => e.contains(destinationAsset))) {
      _destinationAsset = null;
    }
    APPSwapAssets? asset = _destinationAsset;
    if (asset == null) {
      if (sourceAsset == null) {
        asset = _destinationAssets.values.lastOrNull?.firstOrNull;
      } else {
        asset = _destinationAssets[_destinationAssets.keys
                    .firstWhereOrNull((e) => e != sourceAsset.network)]
                ?.firstOrNull ??
            _destinationAssets.values
                .expand((e) => e)
                .firstWhereOrNull((e) => e != sourceAsset) ??
            _destinationAssets.values.firstOrNull?.firstOrNull;
      }
    }
    if (asset != null) {
      await updateDestinationAsset(asset);
    }
  }

  Future<void> onSelectReceiptAddress(ONSELECTDESTACCOUNT onSelectDestAccount) async {
    final dChain = _destinationChain;
    final dAsset = destinationAsset;
    if (dChain == null || dAsset == null) return;
    final address = await onSelectDestAccount(dChain);
    if (address == null) return;
    if (BlockchainAddressUtils.isValidNetworkAddress(address.view, dAsset.network)) {
      _destinationAddress = address;
    }
  }

  Future<void> updateDestinationAsset(APPSwapAssets asset) async {
    if (destinationAsset == asset) return;
    _destinationAsset = asset;
    _destinationChain =
        chains.firstWhereOrNull((e) => e.network == destinationAsset?.network);
    await _destinationChain?.initAsMainNetwork();
    final destAsset = destinationAsset;
    if (destAsset != null &&
        _destinationAddress != null &&
        !BlockchainAddressUtils.isValidNetworkAddress(
            _destinationAddress?.view, destAsset.network)) {
      _destinationAddress = null;
    }
    _destSupported = _destinationChain != null;
  }

  void cleanDestinationState() {
    _destSupported = false;
    _destinationAssets = {};
    _destinationAddress = null;
    _destinationAsset = null;
  }
}
