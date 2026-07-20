import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/transaction/types/operations.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:stellar_dart/stellar_dart.dart';

mixin StellarTransactionApiController on DisposableMixin {
  StellarClient get client;
  final Map<StellarAddress, StellarAccountResponse?> _accountActivities = {};

  Future<void> trackAccountActivity(
      TransactionResourceRequirementStellarAccountActivity receiver) async {
    await receiver.lock.run(() async {
      if (!receiver.status.canTry) return;
      receiver.setPendig();
      final result = await IResult.call(() async {
        if (_accountActivities.containsKey(receiver.address.networkAddress)) {
          return _accountActivities[receiver.address.networkAddress];
        }
        _accountActivities[receiver.address.networkAddress] =
            await client.getAccount(receiver.address.networkAddress);
        return _accountActivities[receiver.address.networkAddress];
      });
      if (result.isErr) {
        receiver.setError();
      } else {
        receiver.setResource(result.unwrap());
      }
    });
  }

  Future<StellarAccountResponse?> getAccount(StellarAddress address) async {
    return await client.getAccount(address);
  }

  Future<int> getBaseReserve() async {
    final result = await client.getBaseReserve();
    return result;
  }

  Future<StellarFeeStatsResponse> feeState() async {
    final result = await client.feeState();
    return result;
  }
}
