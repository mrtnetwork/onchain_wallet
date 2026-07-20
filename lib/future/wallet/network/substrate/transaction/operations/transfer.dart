import 'dart:async';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain/ethereum/src/address/evm_address.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/transaction/operations/transfer_token.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/transaction/widgets/transfer.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:polkadot_dart/polkadot_dart.dart';

class SubstrateTransactionTransferOperation
    extends SubstrateTransactionStateController<ISubstrateTransactionData> {
  SubstrateToken? _transferToken;
  SubstrateTransactionTransferOperation(
      {required super.walletProvider,
      required super.account,
      required super.address,
      SubstrateToken? transferToken})
      : _transferToken = transferToken;

  bool get allowAddTransfer => supportBatch || recipients.value.isEmpty;
  SubstrateTransferDetails? _lockedMax;
  IntegerBalance? _existentialDeposit;
  bool get supportAssetTransfer => metadata.supportTokenTransfer;

  late final LiveFormFields<SubstrateTransferDetails> recipients =
      LiveFormFields<SubstrateTransferDetails>(
          optional: false,
          title: "list_of_recipients".tr,
          subtitle: "amount_for_each_output".tr,
          onValidateError: (_, value) => _validateRecipients(value));

  String? _validateRecipients(List<SubstrateTransferDetails> recipients) {
    if (recipients.isEmpty) {
      return "at_least_one_recipient_required".tr;
    }
    for (final i in recipients) {
      if (!i.hasAmount) return "some_amount_fields_not_filled".tr;
    }
    return null;
  }

  String? filterAccount(BaseSubstrateAddress address) {
    if (address == this.address.networkAddress) {
      return "address_already_exist".tr;
    }
    return null;
  }

  void onUpdateRecipients(List<ReceiptAddress<BaseSubstrateAddress>> addressess) {
    SubstrateTransferToken token = nativeToken;
    final requestToken = _transferToken;
    if (requestToken != null) {
      token = tokens.firstWhere((e) => e.tokenDetails.asset == requestToken,
          orElse: () => token);
      _transferToken = null;
    }
    final recipients = addressess
        .map((e) => SubstrateTransferDetails(recipient: e, token: token))
        .toList();
    this.recipients.addValues(recipients);
    onStateUpdated();
    estimateFee();
  }

  void onRemoveRecipients(SubstrateTransferDetails recipient) {
    _lockedMax = null;
    recipients.removeValue(recipient);
    recipient.dispose();
    onStateUpdated();
    estimateFee();
  }

  BigInt getMaxInput(SubstrateTransferDetails recipient) {
    final token = recipient.token;
    final feeToken = this.feeToken.value;
    final internalAsset = token.tokenDetails.internalAsset;
    final sameTransfers = recipients.value.where((e) => e.token == token);
    bool keepAlive = sameTransfers.any((e) => e.method?.keepAlive ?? false);
    BigInt total =
        sameTransfers.fold<BigInt>(BigInt.zero, (p, c) => p + c.amount.balance);
    total -= recipient.amount.balance;
    if (token == feeToken || (token.isNativeAsset && feeToken == null)) {
      total += txFee.fee.fee.balance;
    }
    if (keepAlive) {
      final existentialDeposit = _existentialDeposit?.balance ?? BigInt.zero;
      if (token.isNativeAsset) {
        total += existentialDeposit;
      } else if (internalAsset.minBalance != null) {
        total += internalAsset.minBalance!;
      }
    }
    final remain = token.tokenDetails.balance.value.balance - total;
    if (remain.isNegative) return BigInt.zero;
    return remain;
  }

  void onUpdateToken(SubstrateTransferDetails recipient, SubstrateTokenDetails? token) {
    if (token == null) return;
    final correctToken = tokens.firstWhereOrNull((e) => e.tokenDetails == token);
    if (correctToken == null || correctToken == recipient.token) return;
    // _lockedMax = max ? recipient : null;
    recipient.onUpdateToken(correctToken);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateTransferMethod(
      SubstrateTransferDetails recipient, SubstrateCallPalletTransferMethod? method) {
    if (method == null || method == recipient.method) return;
    recipient.onUpdateTransferMethod(method);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateAmount(SubstrateTransferDetails recipient, BigInt amount, bool max) {
    if (recipient.token.isNativeAsset) {
      _lockedMax = max ? recipient : null;
    }
    recipient.onUpdateBalance(amount);
    onStateUpdated();
    estimateFee();
  }

  @override
  void onFeeUpdated(void _) {
    if (!txFee.isPending) {
      final last = _lockedMax;
      if (last != null) {
        last.onUpdateBalance(getMaxInput(last));
        _lockedMax = null;
      }
    }
    onStateUpdated();
  }

  @override
  Future<void> estimateFee() async {
    if (!fieldsReady) return;
    return super.estimateFee();
  }

  TransactionStateStatus? _getTokenStatus(SubstrateTransferToken? token) {
    final feeToken = this.feeToken.value;
    final internalAsset = token?.tokenDetails.internalAsset;
    final bool isNativeAsset = token?.isNativeAsset ?? true;
    final balance =
        token?.tokenDetails.balance.value.balance ?? address.addressData.currencyBalance;
    final assetToken = token?.token ?? network.token;
    List<SubstrateTransferDetails> sameTransfers;
    if (token != null) {
      sameTransfers = recipients.value.where((e) => e.token == token).toList();
    } else {
      sameTransfers = recipients.value.where((e) => e.token.isNativeAsset).toList();
    }
    bool keepAlive = sameTransfers.any((e) => e.method?.keepAlive ?? false);
    BigInt total =
        sameTransfers.fold<BigInt>(BigInt.zero, (p, c) => p + c.amount.balance);
    if (token == feeToken || (isNativeAsset && feeToken == null)) {
      total += txFee.fee.fee.balance;
    }
    BigInt remain = balance - total;
    if (remain.isNegative) {
      return TransactionStateStatus.insufficient(
          IntegerBalance.token(remain, assetToken));
    }
    if (keepAlive) {
      final existentialDeposit = isNativeAsset
          ? (_existentialDeposit?.balance ?? BigInt.zero)
          : (internalAsset?.minBalance ?? BigInt.zero);
      remain -= existentialDeposit;
      if (remain.isNegative) {
        final minBalance = IntegerBalance.token(existentialDeposit, assetToken);
        return TransactionStateStatus.error(
            error: "substrate_keep_alive_min_desc".tr.replaceOne(
                PriceUtils.priceWithCoinName(minBalance.viewPrice, assetToken.symbol)));
      }
    }
    return null;
  }

  @override
  TransactionStateStatus getStateStatus() {
    final status = super.getStateStatus();
    if (!status.isReady) return status;
    String? simulateError =
        txFee.fee.hasError ? "transaction_simulation_failed".tr : null;
    final tokens = recipients.value.map((e) => e.token).toSet();
    for (final i in tokens) {
      final status = _getTokenStatus(i);
      if (status == null) continue;
      return status;
    }
    if (!tokens.contains(feeToken.value)) {
      final feeTokenStatus = _getTokenStatus(feeToken.value);
      if (feeTokenStatus != null) return feeTokenStatus;
    }
    return TransactionStateStatus.ready(warning: simulateError);
  }

  Future<SubstrateCallPallet> _toCalls() async {
    final memos = this.memos.value;
    final remarks =
        memos.map((e) => SystemCallPalletRemark(value: StringUtils.toBytes(e)));
    final messages = await Future.wait(recipients.value.map((e) => e.createCall(
        metadata: client.metadataWitPorvider(),
        owner: address.networkAddress,
        controller: client.metadata.controller)));
    final calls = [...messages, ...remarks];
    final bool batch = calls.length > 1;
    if (batch) {
      return UtilityCallPalletBatchAll(calls: calls);
    }
    return calls.first;
  }

  @override
  Future<ISubstrateTransaction> buildTransaction({bool simulate = false}) async {
    final transactionData = await buildTransactionData(simulate: simulate);
    BigInt nonce = BigInt.zero;
    if (!simulate) {
      nonce = await getAccountNonce(address.networkAddress);
    }
    final blockInfo = await finalizeBlockWithEra();
    final List<int> genesis = metadata.genesisBytes();
    final call = await _toCalls();
    final messageBytes = call.encodeCall(extrinsic: metadata.metadataWithExtrinsic());
    final extrinsic = DynamicExtrinsicBuilder(
        era: blockInfo.era,
        nonce: nonce,
        specVersion: metadata.runtimeVersion.specVersion,
        transactionVersion: metadata.runtimeVersion.transactionVersion,
        chargeAssetTxPayment: transactionData.feeAssetConfig?.feeId,
        genesis: genesis,
        mortality: blockInfo.blockHashBytes,
        metadataFields: metadata.extrinsic);
    final extraFields = extrinsic.encodeExtrinsicPayload(metadata.metadata);
    final List<int> encodeBytes = [...messageBytes, ...extraFields].asImmutableBytes;
    final extrinsicInfo = ExtrinsicPayloadInfo(
        serializedExtrinsic: encodeBytes, method: messageBytes, extrinsic: extrinsic);

    return ISubstrateTransaction(
        account: address, transactionData: transactionData, payload: extrinsicInfo);
  }

  @override
  Future<ISubstrateTransactionData> buildTransactionData({bool simulate = false}) async {
    final payments = recipients.value
        .map((e) => ISubstrateTransactionDataTokenTransfer(
            recipient: e.recipient.networkAddress,
            amount: e.amount.balance,
            token: e.token.tokenDetails.asset))
        .toList();
    return ISubstrateTransactionData(
        fee: txFee.fee, payment: payments, feeAssetConfig: feeToken.value?.feeConfig);
  }

  @override
  Future<List<IWalletTransaction<SubstrateWalletTransaction, ISubstrateAddress>>>
      buildWalletTransaction(
          {required ISubstrateSignedTransaction signedTx,
          required SubmitSubstrateTransactionSuccess txId}) async {
    final destinations = signedTx.transaction.transactionData.payment ?? [];
    final outputs = destinations
        .map((e) => SubstrateWalletTransactionTransferOutput(
            to: e.recipient,
            amount: WalletTransactionIntegerAmount(
                amount: e.amount, network: network, token: e.token?.token)))
        .toList();
    final tokens = destinations.map((e) => e.token).toSet();
    WalletTransactionIntegerAmount? totalOutput;
    if (tokens.length == 1) {
      totalOutput = WalletTransactionIntegerAmount(
          amount: destinations.map((e) => e.amount).sum,
          network: network,
          token: tokens.first?.token);
    } else {
      final nativeAmount =
          destinations.where((e) => e.token == null).map((e) => e.amount).sum;
      if (nativeAmount > BigInt.zero) {
        totalOutput =
            WalletTransactionIntegerAmount(amount: nativeAmount, network: network);
      }
    }
    final transaction = SubstrateWalletTransaction(
        txId: txId.txId,
        network: network,
        block: txId.block!,
        outputs: outputs,
        totalOutput: totalOutput,
        extrinsics: signedTx.finalTransactionData.serializeHex());
    return [
      IWalletTransaction(transaction: transaction, account: signedTx.transaction.account)
    ];
  }

  @override
  Future<TransactionStateController> cloneController(ISubstrateAddress address) async {
    return SubstrateTransactionTransferOperation(
        walletProvider: walletProvider, account: account, address: address);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return SubstrateTransactionTransferWidget(
      form: this,
      mainContext: context,
    );
  }

  @override
  Future<TransactionStateController> initForm({
    required BuildContext context,
    required SubstrateNetworkClient client,
    bool updateAccount = true,
    bool updateTokens = false,
  }) async {
    final controller = client.metadata.controller;
    final transferToken = _transferToken;
    if (transferToken != null && controller != null) {
      final chainId = switch (controller) {
        final BaseMoonbeamNetworkController controller => controller.chainId,
        _ => null
      };
      if (chainId != null) {
        final evmChain = walletProvider.wallet
            .getChains<EthereumChain>()
            .firstWhereNullable((e) => e.chainId == chainId);
        if (evmChain == null) {
          throw AppException("eth_chain_not_found_send_transaction_desc"
              .tr
              .replaceOne(network.networkName));
        }
        await evmChain.initAsMainNetwork();
        final address = evmChain.addresses.firstWhereOrNull((e) => StringUtils.hexEqual(
            e.networkAddress.address, this.address.networkAddress.address));
        if (address == null) {
          throw AppException(
              "missing_ethereum_account".tr.replaceOne(evmChain.network.networkName));
        }
        final contractAddress = ETHAddress(
            MoonbeamNetworkControllerUtils.formatAssetIdToERC20(
                    transferToken.assetIdentifier.toString())
                .address);
        final tokens = (await address.getAccountTokens()).unwrap();
        final token = tokens.firstWhere(
          (e) => e.contractAddress == contractAddress,
          orElse: () {
            return ETHERC20Token.create(
                balance: transferToken.balance.balance,
                token: transferToken.token,
                contractAddress: contractAddress);
          },
        );
        return EthereumTransactionTransferTokenOperation(
            address: address,
            account: evmChain,
            walletProvider: walletProvider,
            token: token);
      }
    }

    await super.initForm(client: client, context: context, updateAccount: updateAccount);
    if (!client.metadata.supportNativeTransfer) {
      throw AppException("substrate_disable_transfer_option_desc");
    }
    final existentialDeposit = metadata.existentialDeposit;
    if (existentialDeposit != null) {
      _existentialDeposit = IntegerBalance.token(existentialDeposit, network.token);
    }
    return this;
  }

  @override
  TransactionOperations get operation => SubstrateTransactionOperations.transfer;

  @override
  void dispose() {
    for (final i in recipients.value) {
      i.dispose();
    }
    super.dispose();
  }

  @override
  List<LiveFormField<Object?, Object>> get fields => [recipients];
}

/// 50000262
