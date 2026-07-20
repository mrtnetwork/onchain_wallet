import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:polkadot_dart/polkadot_dart.dart';

import 'types.dart';

class SubstrateXCMTokenDetails {
  final SubstrateShareAsset? shareAsset;
  final SubstrateTokenDetails tokenDetails;
  final int? reserveChain;
  bool get isNativeAsset => tokenDetails.isNativeAsset;
  final bool canPayFee;
  SubstrateXCMTokenDetails(
      {required this.tokenDetails, required this.canPayFee, required this.shareAsset})
      : reserveChain = tokenDetails.internalAsset.reserveChain();
  Token get token => tokenDetails.balance.value.token;
}

class SubstrateXCMTransferToken {
  final SubstrateXCMTokenDetails token;
  SubstrateXCMTransferToken({required this.token, BigInt? amount})
      : amount = IntegerBalance.token(amount ?? BigInt.zero, token.token,
            allowNegative: false, immutable: amount != null),
        minAmount = IntegerBalance.token(amount ?? BigInt.zero, token.token,
            allowNegative: false, immutable: amount != null);
  final IntegerBalance amount;
  final IntegerBalance minAmount;
  String? _minError;
  String? get minError => _minError;
  bool get hasAmount => amount.largerThanZero;
  bool _minReached = true;
  bool get minReached => _minReached;
  void _setError() {
    if (!_minReached) {
      _minError = "account_requires_min_n_balance"
          .tr
          .replaceOne("${minAmount.viewPrice} ${minAmount.token.symbol}");
    } else {
      _minError = null;
    }
  }

  void onUpdateAmount(BigInt amount) {
    this.amount.updateBalance(amount);
    _minReached = amount >= minAmount.balance;
    _setError();
  }

  void onUpdateMinAmount(BigInt amount) {
    minAmount.updateBalance(amount);
    _minReached = this.amount.balance >= minAmount.balance;
    _setError();
  }
}

class SubstrateXCMTransferFeeToken {
  final SubstrateXCMTokenDetails token;
  SubstrateXCMTransferFeeToken({required this.token, BigInt? amount})
      : amount = IntegerBalance.token(amount ?? BigInt.zero, token.token,
            allowNegative: false);
  final IntegerBalance amount;
  bool get hasAmount => amount.largerThanZero;
}

class SubstrateXCMTransferRequirement {
  final SubstrateXCMTransferNetwork relay;
  final SubstrateXCMTransferNetwork systemAssetHub;
  final List<SubstrateXCMTransferNetwork> routes;
  final List<SubstrateChain> destinations;

  SubstrateXCMTransferRequirement(
      {required this.relay,
      required this.systemAssetHub,
      required this.destinations,
      required List<SubstrateXCMTransferNetwork> routes})
      : routes = routes.immutable;
}

class SubstrateXCMTransferNetwork {
  final SubstrateChain network;
  final BaseSubstrateNetwork internalNetwork;
  SubstrateNetworkClient? _client;
  SubstrateNetworkAssets? _assets;
  final Map<BaseSubstrateAddress, SubstrateNetworkAccountBalances> _accountsAssets = {};
  SubstrateXCMTransferNetwork({required this.network, required this.internalNetwork});
  Future<SubstrateNetworkClient> client() async {
    return _client ??= (await network.client()).unwrap();
  }

  Future<SubstrateNetworkClient?> clientOrNull() async {
    return _client ??= (await network.client()).ok();
  }

  Future<SubstrateNetworkAssets> getAssets() async {
    return _assets ??= await (await controller()).getAssets();
  }

  Future<SubstrateNetworkAccountBalances> getAccountAssets(
      BaseSubstrateAddress address) async {
    return _accountsAssets[address] ??=
        await (await controller()).getAccountAssets(address: address);
  }

  Future<BaseSubstrateNetworkController> controller() async {
    final client = await this.client();
    return client.metadata.controller!;
  }
}

enum SubstrateXCMDestinationFeeStatus {
  unsuported,
  failed,
  success,
  pending,
  idle;

  bool get isIdle => this == idle;
  bool get isPending => this == pending;
}

enum SubstrateXCMDryRunStatus {
  success,
  failed,
  feeFailed,
  unsuported;

