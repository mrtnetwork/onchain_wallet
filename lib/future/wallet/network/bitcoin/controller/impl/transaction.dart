import 'dart:async';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/network/bitcoin/controller/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/crypto/requets/messages/models/models/signing.dart';
import 'package:on_chain_wallet/crypto/utils/bitcoin_cash/bitcoin_cash_utils.dart';
import 'memo_impl.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/crypto/keys/access/crypto_keys/crypto_keys.dart';

enum TransactionOrdering {
  bip69("bip_69_desc"),
  shuffle("shuffle_desc"),
  none("none_ordering_transaction_desc"),
  manually("manually_ordering_transaction_desc");

  const TransactionOrdering(this.desc);
  final String desc;

  BitcoinOrdering get ordering {
    switch (this) {
      case TransactionOrdering.none:
      case TransactionOrdering.manually:
        return BitcoinOrdering.none;
      case TransactionOrdering.shuffle:
        return BitcoinOrdering.shuffle;
      default:
        return BitcoinOrdering.bip69;
    }
  }
}

enum BitcoinTransactionPages { account, utxo, send }

abstract class BitcoinTransactionImpl<NETWORK extends WalletBitcoinNetwork>
    extends WalletSendTransactionStateImpl<IBitcoinAddress, BitcoinClient,
        WalletBitcoinNetwork, BitcoinChain> with BitcoinTransactionMemoImpl {
  BitcoinTransactionImpl({
    required super.walletProvider,
    required super.account,
    required super.apiProvider,
  });
  List<IBitcoinAddress> get addresses => account.addresses;
  final Cancelable _cancelable = Cancelable();
  bool get hasFeeRate;
  bool get hasSegwit => _hasSegwit;
  bool _hasSegwit = false;
  late IBitcoinAddress _onChangeAddress = address;
  String get onChangeAddressView => _onChangeAddress.address.toAddress;
  BitcoinBaseAddress get onChangeAddress => _onChangeAddress.networkAddress;
  bool get isForked => network.coinParam.isForked;
  bool get isBCH => network.coinParam.isBCH;
  BigInt get minimumOutput => isBCH ? BCHUtils.minimumOutput : BigInt.zero;
  String? _txHash;
  late bool supportRbf = network.coinParam.rbfSupport;
  @override
  late int? opReturnLength = network.coinParam.maxMemoLength;
  @override
  late bool allowMultipleOpReturn = network.coinParam.supportMultipleOpReturn;

  void estimateFee(
      {required List<BitcoinBaseOutput> outPuts,
      required List<UtxoWithAddress> inputs,
      BCMR? bcmr});

  final List<BitcoinUtxoWithBalance> selectedUtxo = [];
  int _utxosCount = 0;
  int get transactionSize;
  void countUtxos() {
    _utxosCount = 0;
    for (final i in accountsUtxos) {
      _utxosCount += i.utxosWithBalance?.length ?? 0;
    }
  }

  TransactionOrdering _ordering = TransactionOrdering.bip69;
  TransactionOrdering get ordering => _ordering;

  List<UtxoWithAddress> inputs = [];
  void buildInputs() {
    inputs = List.unmodifiable(selectedUtxo.map((e) => e.utxo).toList());
  }

  List<BitcoinBaseOutput> outputs = [];

  void buildOutputs([List<BitcoinBaseOutput> extraOutputs = const []]) {
    outputs = List<BitcoinBaseOutput>.unmodifiable([
      ...extraOutputs,
      ...receivers.map<BitcoinBaseOutput>((e) => BitcoinOutput(
          address: e.address.networkAddress, value: e.balance.balance)),
      if (remindAmount.balance > BigInt.zero)
        BitcoinOutput(address: onChangeAddress, value: remindAmount.balance),
      ...memoScripts.map((e) => e.script)
    ]);
    if (_ordering == TransactionOrdering.manually) {
      _ordering = TransactionOrdering.bip69;
      notify();
    }
  }

  void changeAccount(IBitcoinAddress? change) {
    if (change == null || !addresses.contains(change)) return;
    _onChangeAddress = change;
    buildOutputs();
    calculateFee();
  }

  bool get haveUtxos => _utxosCount > 0;
  bool get canBuildTransaction => selectedUtxo.isNotEmpty;
  bool get allUtxosSelected => selectedUtxo.length == _utxosCount;
  bool utxoSelected(BitcoinUtxoWithBalance utxo) => selectedUtxo.contains(utxo);

  late final IntegerBalance remindAmount = IntegerBalance.zero(network.token);
  late final IntegerBalance setupAmount = IntegerBalance.zero(network.token);
  late final IntegerBalance spendableAmount =
      IntegerBalance.zero(network.token);
  final Map<String, BitcoinOutputWithBalance> _receivers = {};
  List<BitcoinOutputWithBalance> get receivers => _receivers.values.toList();
  bool get hasOutput => _receivers.isNotEmpty;

  void _updateUtxosAmount() {
    BigInt sum = BigInt.zero;
    for (final i in selectedUtxo) {
      sum += i.balance.balance;
    }
    spendableAmount.updateBalance(sum);
  }

  void selectAllUtxos() {
    if (allUtxosSelected) {
      selectedUtxo.clear();
    } else {
      for (final a in accountsUtxos) {
        for (final u in a.utxosWithBalance ?? <BitcoinUtxoWithBalance>[]) {
          if (selectedUtxo.contains(u)) continue;
          selectedUtxo.add(u);
        }
      }
    }
    _updateUtxosAmount();
    notify();
  }

  void addUtxo(BitcoinUtxoWithBalance utxo) {
    final bool remove = selectedUtxo.remove(utxo);
    if (!remove) {
      selectedUtxo.add(utxo);
    }
    _updateUtxosAmount();
    notify();
  }

  void onSetupUtxo();

  // BitcoinClient get client => chainAccount.client;

  void onCalculateAmount();

  IntegerBalance get transactionFee;
  final GlobalKey<PageProgressState> progressKey =
      GlobalKey(debugLabel: "BitcoinTransactionPages");

  late final IntegerBalance sumOfSelectedUtxo =
      IntegerBalance.zero(network.token);
  bool _rbf = false;
  bool get rbf => _rbf;
  void toggleRbf(bool onChanged) {
    if (!supportRbf) return;
    _rbf = !_rbf;
    notify();
  }

  ///up

  BitcoinTransactionPages _page = BitcoinTransactionPages.account;
  bool get canPopPage =>
      _txHash != null ||
      _page == BitcoinTransactionPages.account ||
      progressKey.hasError;
  BitcoinTransactionPages get page => _page;
  bool get inAccountPage => _page == BitcoinTransactionPages.account;
  bool get inUtxoPage => _page == BitcoinTransactionPages.utxo;
  bool get inSendPage => _page == BitcoinTransactionPages.send;

  void onBackButton() {
    if (progressKey.status == StreamWidgetStatus.success) {
      return;
    }
    _cancelable.cancel();
    progressKey.backToIdle();
    try {
      switch (_page) {
        case BitcoinTransactionPages.account:
          break;
        case BitcoinTransactionPages.utxo:
          _page = BitcoinTransactionPages.account;
          break;
        default:
          _page = BitcoinTransactionPages.utxo;
          break;
      }
    } finally {
      notify();
    }
  }

  final GlobalKey<StreamWidgetState> updateBalancessKey =
      GlobalKey<StreamWidgetState>(debugLabel: "updateBalancessKey");

  final Map<String, UtxoAddressDetails> _addresses = {};
  final Map<String, BitcoinAccountUtxos> _accountsUtxos = {};

  List<BitcoinAccountUtxos> get accountsUtxos => _accountsUtxos.values.toList();
  final Map<String, BitcoinAccountUtxos> _retrievedUtxos = {};
  bool addressSelected(String addressProgram) =>
      _addresses.containsKey(addressProgram);
  bool get hasSpender => _addresses.isNotEmpty;
  void addAccount(IBitcoinAddress account) {
    final address = account.networkAddress.addressProgram;

    if (_addresses.containsKey(address)) {
      _addresses.remove(address);
    } else {
      if (account.multiSigAccount) {
        final multiSignatureAddress =
            (account as BitcoinMultiSigBase).multiSignatureAddress;

        _addresses.addAll({
          address: UtxoAddressDetails.multiSigAddress(
              address: account.networkAddress,
              multiSigAddress: multiSignatureAddress)
        });
      } else {
        final addrInfo = UtxoAddressDetails(
            address: account.networkAddress,
            publicKey: BytesUtils.toHexString(account.publicKey));
        _addresses.addAll({address: addrInfo});
      }
    }
    notify();
  }

  void fetchUtxos([bool includeTokenUtxos = false]) async {
    _page = BitcoinTransactionPages.utxo;
    notify();
    progressKey.progressText("retrieving_transaction".tr);
    _accountsUtxos.clear();
    selectedUtxo.clear();

    bool hasError = false;
    for (final i in _addresses.keys) {
      if (_retrievedUtxos[i]?.hasUtxo ?? false) {
        _accountsUtxos[i] = _retrievedUtxos[i]!;
        continue;
      }
      final result = await MethodUtils.call(() async {
        return await apiProvider.readUtxos(_addresses[i]!, includeTokenUtxos);
      }, cancelable: _cancelable);
      if (result.hasError) {
        if (result.isCancel) return;
        hasError = true;
      }
      _retrievedUtxos[i] = BitcoinAccountUtxos(
          address: i,
          utxos: result.hasError ? null : result.result,
          addressDetails: _addresses[i]!,
          network: network);
      _accountsUtxos[i] = _retrievedUtxos[i]!;
    }
    countUtxos();

    if (hasError) {
      progressKey.errorText("problem_when_receiving_utxos".tr);
    } else {
      progressKey.successText("transaction_successfully_received".tr);
    }
    notify();
  }

  void updateBalances() async {
    if (updateBalancessKey.inProgress) return;
    updateBalancessKey.process();
    await account.updateAccountBalance();
    updateBalancessKey.success();
    notify();
  }

  bool _onAddRecever(ReceiptAddress<BitcoinBaseAddress> addr) {
    if (_receivers.containsKey(addr.networkAddress.addressProgram)) {
      return false;
    } else {
      _receivers[addr.networkAddress.addressProgram] =
          BitcoinOutputWithBalance(address: addr, network: network);
      return true;
    }
  }

  void onAddRecever(List<ReceiptAddress<BitcoinBaseAddress>>? address,
      DynamicVoid onAccountExists) {
    if (address == null) return;
    bool allAdded = true;
    for (final i in address) {
      allAdded &= _onAddRecever(i);
    }
    if (!allAdded) {
      onAccountExists();
    }
    buildOutputs();
    calculateFee();
  }

  void removeReceiver(ReceiptAddress<BitcoinBaseAddress>? addr) {
    if (addr == null) return;
    final re = _receivers.remove(addr.networkAddress.addressProgram);
    onCalculateAmount();
    if (re != null) {
      calculateFee();
    }
  }

  void setupAccountAmount(
      BitcoinOutputWithBalance address, BigInt? amount) async {
    if (amount == null) return;
    address.balance.updateBalance(amount);
    final bool isMax = amount == remindAmount.balance;
    onCalculateAmount();
    if (isMax) {
      calculateFee();
      final fixedAmount = amount + remindAmount.balance;
      address.balance.updateBalance(fixedAmount);
      onCalculateAmount();
    }
    notify();
  }

  void onChangeOrdering(
      TransactionOrdering? ordering, OnCustomOrdering custom) async {
    try {
      if (ordering == null) return;
      if (ordering == TransactionOrdering.manually) {
        final ordered = await custom(inputs, outputs);
        if (ordered == null) return;
        inputs = ordered.$1;
        outputs = ordered.$2;
      }
      _ordering = ordering;
    } finally {
      notify();
    }
  }

  void calculateFee() {
    // if (!hasFeeRate || page != BitcoinTransactionPages.send) {
    //   progressKey.progressText("processing_fee_please_wait".tr);
    // }
    _hasSegwit = inputs.any((e) => e.utxo.isSegwit);
    _page = BitcoinTransactionPages.send;
    notify();
    estimateFee(outPuts: outputs, inputs: inputs);
    // final result = await MethodUtils.call(() async {
    //   return estimateFee(outPuts: outputs, inputs: inputs);
    // }, cancelable: _cancelable);
    // if (progressKey.inProgress && !result.isCancel) {
    //   if (result.hasError) {
    //     progressKey.errorText(result.error!.tr);
    //   } else {
    //     progressKey.backToIdle();
    //   }
    // }
    onCalculateAmount();
    notify();
  }

  @override
  Future<void> onTapMemo(FutureNullString onAdd) async {
    final currentMemo = memoScripts.length;
    await super.onTapMemo(onAdd);
    if (currentMemo != memoScripts.length) {
      buildOutputs();
      calculateFee();
    }
  }

  @override
  void onRemoveMemo(BitcoinMemo? memo) {
    if (!memoScripts.contains(memo)) return;
    super.onRemoveMemo(memo);
    buildOutputs();
    calculateFee();
  }

  BasedBitcoinTransacationBuilder _buildTransaction(
      {required List<BitcoinBaseOutput> outputs,
      required List<UtxoWithAddress> inputs}) {
    if (isForked) {
      return ForkedTransactionBuilder(
          outPuts: outputs,
          fee: transactionFee.balance,
          inputOrdering: ordering.ordering,
          outputOrdering: ordering.ordering,
          network: network.coinParam.transacationNetwork,
          utxos: inputs,
          enableRBF: rbf);
    }
    return BitcoinTransactionBuilder(
        outPuts: outputs,
        fee: transactionFee.balance,
        network: network.coinParam.transacationNetwork,
        inputOrdering: ordering.ordering,
        outputOrdering: ordering.ordering,
        utxos: inputs,
        enableRBF: rbf);
  }

  void sendTransaction() async {
    progressKey.progressText(
        "create_send_transaction".tr.replaceOne(network.coinParam.token.name));
    final result = await MethodUtils.call(() async {
      final inputs = this.inputs.imutable;
      final outputs = this.outputs.imutable;
      final List<IBitcoinAddress> signers = [];
      for (final i in selectedUtxo) {
        final IBitcoinAddress utxosAcount = addresses.firstWhere((element) =>
            element.networkAddress.addressProgram ==
            i.utxo.ownerDetails.address.addressProgram);
        signers.add(utxosAcount);
      }

      final tr = _buildTransaction(inputs: inputs, outputs: outputs);

      final request = WalletSigningRequest(
        addresses: signers,
        network: network,
        sign: (generateSignature) async {
          return tr.buildTransactionAsync(
              (trDigest, utxo, publicKey, sighash) async {
            final account = signers
                .whereType<IBitcoinAddress>()
                .firstWhere((element) => element.signers.contains(publicKey));
            AddressDerivationIndex keyIndex = account.keyIndex;
            if (account.multiSigAccount) {
              final multiSignatureAddress =
                  (account as BitcoinMultiSigBase).multiSignatureAddress;
              final correctSigner = multiSignatureAddress.signers
                  .firstWhere((element) => element.publicKey == publicKey);
              keyIndex = correctSigner.keyIndex;
            }
            final bitcoinSigning = BitcoinSigning(
                digest: trDigest,
                index: keyIndex.cast(),
                useTaproot: utxo.utxo.isP2tr,
                sighash: sighash,
                useBchSchnorr: !account.multiSigAccount,
                network: isBCH
                    ? SigningRequestNetwork.bitcoinCash
                    : SigningRequestNetwork.bitcoin);
            final sig = await generateSignature(bitcoinSigning);
            return BytesUtils.toHexString(sig.signature);
          });
        },
      );

      final signedTr =
          await walletProvider.wallet.signTransaction(request: request);
      if (signedTr.hasError) {
        throw signedTr.exception!;
      }
      assert(signedTr.result.getVSize() <= transactionSize,
          "should be equal or greather few bytes.");

      final ser = signedTr.result.serialize();
      final txId = await apiProvider.sendTransaction(ser);
      _saveTransaction(
          signers: signers, outputs: outputs, inputs: inputs, txId: txId);
      return txId;
    });
    progressKey.backToIdle();
    if (result.hasError) {
      progressKey.errorText(result.error!.tr,
          showBackButton: true, backToIdle: false);
    } else {
      _txHash = result.result;
      progressKey.success(
          progressWidget: SuccessTransactionTextView(
            network: network,
            txIds: [result.result],
          ),
          backToIdle: false);
    }
    notify();
  }

  Future<void> _saveTransaction(
      {required List<IBitcoinAddress> signers,
      required List<BitcoinBaseOutput> outputs,
      required List<UtxoWithAddress> inputs,
      required String txId}) async {
    final s = await MethodUtils.call(() async {
      signers = signers.toSet().toList();
      for (final i in signers) {
        final totalInputs = inputs
            .where((e) => e.ownerDetails.address == i.networkAddress)
            .toList()
            .sumOfUtxosValue();
        if (totalInputs == BigInt.zero) continue;
        final tx = BitcoinWalletTransaction(
            txId: txId,
            time: DateTime.now(),
            totalOutput: WalletTransactionIntegerAmount(
                amount: totalInputs, network: network),
            scriptHash: address.networkAddress.pubKeyHash(),
            outputs: [],
            network: network);
        await account.saveTransaction(address: i, transaction: tx);
      }
    });
    assert(!s.hasError, "saving bitcoin transaction failed $s");
  }
}
