part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

abstract final class ISubstrateChainContext
    implements
        IChainContext<
            BaseSubstrateAddress,
            SubstrateToken,
            NFTCore,
            WalletSubstrateNetwork,
            SubstrateWalletTransaction,
            ISubstrateAddress,
            SubstrateNetworkClient,
            SubstrateNetworkProvider> {
  @override
  ISubstrateAddress? getAddressSync(
      {String? address, BaseSubstrateAddress? networkAddress}) {
    if (networkAddress != null) {
      return addresses.firstWhereOrNull(
          (element) => element.networkAddress.rawAddress == networkAddress.rawAddress);
    }
    if (address == null) return null;
    if (StringUtils.isHexBytes(address)) {
      return addresses.firstWhereOrNull(
          (element) => StringUtils.hexEqual(element.networkAddress.rawAddress, address));
    }
    return addresses.firstWhereOrNull((element) => element.viewAddress == address);
  }

  Future<IResult<List<SubstrateMultisigCallData>>> getAccountMultisigs(
      ISubstrateMultiSigAddress address,
      {SubstrateMultisigCall? newRequest});
}

final class SubstrateMainChainContext extends DefaultMainChainContext<
    BaseSubstrateAddress,
    SubstrateToken,
    NFTCore,
    WalletSubstrateNetwork,
    SubstrateWalletTransaction,
    ISubstrateAddress,
    SubstrateNetworkClient,
    SubstrateNetworkProvider> implements ISubstrateChainContext {
  SubstrateMainChainContext(
      {required super.id, required super.controller, required super.network});

  @override
  Future<IResult<bool>> updateAddressBalanceInternal(ISubstrateAddress address,
      {bool tokens = true}) async {
    final accountAddress = await isAccountAddress(address);
    return accountAddress.andThenAsync((address) async {
      final client = await this.client();
      return client.andThenCatchAsync((client) async {
        final balance = await client.getAccountBalance(address.networkAddress);
        final updateBalance = await address._updateAccountBalance(balance);
        if (updateBalance.isErr) return updateBalance;
        if (tokens) {
          final tokens = await address.getAccountTokens();
          return tokens.andThenAsync((tokens) async {
            final balances = await client.getAddressTokensBalances(
                address: address.networkAddress,
                identifiers: tokens.map((e) => e.assetIdentifier).toList());
            for (final i in tokens) {
              final balance = balances
                  .firstWhereOrNull((e) => e.asset.identifierEqual(i.assetIdentifier));
              final result = await address._updateAccountTokenBalance(
                  i, () => i._updateBalance(balance?.free ?? BigInt.zero));
              if (result.isErr) return result;
            }
            return updateBalance;
          });
        }
        return updateBalance;
      });
    });
  }

  @override
  Future<IResult<void>> updateTokenBalance(
      {required ISubstrateAddress address,
      required List<SubstrateToken> tokens,
      bool isAccountAddress = false}) async {
    final accountAddress =
        await this.isAccountAddress(address, validate: !isAccountAddress);
    return accountAddress.andThenAsync((address) async {
      final client = await this.client();
      return client.andThenCatchAsync((client) async {
        final balances = await client.getAddressTokensBalances(
            address: address.networkAddress,
            identifiers: tokens.map((e) => e.assetIdentifier).toList());
        for (final i in tokens) {
          final balance = balances
              .firstWhereOrNull((e) => e.asset.identifierEqual(i.assetIdentifier));
          assert(balance != null, "token not found.");
          final result = await address._updateAccountTokenBalance(
              i, () => i._updateBalance(balance?.free ?? BigInt.zero));
          if (result.isErr) return result;
        }
        return ResultOk.okVoid;
      });
    });
  }

  @override
  Future<IResult<List<SubstrateMultisigCallData>>> getAccountMultisigs(
      ISubstrateMultiSigAddress address,
      {SubstrateMultisigCall? newRequest}) async {
    return callSync(
        fn: () async {
          final accountAddress = await isAccountAddress(address);
          return accountAddress.andThenAsync((address) async {
            final client = await this.client();
            return client.andThenCatchAsync((client) async {
              final multisigs = await client.getMultisigs(address.networkAddress);
              if (multisigs.isEmpty) {
                final result = await address._storageCleanAccountAllMultisigs();
                if (result.isErr) {
                  return result.cast();
                }
                if (newRequest == null) return ResultOk([]);
              }
              if (newRequest != null) {
                assert(newRequest.callData != null);
                final result = await address._storageSaveAccountMultisig(newRequest);
                if (result.isErr) {
                  return result.cast();
                }
              }

              final fetchedTxes = [
                ...multisigs.map((e) => e.callHashHex),
                if (newRequest != null) newRequest.callHashHex
              ];
              final exitMultisigs = await address._storageGetAccountMultisigs();
              if (exitMultisigs.isErr) {
                return exitMultisigs.cast();
              }
              final accountMultisigs = [
                ...exitMultisigs.unwrap(),
                if (newRequest != null) newRequest
              ];
              final txes = {for (final i in accountMultisigs) i.callHashHex: i};
              final junkTxes = txes.keys.where((e) => !fetchedTxes.contains(e)).toList();
              final result = await address._storageCleanAccountMultisigs(junkTxes);
              return result.andThenAsync((_) {
                final addNewReuqest = newRequest == null
                    ? false
                    : !multisigs.any((e) => e.callHashHex == newRequest.callHashHex);
                final List<SubstrateMultisigCallData> exitMultisigs = [];
                if (addNewReuqest) {
                  exitMultisigs.add(SubstrateMultisigCallData(
                      call: newRequest,
                      content: () {
                        final data = newRequest.callData;
                        if (data == null) return null;
                        return client.api.decodeCall(data).toJson();
                      }(),
                      multisig: null));
                }
                exitMultisigs.addAll(multisigs.map((e) {
                  final callData = txes[e.callHashHex] ??
                      SubstrateMultisigCall(callData: null, callHash: e.callHash);
                  return SubstrateMultisigCallData(
                      call: callData,
                      content: () {
                        final data = callData.callData;
                        if (data == null) return null;
                        return client.api.decodeCall(data).toJson();
                      }(),
                      multisig: e.multisig);
                }));

                return ResultOk(exitMultisigs);
              });
            });
          });
        },
        lockId: LockId.five,
        type: null);
  }

  @override
  IResult<SubstrateNetworkProvider?> buildProviderNetworkIdentifier(
      {required List<DefaultAPIProvider> providers,
      List<SubstrateNetworkProvider> exclude = const []}) {
    for (final p in providers) {
      if (!clientRequiredServices.allowServices.contains(p.service)) {
        continue;
      }
      final identifier = SubstrateNetworkProvider(p);
      if (exclude.contains(identifier)) continue;
      return ResultOk(identifier);
    }
    return ResultOk(null);
  }

  @override
  final clientRequiredServices =
      NetworkClientRequirment.oneOf({APIProviderServices.substrateJsonRpc});
}