  bool get isSuccess => this == success;
}

class SubstrateXCMCallDryRun {
  final SubstrateXCMDryRunStatus status;
  final Map<String, dynamic>? dryRunContent;
  final List<SubstrateXCMTransferFeeToken> fees;
  final BaseSubstrateNetwork? network;
  bool get haveAmoutns => fees.isNotEmpty;
  SubstrateXCMCallDryRun(
      {required this.status,
      required this.dryRunContent,
      this.fees = const [],
      required this.network});
  Map<String, dynamic> toJson() {
    return {
      "status": status.name,
      "dry_run": dryRunContent,
      "fees": fees
          .map((e) => {
                "amount": e.amount.balance,
                "asset": e.token.tokenDetails.internalAsset.toJson()
              })
          .toList()
    };
  }
}

class SubstrateXCMTransactionDryRun {
  final SubstrateXCMCallDryRun call;
  final List<SubstrateXCMCallDryRun> routes;
  final List<SubstrateXCMTransferToken> localFees;
  final List<SubstrateXCMTransferToken> destinationFees;
  const SubstrateXCMTransactionDryRun(
      {required this.call,
      required this.routes,
      required this.localFees,
      required this.destinationFees});

  Map<String, dynamic> toJson() {
    return {"call": call.toJson(), "routes": routes.map((e) => e.toJson()).toList()};
  }
}

class SubstrateXCMTransferDestinationAccountInfo
    with DisposableMixin, StreamStateController {
  final Cancelable _cancelable = Cancelable();
  final _lock = SafeAtomicLock();
  final ReceiptAddress<BaseSubstrateAddress> receipt;
  SubstrateXCMTransferDestinationAccountInfo(this.receipt);
  SubstrateNetworkAccountBalances? _accountBalance;

  Future<void> getAccountBalances(SubstrateXCMTransferNetwork network) async {
    if (_accountBalance != null) return;
    final result = await IResult.call(() async {
      return await _lock.run(
        () async {
          final accountBalance = _accountBalance;
          if (accountBalance != null) return accountBalance;
          final controller = await network.controller();
          return await controller.getAccountAssets(address: receipt.networkAddress);
        },
      );
    }, cancelable: _cancelable);
    if (result.err()?.canceled() ?? false) return;
    assert(result.isOk);
    _accountBalance ??= result.ok();
    if (_accountBalance != null) notify();
  }

  BigInt getMinBalance(SubstrateShareAsset asset) {
    final accountBalances = _accountBalance;
    if (accountBalances == null) return BigInt.zero;
    final minBalance = asset.destination.minBalance ?? BigInt.zero;
    if (minBalance <= BigInt.zero) return BigInt.zero;
    SubstrateAccountAssetBalance? balance;
    if (asset.destination.type.isNative) {
      balance = accountBalances.balances.firstWhereNullable((e) => e.asset.type.isNative);
    } else {
      balance = accountBalances.balances
          .firstWhereNullable((e) => e.asset == asset.destination);
    }
    final freeBalance = balance?.free ?? BigInt.zero;
    final rBalance = minBalance - freeBalance;
    if (rBalance.isNegative) return BigInt.zero;
    return rBalance;
  }

  @override
  void dispose() {
    _cancelable.cancel();
    super.dispose();
  }
}

class SubstrateXCMTransferSimulate with DisposableMixin, StreamStateController {
  String? _error;
  String? get error => _error;
  SubstrateXCMTransactionDryRun? _xcmDryRun;
  SubstrateXCMTransactionDryRun? get xcmDryRun => _xcmDryRun;
  SubstrateXCMDestinationFeeStatus _status = SubstrateXCMDestinationFeeStatus.idle;
  SubstrateXCMDestinationFeeStatus get status => _status;

  void setIdle() {
    _error = null;
    _xcmDryRun = null;
    _status = SubstrateXCMDestinationFeeStatus.idle;
    notify();
  }

  void setPending() {
    _error = null;
    _xcmDryRun = null;
    _status = SubstrateXCMDestinationFeeStatus.pending;
    notify();
  }

