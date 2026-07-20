import 'package:blockchain_utils/utils/atomic/atomic.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:on_chain/tron/tron.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/extension/app_extensions/string.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/fields/fields.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';

import 'provider.dart';

mixin TronTransactionFeeController on TronTransactionApiController {
  final Cancelable _cancelable = Cancelable();
  WalletTronNetwork get network;
  final _lock = SafeAtomicLock();
  bool _isManualFeeLimit = false;

  late final LiveFormField<IntegerBalance, IntegerBalance> feeLimit = LiveFormField(
    title: "fee_limit".tr,
    subtitle: "fee_limit".tr,
    value: IntegerBalance.token(TronHelper.toSun("25"), network.token),
    optional: false,
    onValidateError: (field, value) {
      if (value.largerThanZero) {
        if (txFee.hasFee && value.balance < txFee.fee.fee.balance) {
          return "low_fee_limit_desc".tr;
        }
        return null;
      }
      return "field_is_required".tr.replaceOne(field.title.tr);
    },
  );

  TronTransactionFee get _defaultFee =>
      TronTransactionFee.defaultFee(feeToken: network.token);

  late final TronTransactionFeeData txFee =
      TronTransactionFeeData(select: _defaultFee, feeToken: network.token);

  void _onUpdateFeeLimitInternal(BigInt feeLimit) {
    if (feeLimit == this.feeLimit.value.balance) return;
    this.feeLimit.value.updateBalance(feeLimit);
    this.feeLimit.notify();
  }

  void onUpdateFeeLimit(BigInt feeLimit) {
    _onUpdateFeeLimitInternal(feeLimit);
    _isManualFeeLimit = true;
  }

  void setDefaultFee() {
    txFee.setFee(_defaultFee);
  }

  TronAddress? _getContractDestinationAccount(TronBaseContract contract) {
    if (contract is TransferAssetContract) {
      return contract.toAddress;
    } else if (contract is TransferContract) {
      return contract.toAddress;
    }
    return null;
  }

  Future<TronSimulateTransaction> simulateTransaction();

  Future<TronTransactionFee> simulateFee() async {
    final transaction = await simulateTransaction();
    final rawTransaction = transaction.transaction;
    final contract = rawTransaction.getContract();
    bool isAccountActive = true;
    final destination = _getContractDestinationAccount(contract);
    if (destination != null) {
      isAccountActive = await this.isAccountActive(destination);
    }
    int energy = 0;
    if (contract.contractType == TransactionContractType.triggerSmartContract) {
      energy = await estimateContractTrigger(contract.cast<TriggerSmartContract>());
    } else if (contract.contractType == TransactionContractType.createSmartContract) {
      final sc = contract.cast<CreateSmartContract>();
      energy = await client.estimateCreateContractEnergy(
          ownerAddress: sc.ownerAddress,
          byteCode: BytesUtils.toHexString(sc.newContract.bytecode),
          callTokenValue: sc.callTokenValue,
          tokenID: sc.tokenId);
    }
    final chainParameters = await getChainParameters();
    final fee = TronTransactionFee.calculate(
        raw: rawTransaction,
        chainParameters: chainParameters,
        resource: transaction.accountResource,
        hasMemo: rawTransaction.data != null,
        signature: transaction.totalSigners,
        consumedEnergy: energy,
        isNewAccount: !isAccountActive,
        network: network);
    if (contract.contractType == TransactionContractType.triggerSmartContract &&
        !_isManualFeeLimit) {
      _onUpdateFeeLimitInternal(fee.fee.balance);
    }
    return fee;
  }

  Future<void> estimateFee() async {
    _cancelable.cancel();
    await _lock.run(() async {
      txFee.setFee(_defaultFee);
      txFee.setPending();
      final fee =
          await IResult.call(() async => await simulateFee(), cancelable: _cancelable);
      if (fee.err()?.canceled() ?? false) return;
      if (fee.isErr) {
        txFee.setFee(TronTransactionFee.defaultFee(
            feeToken: network.token, error: fee.err()?.localizationError));
        return;
      }
      txFee.setFee(fee.unwrap());
    });
  }

  @override
  void dispose() {
    super.dispose();
    _cancelable.cancel();
    txFee.dispose();
    feeLimit.dispose();
  }
}
