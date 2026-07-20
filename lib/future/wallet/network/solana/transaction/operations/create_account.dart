import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/transaction/widgets/create_account.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class SolanaTransactionCreateAccountOperation extends SolanaTransactionStateController {
  final _lock = SafeAtomicLock();
  final Cancelable _cancelable = Cancelable();
  SolanaTransactionCreateAccountOperation(
      {required super.walletProvider, required super.account, required super.address});
  final LiveFormField<ReceiptAddress<SolAddress>, ReceiptAddress<SolAddress>> programId =
      LiveFormField(
          title: "program_id".tr,
          value: ReceiptAddress<SolAddress>(
              view: SPLTokenProgramConst.tokenProgramId.address,
              type: null,
              networkAddress: SPLTokenProgramConst.tokenProgramId),
          optional: false);

  final LiveFormField<ReceiptAddress<SolAddress>?, ReceiptAddress<SolAddress>>
      newAccountAddress = LiveFormField(
          title: "new_account_address".tr,
          subtitle: "solana_new_account_desc".tr,
          optional: false,
          value: null);
  final LiveFormField<BigRational?, BigRational> accountSize = LiveFormField(
      title: "account_size".tr,
      subtitle: "solana_account_size_desc".tr,
      optional: false,
      value: null);

  late final LiveFormField<TransactionResourceRequirementSolanaRentData,
      TransactionResourceRequirementSolanaRentData> rent = LiveFormField(
    title: "lamports".tr,
    subtitle: "solana_create_account_lamports_desc".tr,
    optional: false,
    onValidateError: (field, value) {
      if (!value.value.largerThanZero) {
        return "amount_required_for_create_account".tr;
      }
      return null;
    },
    value: TransactionResourceRequirementSolanaRentData(
        value: IntegerBalance.zero(network.token),
        status: TransactionResourceRequirementFetchStatus.idle),
  );

  BigInt getMaxInput() {
    final max = address.addressData.currencyBalance -
        (SolanaConst.solanaDefaultTxFeePerSignature * BigInt.from(2));
    if (max.isNegative) return BigInt.zero;
    return max;
  }

  Future<void> getRequiredRentData() async {
    final size = accountSize.value;
    if (size == null) return;
    _cancelable.cancel();
    await _lock.run(() async {
      final value = this.rent.value;
      if (value.status.isManual) return;
      this.rent.setValue(TransactionResourceRequirementSolanaRentData(
          value: IntegerBalance.zero(network.token),
          status: TransactionResourceRequirementFetchStatus.pending));
      final rent = await IResult.call(() async {
        return client.getRent(size.toBigInt().toInt());
      }, cancelable: _cancelable);
      if (rent.err()?.canceled() ?? false) return;
      if (rent.isErr) {
        this.rent.setValue(TransactionResourceRequirementSolanaRentData(
            value: IntegerBalance.zero(network.token),
            status: TransactionResourceRequirementFetchStatus.failed,
            error: rent.unwrapErr().localizationError));
        return;
      }
      this.rent.setValue(TransactionResourceRequirementSolanaRentData(
          value: IntegerBalance.token(rent.unwrap(), network.token),
          status: TransactionResourceRequirementFetchStatus.success));
      estimateFee();
    });
  }

  void onUpdateNewAccountAddress(ReceiptAddress<SolAddress>? address) {
    if (address == null) return;
    newAccountAddress.setValue(address);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateProgramId(ReceiptAddress<SolAddress>? address) {
    if (address == null) return;
    programId.setValue(address);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateAccountSize(BigRational size) {
    accountSize.setValue(size);
    getRequiredRentData();
    onStateUpdated();
    estimateFee();
  }

  void onUpdateRentAmount(BigInt amount) {
    rent.setValue(TransactionResourceRequirementSolanaRentData(
        value: IntegerBalance.token(amount, network.token),
        status: TransactionResourceRequirementFetchStatus.manual));
    onStateUpdated();
    estimateFee();
  }

  @override
  Future<TransactionStateController> cloneController(ISolanaAddress address) async {
    return SolanaTransactionCreateAccountOperation(
        walletProvider: walletProvider, account: account, address: address);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return SolanaTransactionCreateAccountWidget(form: this);
  }

  @override
  TransactionOperations get operation => SolanaTransactionOperations.createAccount;

  @override
  Future<ISolanaTransactionData> buildTransactionData({bool simulate = false}) async {
    final blockHash = await getTransactionBlockHash(simulate: simulate);
    return ISolanaTransactionData(
        fee: txFee.fee,
        memo: memo.value,
        instructions: [
          SystemProgram.createAccount(
              from: address.networkAddress,
              newAccountPubKey: newAccountAddress.value!.networkAddress,
              layout: SystemCreateLayout(
                  lamports: rent.value.value.balance,
                  space: accountSize.value!.toBigInt(),
                  programId: programId.value.networkAddress))
        ],
        blockHash: blockHash);
  }

  @override
  Future<List<IWalletTransaction<SolanaWalletTransaction, ISolanaAddress>>>
      buildWalletTransaction(
          {required ISolanaSignedTransaction signedTx,
          required SubmitTransactionSuccess txId}) async {
    final memo = signedTx.transaction.transactionData.getWalletTxMemo();
    final transaction = SolanaWalletTransaction(
        txId: txId.txId,
        memos: [if (memo != null) memo],
        outputs: [SolanaWalletTransactionOperationOutput(name: operation.value.tr)],
        network: network,
        totalOutput: WalletTransactionIntegerAmount(
            amount: rent.value.value.balance, network: network));
    return [IWalletTransaction(transaction: transaction, account: address)];
  }

  @override
  List<LiveFormField<Object?, Object>> get fields =>
      [newAccountAddress, accountSize, rent, programId];

  @override
  void dispose() {
    _cancelable.cancel();
    super.dispose();
  }
}