  void setUnsuported() {
    _error = null;
    _xcmDryRun = null;
    _status = SubstrateXCMDestinationFeeStatus.unsuported;
    notify();
  }

  void setSuccess(SubstrateXCMTransactionDryRun dryRun) {
    _xcmDryRun = dryRun;
    _status = SubstrateXCMDestinationFeeStatus.success;
    notify();
  }

  void setError(String error) {
    _error = error;
    _xcmDryRun = null;
    _status = SubstrateXCMDestinationFeeStatus.failed;
    notify();
  }

  @override
  void dispose() {
    super.dispose();
    final dryRun = _xcmDryRun;
    if (dryRun != null) {
      for (final i in dryRun.localFees) {
        i.token.tokenDetails.balance.dispose();
      }
      for (final i in dryRun.destinationFees) {
        i.token.tokenDetails.balance.dispose();
      }
      for (final i in dryRun.routes) {
        for (final t in i.fees) {
          t.token.tokenDetails.balance.dispose();
        }
      }
    }
  }
}

class SubstrateXCMTransferDetails with DisposableMixin, StreamStateController {
  final Cancelable _cancelable = Cancelable();
  SubstrateXCMTransferDestinationAccountInfo? _receipt;
  ReceiptAddress<BaseSubstrateAddress>? get receipt => _receipt?.receipt;
  final _lock = SafeAtomicLock();
  final IntegerBalance deliveriesFee;
  final List<SubstrateXCMTransferToken> _transfers = [];

  final SubstrateXCMTransferSimulate dryRun = SubstrateXCMTransferSimulate();
  bool _allowAddTransfer = true;
  bool _isReady = false;
  bool get isReady => _isReady;
  bool get allowAddTransfer => _allowAddTransfer;

  List<SubstrateXCMTokenDetails> _availableTokens = [];
  List<SubstrateXCMTokenDetails> get availableTokens => _availableTokens;
  List<SubstrateXCMTokenDetails> _feeTokens = [];
  List<SubstrateXCMTokenDetails> get feeTokens => _feeTokens;

  SubstrateXCMTransferToken? _destinationFee;
  SubstrateXCMTransferToken? get destinationFee => _destinationFee;
  List<SubstrateXCMTransferToken> get transfers => _transfers;
  bool get haveTransfer => _transfers.isNotEmpty;

  TransactionResourceRequirementFetchStatus _initStatus =
      TransactionResourceRequirementFetchStatus.idle;
  TransactionStateStatus _status = TransactionStateStatus.error();
  TransactionStateStatus get status => _status;
  TransactionResourceRequirementFetchStatus get initStatus => _initStatus;
  final SubstrateTransferToken nativeAsset;
  final SubstrateXCMTransferNetwork origin;
  final SubstrateXCMTransferNetwork destinationChain;
  final List<SubstrateXCMTransferNetwork> relayNetworks;
  final List<SubstrateTransferToken> transferAssets;
  late final List<SubstrateXCMTransferNetwork> _relatedNetworks = [
    origin,
    destinationChain,
    ...relayNetworks
  ];

  final ISubstrateAddress address;
  Future<SubstrateXCMTransferNetwork?> _getNetworkClient(
      BaseSubstrateNetwork network) async {
    final n = _relatedNetworks.firstWhereNullable((e) => e.internalNetwork == network);
    final client = await n?.clientOrNull();
    if (client == null) return null;
    return n;
  }

  SubstrateXCMTransferDetails(
      {required this.origin,
      required this.destinationChain,
      required this.address,
      required List<SubstrateXCMTransferNetwork> relayNetworks,
      required List<SubstrateTransferToken> transferAssets})
      : deliveriesFee =
            IntegerBalance.zero(origin.network.network.token, allowNegative: false),
        transferAssets = transferAssets.immutable,
        relayNetworks = relayNetworks.immutable,
        nativeAsset = transferAssets.firstWhere((e) => e.isNativeAsset);

