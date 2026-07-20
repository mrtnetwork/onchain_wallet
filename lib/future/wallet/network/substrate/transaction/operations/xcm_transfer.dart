import 'dart:async';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/transaction/types/xcm_types.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/transaction/widgets/xcm_transfer.dart';
import 'package:on_chain_wallet/future/wallet/transaction/pages/xcm_submited_transaction_widget.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:polkadot_dart/polkadot_dart.dart';

class SubstrateTransactionXCMTransferOperation
    extends SubstrateTransactionStateController<ISubstrateXCMTransactionData> {
  late SubstrateXCMTransferRequirement _requirement;
  SubstrateTransactionXCMTransferOperation(
      {required super.walletProvider, required super.account, required super.address});

  bool get allowAddTransfer => supportBatch;
  IntegerBalance? _existentialDeposit;
  bool get supportAssetTransfer => metadata.supportTokenTransfer;
  List<SubstrateChain> get routes => _requirement.destinations;
  StreamSubscription? _trakcerSubscription;
  SubmitedXCMTransferDestinationTracker? _tracker;
  late final LiveFormField<SubstrateXCMTransferDetails?, SubstrateXCMTransferDetails>
      destination = LiveFormField(
          optional: false,
          title: "destination_network".tr,
          subtitle: "choose_network_transfer_to_desc".tr,
          value: null);

  String? filterAccount(BaseSubstrateAddress address) {
    if (address == this.address.networkAddress) {
      return "address_already_exist".tr;
    }
    return null;
  }

  StreamSubscription<void>? _transferSubscription;

  void _onTransferEvents(SubstrateXCMTransferDetails transfer) {
    onStateUpdated();
    if (transfer.isReady) {
      estimateFee();
    }
  }

  void onUpdateDestination(SubstrateChain? network) {
    if (network == null) return;
    _transferSubscription?.cancel();
    _transferSubscription = null;
    final currentTransfer = destination.value;
    final transfer = SubstrateXCMTransferDetails(
        transferAssets: tokens,
        origin: _requirement.routes.firstWhere((e) => e.network == account),
        destinationChain: _requirement.routes.firstWhere((e) => e.network == network),
        address: address,
        relayNetworks: _requirement.routes);
    _transferSubscription = transfer.stream.listen((_) => _onTransferEvents(transfer));
    destination.setValue(transfer);
    transfer.init();
    onStateUpdated();
    currentTransfer?.dispose();
  }

  void onUpdateToken(SubstrateXCMTransferDetails transfer, SubstrateTokenDetails? token) {
    if (token == null) return;
    transfer.onUpdateToken(token);
    onStateUpdated();
  }

  void onUpdateDestinationFeeToken(
      SubstrateXCMTransferDetails transfer, SubstrateXCMTokenDetails? token) {
    if (token == null) return;
    transfer.onUpdateDestinationFeeToken(token);
    onStateUpdated();
  }

  void onUpdateReceipt(SubstrateXCMTransferDetails recipient,
      ReceiptAddress<BaseSubstrateAddress>? address) {
    if (address == null) return;
    recipient.onUpdateReceipt(address);
    onStateUpdated();
  }

  BigInt getMaxInput(SubstrateXCMTransferToken recipient) {
    final token = recipient.token;
    final feeToken = this.feeToken.value;
    final sameTransfers = destination.value?.transfers
            .where((e) => e.token.tokenDetails == token.tokenDetails)
            .toList() ??
        [];
    BigInt total =
        sameTransfers.fold<BigInt>(BigInt.zero, (p, c) => p + c.amount.balance);
    total -= recipient.amount.balance;
    if (token.tokenDetails == feeToken?.tokenDetails ||
        (token.isNativeAsset && feeToken == null)) {
      total += txFee.fee.fee.balance;
    }
    if (recipient.token.isNativeAsset) {
      total += (destination.value?.deliveriesFee.balance ?? BigInt.zero);
    }
    final existentialDeposit = _existentialDeposit?.balance ?? BigInt.zero;
    if (token.isNativeAsset) {
      total += existentialDeposit;
    } else if (token.tokenDetails.internalAsset.minBalance != null) {
      total += token.tokenDetails.internalAsset.minBalance!;
    }
    final remain = token.tokenDetails.balance.value.balance - total;
    if (remain.isNegative) return BigInt.zero;
    return remain;
  }

  /// 999999990000000000
  void onRemoveTransfer(
      SubstrateXCMTransferDetails destination, SubstrateXCMTransferToken transfer) {
    destination.onRemoveTransfer(transfer);
    onStateUpdated();
  }

  void onUpdateAmount(SubstrateXCMTransferDetails destination,
      SubstrateXCMTransferToken transfer, BigInt amount, bool max) {
    destination.onUpdateAmount(transfer, amount, max);
    onStateUpdated();
  }

  @override
  void onFeeUpdated(void _) {
    final deliveriesFee = destination.value?.deliveriesFee;
    final bool updateFee = !txFee.isPending &&
        txFee.fee.xcmDeliveriesFee == null &&
        deliveriesFee != null &&
        deliveriesFee.balance > BigInt.zero &&
        !txFee.fee.hasError;
    if (updateFee) {
      final fee = txFee.fee.copyWith(xcmDeliveriesFee: deliveriesFee);
      txFee.setFee(fee);
      return;
    }
    onStateUpdated();
  }

  @override
  Future<void> estimateFee() async {
    if (!fieldsReady) return;
    return super.estimateFee();
  }

  TransactionStateStatus? _getTokenStatus(SubstrateTokenDetails? token) {
    final feeToken = this.feeToken.value;
    // final internalAsset = token?.internalAsset;
    final bool isNativeAsset = token?.isNativeAsset ?? true;
    final balance = token?.balance.value.balance ?? address.addressData.currencyBalance;
    final assetToken = token?.token ?? network.token;
    List<SubstrateXCMTransferToken> sameTransfers;
    final recipients = destination.value?.transfers ?? [];
    if (token != null) {
      sameTransfers = recipients.where((e) => e.token.tokenDetails == token).toList();
    } else {
      sameTransfers = recipients.where((e) => e.token.isNativeAsset).toList();
    }
    BigInt total =
        sameTransfers.fold<BigInt>(BigInt.zero, (p, c) => p + c.amount.balance);
    if (token == feeToken?.tokenDetails || (isNativeAsset && feeToken == null)) {
      total += txFee.fee.fee.balance;
    }
    if (token == null || isNativeAsset) {
      total += (destination.value?.deliveriesFee.balance ?? BigInt.zero);
    }
    BigInt remain = balance - total;

    if (remain.isNegative) {
      return TransactionStateStatus.insufficient(
          IntegerBalance.token(remain, assetToken));
    }
    return null;
  }

  @override
  TransactionStateStatus getStateStatus() {
    final status = super.getStateStatus();
    if (!status.isReady) return status;
    final destination = this.destination.value?.getStateStatus();
    if (destination != null && !destination.isReady) {
      return TransactionStateStatus.error(error: destination.error);
    }

    String? simulateError = destination?.warning ??
        (txFee.fee.hasError ? "transaction_simulation_failed".tr : null);
    final tokens = [];
    for (final i in tokens) {
      final status = _getTokenStatus(i);
      if (status == null) continue;
      return status;
    }
    if (!tokens.contains(feeToken.value)) {
      final feeTokenStatus = _getTokenStatus(feeToken.value?.tokenDetails);
      if (feeTokenStatus != null) return feeTokenStatus;
    }
    return TransactionStateStatus.ready(warning: simulateError);
  }

  Future<SubstrateCallPallet> _toCalls(SubstrateXCMTransferEncodedParams xcmParam) async {
    final memos = this.memos.value;
    final remarks =
        memos.map((e) => SystemCallPalletRemark(value: StringUtils.toBytes(e)));
    final calls = [xcmParam.transfer, ...remarks];
    final bool batch = calls.length > 1;
    if (batch) {
      return UtilityCallPalletBatchAll(calls: calls);
    }
    return calls.first;
  }

  @override
  Future<ISubstrateTransaction<ISubstrateXCMTransactionData>> buildTransaction(
      {bool simulate = false}) async {
    final transactionData = await buildTransactionData(simulate: simulate);
    BigInt nonce = BigInt.zero;
    if (!simulate) {
      nonce = await getAccountNonce(address.networkAddress);
    }
    final blockInfo = await finalizeBlockWithEra();
    final List<int> genesis = metadata.genesisBytes();
    final call = await _toCalls(transactionData.xcmParams.xcmParams);
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
  Future<ISubstrateXCMTransactionData> buildTransactionData(
      {bool simulate = false}) async {
    final transfer = destination.output;
    final xcmParams = await transfer.createCall();
    final payments = transfer.transfers
        .map((e) => ISubstrateTransactionDataTokenTransfer(
            recipient: transfer.receipt!.networkAddress,
            amount: e.amount.balance,
            token: e.token.tokenDetails.asset))
        .toList();
    return ISubstrateXCMTransactionData(
        fee: txFee.fee,
        payment: payments,
        destination: transfer.destinationChain.network,
        xcmParams: xcmParams,
        feeAssetConfig: feeToken.value?.feeConfig);
  }

  Future<List<IWalletTransaction<SubstrateWalletTransaction, ISubstrateAddress>>>
      _buildWalletTransaction(
          {required ISubstrateSignedTransaction signedTx,
          required String txId,
          required int? block}) async {
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
        txId: txId,
        network: network,
        block: block,
        outputs: outputs,
        totalOutput: totalOutput,
        extrinsics: signedTx.finalTransactionData.serializeHex());
    return [
      IWalletTransaction(transaction: transaction, account: signedTx.transaction.account)
    ];
  }

  @override
  Future<List<IWalletTransaction<SubstrateWalletTransaction, ISubstrateAddress>>>
      buildWalletTransaction(
          {required ISubstrateSignedTransaction signedTx,
          required SubmitSubstrateTransactionSuccess txId}) async {
    return txId.txes;
  }

  @override
  Future<TransactionStateController> cloneController(ISubstrateAddress address) async {
    return SubstrateTransactionXCMTransferOperation(
        walletProvider: walletProvider, account: account, address: address);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return SubstrateTransactionXCMTransferWidget(form: this, mainContext: context);
  }

  @override
  Widget onTxCompleteWidget(
      {required SubstrateWalletTransaction? transaction,
      required SubmitSubstrateTransactionSuccess<ISubstrateXCMTransactionData> txId,
      required SubstrateChain account}) {
    final tracker = txId.xcmTransferDestinationTracker;
    if (tracker == null) {
      return super
          .onTxCompleteWidget(transaction: transaction, txId: txId, account: account);
    }
    return SuccessXCMTransactionTextView(
        txId: txId.txId,
        warning: txId.warning,
        account: account,
        transaction: transaction,
        destinationTracker: tracker);
  }

  @override
  Future<SubmitSubstrateTransactionSuccess<ISubstrateXCMTransactionData>>
      submitTransaction(
          {required ISubstrateSignedTransaction<ISubstrateXCMTransactionData>
              signedTransaction}) async {
    _trakcerSubscription?.cancel();
    _trakcerSubscription = null;
    _tracker?.dispose();
    _tracker = null;
    final Completer<SubstrateTxIdWithBlock> result = Completer();
    final txData = signedTransaction.transaction.transactionData;
    final xcm = txData.xcmParams;
    List<IWalletTransaction<SubstrateWalletTransaction, ISubstrateAddress>> txes =
        const [];
    final stream = await xcm.origin.submitXCMTransaction(
        owner: signedTransaction.transaction.account.networkAddress,
        transaction: SubstrateSubmitableTransaction(
            extrinsic: BytesUtils.fromHexString(
                signedTransaction.finalTransactionData.serializedExtrinsic)),
        destinationChainController: xcm.destination,
        params: xcm.xcmParams,
        onDestinationChainEvent: (event) {
          _tracker?.onUpdateEvent(event);
        },
        onUpdateTransactionStatus: (event) {
          final status = switch (event.status) {
            SubtrateTransactionSubmitionStatus.notFound =>
              WalletTransactionStatus.unknown,
            SubtrateTransactionSubmitionStatus.success => WalletTransactionStatus.block,
            SubtrateTransactionSubmitionStatus.failed => WalletTransactionStatus.failed
          };
          for (final i in txes) {
            i.transaction.updateStatus(status);
          }
        },
        onTransactionSubmited: (txId, blockNumber) {
          result.complete(SubstrateTxIdWithBlock(txId: txId, block: blockNumber));
        });
    final txId = await result.future;
    _tracker = SubmitedXCMTransferDestinationTracker(txData.destination);
    _trakcerSubscription = stream.listen(
      (event) {},
      onError: (e) {},
      onDone: () {
        _tracker?.dispose();
      },
    );
    txes = await _buildWalletTransaction(
        signedTx: signedTransaction, txId: txId.txId, block: txId.block);
    return SubmitSubstrateTransactionSuccess(
        txId: txId.txId,
        block: txId.block,
        xcmTransferDestinationTracker: _tracker,
        signedTransaction: signedTransaction,
        txes: txes);
  }

  @override
  Future<TransactionStateController> initForm({
    required BuildContext context,
    required SubstrateNetworkClient client,
    bool updateAccount = true,
    bool updateTokens = false,
  }) async {
    await super.initForm(
        context: context,
        client: client,
        updateAccount: updateAccount,
        updateTokens: updateTokens);
    if (!client.metadata.supportNativeTransfer) {
      throw AppException("substrate_disable_transfer_option_desc");
    }
    final existentialDeposit = metadata.existentialDeposit;
    if (existentialDeposit != null) {
      _existentialDeposit = IntegerBalance.token(existentialDeposit, network.token);
    }
    final internalNetwork = metadata.internalNetwork;
    final internalController = metadata.controller;
    if (internalNetwork == null || internalController == null) {
      throw AppExceptionConst.unsupportedNetworkFeature;
    }
    List<BaseSubstrateNetwork> relatedChains = internalNetwork.relaySystem.networks;
    final routes = relatedChains.map((e) => StringUtils.normalizeHex(e.genesis)).toList();
    final assetHub = internalNetwork.assetHub;
    final relay = internalNetwork.relayChain;
    final chains = walletProvider.wallet.getChains<SubstrateChain>();
    final SubstrateChain assetHubChain = chains.firstWhere(
        (e) => StringUtils.hexEqual(e.network.genesisBlock, assetHub.genesis),
        orElse: () => throw AppExceptionConst.unsupportedNetworkFeature);
    final SubstrateChain relayChain = chains.firstWhere(
        (e) => StringUtils.hexEqual(e.network.genesisBlock, relay.genesis),
        orElse: () => throw AppExceptionConst.unsupportedNetworkFeature);
    List<SubstrateXCMTransferNetwork> supportedChains = [];
    for (final i in chains) {
      final index =
          routes.indexWhere((e) => StringUtils.hexEqual(e, i.network.genesisBlock));
      if (index.isNegative) continue;
      supportedChains.add(SubstrateXCMTransferNetwork(
          network: i, internalNetwork: relatedChains.elementAt(index)));
    }
    if (supportedChains.isEmpty) {
      throw AppException("no_xcm_available_route_desc");
    }
    _requirement = SubstrateXCMTransferRequirement(
        destinations: supportedChains
            .where((e) => e.network != account)
            .map((e) => e.network)
            .toList(),
        relay: SubstrateXCMTransferNetwork(network: relayChain, internalNetwork: relay),
        systemAssetHub: SubstrateXCMTransferNetwork(
            network: assetHubChain, internalNetwork: assetHub),
        routes: supportedChains);
    SubstrateChainConfig config = await getChainConfig(
      walletProvider: walletProvider,
      type: account.network.type,
      onCreate: () => SubstrateChainConfig(),
    );

    if (!config.acceptXcmTransferTerm) {
      final success = await context.openDialogPage<bool>("create_xcm_transaction".tr,
          widget: (context) => DialogTitleAndMultiTextView(
                title: "before_you_continue".tr,
                buttonWidget: DialogSingleButtonView(
                  buttonLabel: "got_it_dont_show_again".tr,
                ),
                content: [
                  "xcm_condition_dryrun_required_desc".tr,
                  "xcm_condition_no_dryrun_desc".tr,
                  "xcm_condition_token_inactive_desc".tr,
                  "xcm_condition_partial_validation_desc".tr,
                  "xcm_condition_network_uncertainty_desc".tr,
                ],
              ));
      if (success == true) {
        await updateChainConfig(
            walletProvider: walletProvider,
            config: config.copyWith(acceptXcmTransferTerm: true),
            type: account.network.type);
      }
    }
    return this;
  }

  @override
  TransactionOperations get operation => SubstrateTransactionOperations.xcmTransfer;

  @override
  List<LiveFormField<Object?, Object>> get fields => [destination];

  @override
  void dispose() {
    destination.value?.dispose();
    _trakcerSubscription?.cancel();
    _trakcerSubscription == null;
    _tracker?.dispose();
    super.dispose();
  }
}
