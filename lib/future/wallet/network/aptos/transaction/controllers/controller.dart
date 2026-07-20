import 'dart:async';
import 'package:on_chain/aptos/aptos.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/aptos/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/models/networks/aptos/models/types.dart';
import 'package:on_chain_wallet/wallet/models/others/models/receipt_address.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';
import 'fee.dart';
import 'provider.dart';
import 'signer.dart';

abstract class AptosTransactionStateController<T extends IAptosTransactionData>
    extends BaseAptosTransactionController<T>
    with
        AptosTransactionApiController,
        AptosTransactionFeeController,
        AptosTransactionSignerController {
  Token get transferToken;
  AptosTransactionStateController(
      {required super.walletProvider, required super.account, required super.address});

  late final LiveFormFields<AptosTransferDetails> recipients =
      LiveFormFields<AptosTransferDetails>(
          optional: false,
          title: "list_of_recipients".tr,
          subtitle: "amount_for_each_output".tr,
          onValidateError: (field, value) => _validateRecipients(value));

  @override
  TransactionStateStatus getStateStatus() {
    if (!fieldsReady) return TransactionStateStatus.error();
    return super.getStateStatus();
  }

  @override
  Future<void> estimateFee({BigInt? accountBalance}) async {
    if (!fieldsReady) {
      setDefaultFee();
      return;
    }
    return super.estimateFee(accountBalance: address.addressData.balance.value.balance);
  }

  String? _validateRecipients(List<AptosTransferDetails> recipients) {
    if (recipients.isEmpty) {
      return "at_least_one_recipient_required".tr;
    }
    for (final i in recipients) {
      if (!i.hasAmount) return "some_amount_fields_not_filled".tr;
    }
    return null;
  }

  String? filterAccount(AptosAddress address) {
    if (address == this.address.networkAddress ||
        recipients.value.any((e) => e.recipient.networkAddress == address)) {
      return "address_already_exist".tr;
    }
    return null;
  }

  void onUpdateRecipients(List<ReceiptAddress<AptosAddress>> addressess) {
    final recipients = addressess
        .map((e) => AptosTransferDetails(recipient: e, token: transferToken))
        .toList();
    this.recipients.addValues(recipients);
    onStateUpdated();
    estimateFee();
  }

  void onRemoveRecipient(AptosTransferDetails recipient) {
    recipients.removeValue(recipient);
    recipient.dispose();
    onStateUpdated();
    estimateFee();
  }

  @override
  Future<IAptosTransaction<T>> buildTransaction(
      {bool simulate = false, BigInt? maxGasAmount, BigInt? gasUnitPrice}) async {
    final tansactionData = await buildTransactionData();
    final accountSequence =
        await getAccountSequenceNumber(address.networkAddress, cache: simulate);
    final chainId = await getChainId();
    final fee = tansactionData.fee;
    final expire = BigInt.from(
        DateTime.now().add(const Duration(minutes: 2)).millisecondsSinceEpoch ~/ 1000);
    maxGasAmount ??= fee.maxGasAmount;
    gasUnitPrice ??= fee.gasUnitPrice;
    final rawTransaction = AptosRawTransaction(
        sender: address.networkAddress,
        sequenceNumber: accountSequence,
        transactionPayload: tansactionData.toTransactionPayload(),
        maxGasAmount: maxGasAmount,
        gasUnitPrice: gasUnitPrice,
        expirationTimestampSecs: expire,
        chainId: chainId);
    return IAptosTransaction(
        account: address,
        transactionData: tansactionData,
        rawTransaction: rawTransaction);
  }

  @override
  Future<IAptosSignedTransaction<T>> signTransaction(IAptosTransaction<T> transaction,
      {bool fakeSignature = false}) async {
    final address = transaction.account;
    final rawTransaction = transaction.rawTransaction;
    final signatures = await signTransactionInternal(
        rawTransaction: rawTransaction, address: address, fakeSignature: fakeSignature);
    if (fakeSignature) {
      return IAptosSignedTransaction(
          transaction: transaction,
          signatures: [],
          finalTransactionData: AptosSignedTransaction(
              rawTransaction: rawTransaction,
              authenticator: AptosTransactionAuthenticatorSignleSender(
                  AptosAccountAuthenticatorNoAccountAuthenticator())));
    }
    final accountAuthenticators = address.createAccountAuthenticated(signatures);
    return IAptosSignedTransaction(
        transaction: transaction,
        signatures: signatures.map((e) => e.signatureBytes()).toList(),
        finalTransactionData: AptosSignedTransaction(
            rawTransaction: rawTransaction,
            authenticator:
                AptosTransactionAuthenticatorSignleSender(accountAuthenticators)));
  }

  @override
  Future<SubmitTransactionResult> submitTransaction(
      {required IAptosSignedTransaction<T> signedTransaction}) async {
    final result = await client.submitTransaction(signedTransaction.finalTransactionData);
    return SubmitTransactionSuccess(
        txId: result.$1, signedTransaction: signedTransaction);
  }

  @override
  Future<AptosSignedTransaction> simulateTransaction(
      {required BigInt maxGasAmount, required BigInt gasUnitPrice}) async {
    final transaction = await buildTransaction(
        simulate: true, gasUnitPrice: gasUnitPrice, maxGasAmount: maxGasAmount);
    final signedTransaction = await signTransaction(transaction, fakeSignature: true);
    return signedTransaction.finalTransactionData;
  }

  @override
  List<LiveFormField<Object?, Object>> get fields => [recipients];

  @override
  void dispose() {
    for (final i in [...recipients.value]) {
      i.dispose();
    }
    super.dispose();
  }
}