  Future<SubstrateXCMCallDryRun> _findSimulateAssets(
      {required Map<String, dynamic>? dryRunContent,
      required List<QueryDeleveriesFeeWithAmount> deleveriesFees,
      required bool isOk,
      required SubstrateXCMTokenDetails feeToken,
      SubstrateDispatchResult<BigInt>? weightToFee,
      required BaseSubstrateNetwork? network,
      required SubstrateTransactionXCMDryRunStatus status}) async {
    if (dryRunContent == null ||
        status == SubstrateTransactionXCMDryRunStatus.unsuportedDryRun ||
        status == SubstrateTransactionXCMDryRunStatus.unsuportedNetwork) {
      return SubstrateXCMCallDryRun(
          status: SubstrateXCMDryRunStatus.unsuported,
          dryRunContent: null,
          network: network);
    }

    final bool success = isOk &&
        deleveriesFees.every((e) => e.isSuccess) &&
        (weightToFee?.success ?? true) &&
        status == SubstrateTransactionXCMDryRunStatus.complete;
    if (!success) {
      return SubstrateXCMCallDryRun(
          status:
              isOk ? SubstrateXCMDryRunStatus.feeFailed : SubstrateXCMDryRunStatus.failed,
          dryRunContent: dryRunContent,
          network: network);
    }
    List<SubstrateXCMTransferFeeToken> fees = [];
    final weightFee = weightToFee?.ok;
    if (weightFee != null) {
      fees.add(SubstrateXCMTransferFeeToken(token: feeToken, amount: weightFee));
    }

    for (final deleveriesFee in deleveriesFees) {
      final assets = deleveriesFee.amounts;
      if (assets.isNotEmpty) {
        final accountAssets = await origin.getAccountAssets(address.networkAddress);
        for (final i in assets) {
          final amount = i.amount;
          final asset = i.asset;
          if (asset == null) {
            return SubstrateXCMCallDryRun(
                status: SubstrateXCMDryRunStatus.feeFailed,
                dryRunContent: dryRunContent,
                network: network);
          }
          SubstrateTokenDetails? feeAsset = transferAssets
              .firstWhereOrNull((e) => e.tokenDetails.internalAsset == asset)
              ?.tokenDetails;
          final inAccount =
              accountAssets.balances.firstWhereOrNull((e) => e.asset == asset);
          if (asset.type.isNative) {
            if (network != origin.internalNetwork) {
              fees.add(SubstrateXCMTransferFeeToken(
                  token: SubstrateXCMTokenDetails(
                      shareAsset: null,
                      tokenDetails: feeAsset ??
                          SubstrateTokenDetails(
                              internalAsset: asset,
                              asset: null,
                              balance: StreamValue.immutable(
                                  IntegerBalance.token(
                                      amount,
                                      Token(
                                          name: asset.name,
                                          symbol: asset.symbol,
                                          decimal: asset.decimals ?? 0)),
                                  name: "SubstrateXCMTransferDetails")),
                      canPayFee: false),
                  amount: amount));
              continue;
            }
            fees.add(SubstrateXCMTransferFeeToken(
                token: SubstrateXCMTokenDetails(
                    shareAsset: null,
                    tokenDetails: transferAssets
                            .firstWhereOrNull((e) => e.tokenDetails.isNativeAsset)
                            ?.tokenDetails ??
                        SubstrateTokenDetails(
                            internalAsset: asset,
                            asset: null,
                            balance: address.addressData.balance),
                    canPayFee: false),
                amount: amount));
            continue;
          }

          feeAsset ??= () {
            final token = SubstrateToken.create(
                assetIdentifier: asset.identifierAs(),
                balance: inAccount?.free ?? BigInt.zero,
                token: Token(
                    name: asset.name,
                    symbol: asset.symbol,
                    decimal: asset.decimals ?? 0));
            return SubstrateTokenDetails(
                asset: token, internalAsset: asset, balance: token.streamBalance);
          }();
          fees.add(SubstrateXCMTransferFeeToken(
              token: SubstrateXCMTokenDetails(
                  shareAsset: null, tokenDetails: feeAsset, canPayFee: false),
              amount: amount));
        }
      }
    }
    return SubstrateXCMCallDryRun(
        network: network,
        status: SubstrateXCMDryRunStatus.success,
        dryRunContent: dryRunContent,
        fees: fees);
  }

