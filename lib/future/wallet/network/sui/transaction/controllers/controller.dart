import 'dart:async';
import 'package:on_chain/sui/src/address/address/address.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/sui/transaction/controllers/signer.dart';
import 'package:on_chain_wallet/future/wallet/network/sui/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'fee.dart';
import 'package:on_chain/sui/src/transaction/types/types.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/future/wallet/network/sui/web3/types/types.dart';
import 'provider.dart';

abstract class SuiTransactionStateController<T extends ISuiTransactionData>
    extends BaseSuiTransactionController<T>
    with
        SuiTransactionApiController,
        SuiTransactionFeeController,
        SuiTransactionSignerController {
  Token get transferToken;
  SuiTransactionStateController(
      {required super.walletProvider, required super.account, required super.address});

  late final LiveFormFields<SuiTransferDetails> recipients =
      LiveFormFields<SuiTransferDetails>(
          optional: false,
          title: "list_of_recipients".tr,
          subtitle: "amount_for_each_output".tr,
          onValidateError: (_, value) => _validateRecipients(value));

  @override
  Future<void> estimateFee() async {
    if (!fieldsReady) {
      setDefaultFee();
      return;
    }
    return super.estimateFee();
  }

  String? _validateRecipients(List<SuiTransferDetails> recipients) {
    if (recipients.isEmpty) {
      return "at_least_one_recipient_required".tr;
    }
    for (final i in recipients) {
      if (!i.hasAmount) return "some_amount_fields_not_filled".tr;
    }
    return null;
  }

  String? filterAccount(SuiAddress address) {
    if (address == this.address.networkAddress ||
        recipients.value.any((e) => e.recipient.networkAddress == address)) {
      return "address_already_exist".tr;
    }
    return null;
  }

  void onUpdateRecipients(List<ReceiptAddress<SuiAddress>> addressess) {
    final recipients = addressess
        .map((e) => SuiTransferDetails(recipient: e, token: transferToken))
        .toList();
    this.recipients.addValues(recipients);
    onStateUpdated();
    estimateFee();
  }

  void onRemoveRecipient(SuiTransferDetails recipient) {
    recipients.removeValue(recipient);
    recipient.dispose();
    onStateUpdated();
    estimateFee();
  }

  @override
  void onAccountUpdated() {
    super.onAccountUpdated();
    getAccountCoins(address.networkAddress, cachedTimeout: Duration.zero);
  }

  SuiTransactionDataV1 buildTransferSingleCoin(
      {required BigInt gasPrice,
      required BigInt budget,
      required SuiAddress owner,
      required List<ITransactionDataTransferRecipient<SuiAddress>> recipients,
      SuiObjectRef? object}) {
    final destionations = recipients;
    final index = object == null ? 0 : 1;
    final splitCoins = SuiCommandSplitCoins(
        amounts: List.generate(destionations.length, (i) {
          return SuiArgumentInput(index + i);
        }),
        coin: object == null ? SuiArgumentGasCoin() : SuiArgumentInput(0));
    final amounts = destionations.map((e) => SuiCallArgPure.u64(e.amount)).toList();
    final addresses = destionations.map((e) => e.recipient).toList();
    final transfers = List.generate(destionations.length, (i) {
      return SuiCommandTransferObjects(objects: [
        SuiArgumentNestedResult(commandIndex: 0, resultIndex: i),
      ], address: SuiArgumentInput(index + i + amounts.length));
    });
    final kind = SuiProgrammableTransaction(inputs: [
      if (object != null) SuiCallArgObject(SuiObjectArgImmOrOwnedObject(object)),
      ...amounts,
      ...addresses,
    ], commands: [
      splitCoins,
      ...transfers
    ]);
    return SuiTransactionDataV1(
        expiration: const SuiTransactionExpirationNone(),
        sender: owner,
        gasData: SuiGasData(payment: [], owner: owner, price: gasPrice, budget: budget),
        kind: SuiTransactionKindProgrammableTransaction(kind));
  }

  @override
  Future<ISuiSignedTransaction<T>> signTransaction(ISuiTransaction<T> transaction,
      {bool fakeSignature = false}) async {
    final transactionWithGas = await filledGasPayment(transaction.transaction);
    final signedTx =
        await signTransactionInternal(transaction: transactionWithGas, signer: address);
    return ISuiSignedTransaction(
        transaction: ISuiTransaction(
            account: address,
            transactionData: transaction.transactionData,
            transaction: transactionWithGas),
        signatures: signedTx.signatures,
        finalTransactionData: transactionWithGas,
        suiSignature: signedTx.suiSignature);
  }

  @override
  Future<ISuiTransaction<T>> buildTransaction(
      {bool simulate = false, BigInt? gasPrice, BigInt? budget});

  @override
  Future<SuiTransactionDataV1> simulateTransaction(
      {required BigInt gasPrice, required BigInt budget}) async {
    final transaction =
        await buildTransaction(simulate: true, gasPrice: gasPrice, budget: budget);
    return transaction.transaction;
  }

  @override
  Future<SubmitTransactionResult> submitTransaction(
      {required ISuiSignedTransaction<T> signedTransaction}) async {
    final txId = await client.excuteTx(
        tx: signedTransaction.finalTransactionData,
        signatures: [signedTransaction.suiSignature]);
    return SubmitTransactionSuccess(
        txId: txId.digest, warning: txId.error, signedTransaction: signedTransaction);
  }

  @override
  void dispose() {
    super.dispose();
    for (final i in [...recipients.value]) {
      i.dispose();
    }
  }

  @override
  List<LiveFormField<Object?, Object>> get fields => [recipients];
}
