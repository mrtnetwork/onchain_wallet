import 'package:on_chain/sui/src/address/address/address.dart';
import 'package:on_chain/sui/src/rpc/models/types/types.dart';
import 'package:on_chain/sui/src/transaction/const/constant.dart';
import 'package:on_chain/sui/src/transaction/types/types.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/sui/client/client.dart';

mixin SuiTransactionApiController on DisposableMixin {
  SuiNetworkClient get client;
  final CachedObject<BigInt> _cachedGasPrice =
      CachedObject<BigInt>(interval: const Duration(minutes: 2));
  final Map<SuiAddress, CachedObject<List<SuiApiCoinResponse>>> _accountsCoins = {};
  Future<List<SuiApiCoinResponse>> getAccountCoins(SuiAddress address,
      {Duration? cachedTimeout}) async {
    final cached = _accountsCoins[address] ??=
        CachedObject<List<SuiApiCoinResponse>>(interval: const Duration(minutes: 2));
    return cached.get(
        onFetch: () async => await client.getAccountCoins(address),
        cachedTimeout: cachedTimeout);
  }

  Future<BigInt> getGasPrice() async {
    return _cachedGasPrice.get(onFetch: () async => await client.getGasPrice());
  }

  Future<SuiTransactionDataV1> filledGasPayment(SuiTransactionDataV1 transaction) async {
    List<SuiApiCoinResponse> coins =
        await client.getAccountCoins(transaction.gasData.owner);
    coins = coins.where((e) => e.coinType == SuiTransactionConst.suiTypeArgs).toList();

    final kind = transaction.kind.cast<SuiTransactionKindProgrammableTransaction>();
    final ownedObjectAddresses = kind.transaction.inputs
        .whereType<SuiCallArgObject>()
        .map((e) => e.object)
        .whereType<SuiObjectArgImmOrOwnedObject>()
        .map((e) => e.immOrOwnedObject.address);

    final filterCoins = coins
        .where((e) => !ownedObjectAddresses.contains(e.coinObjectId))
        .map((e) => e.toObjectRef())
        .toList();
    if (filterCoins.isEmpty) {
      throw WalletExceptionConst.insufficientBalance;
    }
    return transaction.copyWith(
        gasData: transaction.gasData.copyWith(payment: filterCoins));
  }

  @override
  void dispose() {
    super.dispose();
    _accountsCoins.clear();
  }
}