  Future<void> _simulate() async {
    final destinationFee = _destinationFee;
    if (!_status.isReady || destinationFee == null) {
      _cancelable.cancel();
      dryRun.setIdle();
      return;
    }
    _cancelable.cancel();
    dryRun.setPending();
    deliveriesFee.updateBalance(BigInt.zero);
    notify();
    SubstrateTransferEncodedParams? transfer;
    final result = await IResult.call(() async {
      return await _lock.run(() async {
        transfer = (await createCall()).xcmParams;
        final dryRun = await SubstrateNetworkControllerXCMTransferBuilder.dryRunXcm(
          origin: origin.internalNetwork,
          destination: destinationChain.internalNetwork,
          destinationFee: destinationFee.token.tokenDetails.internalAsset,
          transfer: transfer!,
          owner: address.networkAddress,
          onRequestController: (network) async {
            return (await _getNetworkClient(network))?.controller();
          },
        );

        if (dryRun == null) return null;
        final localDryRun = await _findSimulateAssets(
            dryRunContent: dryRun.dryRun.toJson(),
            deleveriesFees: dryRun.localDeliveryFees,
            isOk: dryRun.dryRun.success,
            feeToken: destinationFee.token,
            network: origin.internalNetwork,
            status: dryRun.status);
        List<SubstrateXCMCallDryRun> xcmDryRun = await Future.wait(dryRun.externalXcm.map(
          (e) {
            return _findSimulateAssets(
                dryRunContent: e.xcmDryRun?.toJson(),
                deleveriesFees: e.deleveriesFee,
                isOk: e.xcmDryRun?.ok?.isComplete ?? false,
                feeToken: destinationFee.token,
                weightToFee: e.weightToFee,
                network: e.network,
                status: e.status);
          },
        ));

        final List<SubstrateXCMTransferToken> localFees = [];
        final List<SubstrateXCMTransferToken> destinationFees = [];
        if (localDryRun.status.isSuccess) {
          final dryRunFees = localDryRun.fees;
          final Map<SubstrateTokenDetails, BigInt> fees = {};
          for (final i in dryRunFees) {
            fees.update(i.token.tokenDetails, (value) => value + i.amount.balance,
                ifAbsent: () => i.amount.balance);
          }
          localFees.addAll(fees.entries
              .map((e) => SubstrateXCMTransferToken(
                  token: SubstrateXCMTokenDetails(
                      tokenDetails: e.key, canPayFee: false, shareAsset: null),
                  amount: e.value))
              .toList());
        }
        if (xcmDryRun.every((e) => e.status.isSuccess)) {
          final dryRunFees = xcmDryRun.expand((e) => e.fees).toList();
          final Map<SubstrateTokenDetails, BigInt> fees = {};
          for (final i in dryRunFees) {
            fees.update(i.token.tokenDetails, (value) => value + i.amount.balance,
                ifAbsent: () => i.amount.balance);
          }
          destinationFees.addAll(fees.entries
              .map((e) => SubstrateXCMTransferToken(
                  token: SubstrateXCMTokenDetails(
                      tokenDetails: e.key, canPayFee: false, shareAsset: null),
                  amount: e.value))
              .toList());
        }
        return SubstrateXCMTransactionDryRun(
            call: localDryRun,
            routes: xcmDryRun,
            localFees: localFees,
            destinationFees: destinationFees);
      });
    }, cancelable: _cancelable);
    if (result.err()?.canceled() ?? false) return;
    if (result.isErr) {
      dryRun.setError(result.unwrapErr().localizationError);
    } else {
      final simulate = result.unwrap();
      if (simulate == null) {
        dryRun.setUnsuported();
      } else {
        final deliveriesFee = simulate.localFees.where((e) {
          return e.token.tokenDetails == nativeAsset.tokenDetails;
        }).fold<BigInt>(BigInt.zero, (p, c) => p + c.amount.balance);
        this.deliveriesFee.updateBalance(deliveriesFee);
        dryRun.setSuccess(simulate);
      }
    }

    onStateUpdated(fromSimulate: true);
  }

  String? onFilterToken(SubstrateTokenDetails token) {
    if (_transfers.any((e) => e.token.tokenDetails == token)) {
      return "token_already_exists".tr;
    }
    final reserveChains = {
      ..._transfers.map((e) => e.token.reserveChain),
      token.internalAsset.reserveChain()
    };
    if (reserveChains.length != 1) {
      return "transfer_multiple_reserve_chains_not_allowed".tr;
    }
    return null;
  }

