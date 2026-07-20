import 'dart:async';

import 'package:blockchain_utils/signer/types/eth_signature.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/signing.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

import 'fee.dart';
import 'memo.dart';

abstract class EthereumTransactionStateController<T extends IEthereumTransactionData>
    extends BaseEthereumTransactionController<T>
    with EthereumTransactionFeeController, EthereumTransactionMemoController<T> {
  bool _lockedMax = false;
  bool get lockedMax => _lockedMax;
  EthereumTransactionStateController(
      {required super.walletProvider, required super.account, required super.address});

  Token get transferToken;

  BigInt getMaxInput();

  final LiveFormField<ReceiptAddress<ETHAddress>?, ReceiptAddress<ETHAddress>> receipt =
      LiveFormField(
          title: "recipient".tr,
          subtitle: "receiver_address_desc".tr,
          value: null,
          optional: false);
  late final LiveFormField<IntegerBalance, IntegerBalance> amount = LiveFormField(
    title: "transfer_amount".tr,
    subtitle: "input_the_amout".tr,
    value: IntegerBalance.zero(transferToken),
    optional: false,
    onValidateError: (field, value) {
      if (value.largerThanZero) return null;
      return "field_is_required".tr.replaceOne(field.title.tr);
    },
  );

  void onUpdateAmount(BigInt amount, bool max) {
    _lockedMax = max;
    this.amount.value.updateBalance(max ? getMaxInput() : amount);
    this.amount.notify();
    onStateUpdated();
    if (receipt.hasValue) {
      estimateFee();
    }
  }

  @override
  bool onUpdateMemo(String? memo) {
    final updated = super.onUpdateMemo(memo);
    if (updated) {
      estimateFee();
    }
    return updated;
  }

  @override
  void onRemoveMemo() {
    super.onRemoveMemo();
    estimateFee();
  }

  void onUpdateAddress(ReceiptAddress<ETHAddress>? address) {
    if (address == null) return;
    receipt.setValue(address);
    onStateUpdated();
    if (amount.value.largerThanZero) {
      estimateFee();
    }
  }

  @override
  Future<IEthereumTransaction<T>> buildTransaction({bool simulate = false}) async {
    final txData = await buildTransactionData();
    final fee = txData.fee;
    final transaction = ETHTransaction(
        type: fee.ethereumFeeMode.isEIP1559
            ? ETHTransactionType.eip1559
            : ETHTransactionType.legacy,
        from: address.networkAddress,
        chainId: network.coinParam.chainId,
        data: txData.data,
        nonce: txData.nonce,
        gasPrice: fee.gasPrice,
        maxFeePerGas: fee.maxFeePerGas,
        maxPriorityFeePerGas: fee.maxPriorityFeePerGas,
        gasLimit: BigInt.from(fee.gasLimit),
        value: txData.amount,
        to: txData.recipient);
    return IEthereumTransaction(
        account: address, transactionData: txData, transaction: transaction);
  }

  @override
  Future<IEthereumSignedTransaction<T>> signTransaction(
      IEthereumTransaction<T> transaction,
      {bool fakeSignature = false}) async {
    final ethTransaction = transaction.transaction;
    final WalletSigningRequest<ETHSignature> request = WalletSigningRequest<ETHSignature>(
      addresses: [address],
      network: network,
      sign: (generateSignature) async {
        final signRequest = GlobalSignRequest.eth(
            digest: ethTransaction.serialized, index: address.derivationIndex.cast());
        final ethSignature = await generateSignature(signRequest);
        return ETHSignature.fromBytes(ethSignature.signature);
      },
    );
    final signature = (await walletProvider.wallet
            .signTransaction(params: WalletActionSign(request: request)))
        .unwrap();
    final serializedData =
        BytesUtils.toHexString(ethTransaction.signedSerialized(signature), prefix: "0x");
    return IEthereumSignedTransaction<T>(
        transaction: transaction,
        signatures: [signature.toBytes()],
        finalTransactionData: serializedData);
  }

  @override
  Future<SubmitTransactionResult> submitTransaction(
      {required IEthereumSignedTransaction<T> signedTransaction}) async {
    final txId = await client.sendRawTransaction(signedTransaction.finalTransactionData);
    return SubmitTransactionSuccess<IEthereumSignedTransaction<T>>(
        txId: txId, signedTransaction: signedTransaction);
  }

  @override
  List<LiveFormField<Object?, Object>> get fields => [receipt, amount, memo];
  @override
  Future<TransactionStateController> initForm({
    required BuildContext context,
    required EthereumNetworkClient client,
    bool updateAccount = true,
    bool updateTokens = false,
  }) async {
    await initFee();
    await super.initForm(context: context, client: client, updateAccount: updateAccount);
    return this;
  }
}