  TransactionStateStatus getStateStatus() {
    final isReady = _destinationFee != null &&
        receipt != null &&
        _transfers.isNotEmpty &&
        _transfers.every((e) => e.hasAmount) &&
        !dryRun.status.isPending;
    if (!isReady) {
      return TransactionStateStatus.error();
    }
    if (_availableTokens.isEmpty) {
      return TransactionStateStatus.error(error: "no_transfable_asset_found".tr);
    }
    if (_transfers.map((e) => e.token.reserveChain).toSet().length != 1) {
      return TransactionStateStatus.error(
          error: "transfer_multiple_reserve_chains_not_allowed".tr);
    }
    final dryRunResult = dryRun.xcmDryRun;
    String? warning;
    if (dryRunResult == null ||
        !dryRunResult.call.status.isSuccess ||
        dryRunResult.routes.any((e) => !e.status.isSuccess)) {
      warning = "xcm_simulation_failed_desc".tr;
    }

    return TransactionStateStatus.ready(warning: warning);
  }

  void onStateUpdated({bool fromSimulate = false}) {
    _allowAddTransfer = transfers.length < 2;
    _feeTokens = transfers.where((e) => e.token.canPayFee).map((e) => e.token).toList();
    if (!_feeTokens.any((e) => e.tokenDetails == destinationFee?.token.tokenDetails)) {
      if (_feeTokens.isEmpty) {
        _destinationFee = null;
      } else {
        _destinationFee = SubstrateXCMTransferToken(token: _feeTokens.first);
      }
    }
    _status = getStateStatus();
    _isReady = _status.isReady && fromSimulate;
    if (!fromSimulate) _simulate();
    notify();
  }

  void onDestinationAccountAssetsFetched() {
    final receipt = _receipt;
    for (final i in _transfers) {
      final shareAsset = i.token.shareAsset;
      if (shareAsset == null) continue;
      final balance = receipt?.getMinBalance(shareAsset);
      i.onUpdateMinAmount(balance ?? BigInt.zero);
    }
    onStateUpdated();
  }

  void onUpdateReceipt(ReceiptAddress<BaseSubstrateAddress> address) {
    if (address.view == receipt?.view) return;
    final currentAddress = _receipt;
    _receipt = SubstrateXCMTransferDestinationAccountInfo(address);
    currentAddress?.dispose();
    _receipt?.stream.listen((_) => onDestinationAccountAssetsFetched());
    _receipt?.getAccountBalances(destinationChain);
    onDestinationAccountAssetsFetched();
  }

  void onUpdateToken(SubstrateTokenDetails token) {
    final xcmToken = _availableTokens.firstWhereNullable((e) => e.tokenDetails == token);
    if (xcmToken == null || transfers.any((e) => e.token == xcmToken)) return;
    final transfer = SubstrateXCMTransferToken(token: xcmToken);
    _transfers.add(transfer);
    final sharedAsset = transfer.token.shareAsset;
    if (sharedAsset != null) {
      final minBalance = _receipt?.getMinBalance(sharedAsset);
      transfer.onUpdateMinAmount(minBalance ?? BigInt.zero);
    }

    onStateUpdated();
  }

  void onUpdateDestinationFeeToken(SubstrateXCMTokenDetails token) {
    assert(_feeTokens.contains(token), "Token not found.");
    if (!_feeTokens.contains(token)) return;
    _destinationFee = SubstrateXCMTransferToken(token: token);
    onStateUpdated();
  }

  void onUpdateAmount(SubstrateXCMTransferToken transfer, BigInt amount, bool max) {
    transfer.onUpdateAmount(amount);
    onStateUpdated();
  }

  void onRemoveTransfer(SubstrateXCMTransferToken transfer) {
    assert(_transfers.contains(transfer));
    _transfers.remove(transfer);
    dryRun.setIdle();
    onStateUpdated();
  }

  Future<SubstrateXCMTransferEncodedParamsWithControllers> createCall() async {
    final client = (await origin.network.client()).unwrap();
    final result = await client.metadata.controller!.xcmTransfer(
        onControllerRequest: (network) async {
          final clinet = await (await _getNetworkClient(network))?.client();
          return clinet?.metadataWitPorvider();
        },
        params: SubstrateXCMTransferParams(
          assets: transfers
              .map((e) => SubstrateXCMTransferAsset(
                  amount: e.amount.balance, asset: e.token.tokenDetails.internalAsset))
              .toList(),
          destinationNetwork: destinationChain.internalNetwork,
          origin: origin.internalNetwork,
          feeIndex: transfers.indexWhere((e) =>
              e.token.tokenDetails.internalAsset ==
              destinationFee?.token.tokenDetails.internalAsset),
          destinationAddress: receipt!.networkAddress,
        ));
    return SubstrateXCMTransferEncodedParamsWithControllers(
        origin: await origin.controller(),
        destination: await destinationChain.controller(),
        xcmParams: result);
  }

  Future<void> init() async {
    await _lock.run(() async {
      _initStatus = TransactionResourceRequirementFetchStatus.pending;
      notify();
      final result = await IResult.call(() async {
        final controller = await origin.controller();
        SubstrateNetworkClient client = await origin.client();
        final assets = await client.getNetworkAssets();

        (await destinationChain.network.initAsMainNetwork()).unwrap();
        client = await destinationChain.client();
        final destinationController = await destinationChain.controller();
        final destAssets = await client.getNetworkAssets();
        final sharedAssets = assets.findShareAssets(destAssets);
        SubstrateNetworkAssets transfableAssets = SubstrateNetworkAssets(
            assets: await controller.filterTransferableAssets(
                assets: sharedAssets.map((e) => e.origin).toList(),
                destination: destinationChain.internalNetwork),
            network: origin.internalNetwork);
        transfableAssets = SubstrateNetworkAssets(
            assets: await destinationController.filterReceiveAssets(
                assets: transfableAssets.assets, origin: origin.internalNetwork),
            network: transfableAssets.network);
        final sharedFeeAssets = assets.findShareAssets(destAssets, canPayFee: true);
        List<SubstrateXCMTokenDetails> availableTokens = [];
        for (final i in transfableAssets.assets) {
          final shareAsset = sharedAssets.firstWhereNullable((e) => e.origin == i);
          final bool canPayFee = sharedFeeAssets.any((e) => e.origin == i);
          final asset =
              transferAssets.firstWhereNullable((e) => e.tokenDetails.internalAsset == i);
          if (asset == null) continue;
          availableTokens.add(SubstrateXCMTokenDetails(
              shareAsset: shareAsset,
              tokenDetails: asset.tokenDetails,
              canPayFee: canPayFee));
        }
        return availableTokens;
      }, cancelable: _cancelable);
      if (result.err()?.canceled() ?? false) return;
      if (result.isErr) {
        _status =
            TransactionStateStatus.error(error: result.unwrapErr().localizationError);
        _initStatus = TransactionResourceRequirementFetchStatus.failed;
        notify();
        return;
      }
      _availableTokens = result.unwrap();
      _initStatus = TransactionResourceRequirementFetchStatus.success;
      onStateUpdated();
      return;
    });
  }

  @override
  void dispose() {
    super.dispose();
    dryRun.dispose();
    _receipt?.dispose();
    _cancelable.cancel();
    for (final i in relayNetworks) {
      if (i == origin) continue;
    }
  }
}

class SubmitedXCMTransferDestinationTracker with DisposableMixin, StreamStateController {
  SubstrateXCMTransctionTrackerResult? _event;
  SubstrateXCMTransctionTrackerResult? get event => _event;
  Map<String, dynamic>? _content;
  Map<String, dynamic>? get content => _content;
  final SubstrateChain destination;

  SubstrateXCMTransctionTrackerStatus? get status => _event?.status;

  bool get inProgress => _event == null;
  bool get hasContent => _content != null;
  SubmitedXCMTransferDestinationTracker(this.destination);

  void onUpdateEvent(SubstrateXCMTransctionTrackerResult event) {
    _event = event;
    if (event.blockEvent != null) {
      _content = event.toJson();
    }
    notify();
  }
}
