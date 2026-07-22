import 'dart:async';

import 'package:blockchain_utils/utils/atomic/atomic.dart';
import 'package:on_chain_bridge/dev/dev.dart';
import 'package:on_chain_swap/on_chain_swap.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/chain/chain/chain.dart';
import 'package:on_chain_wallet/wallet/models/swap/swap/models.dart';

class BitcoinSwapAssetsWithBalance
    extends SwapAssetsWithBalance<IBitcoinAddress, BitcoinChain, BitcoinSwapAsset> {
  BitcoinSwapAssetsWithBalance(
      {required super.asset,
      required super.accounts,
      required super.sourceChain,
      required super.networkAsset});

  @override
  Future<IResult<BigInt>> getBalance(IBitcoinAddress account) async {
    final balance = await sourceChain.updateAddressBalance(account);
    return balance.map((e) => account.addressData.currencyBalance);
  }
}

class EthereumSwapAssetsWithBalance
    extends SwapAssetsWithBalance<IEthereumAddress, EthereumChain, ETHSwapAsset> {
  EthereumSwapAssetsWithBalance(
      {required super.asset,
      required super.accounts,
      required super.sourceChain,
      required super.networkAsset});

  @override
  Future<IResult<BigInt>> getBalance(IEthereumAddress account) async {
    final contract = networkAsset.contractAddress;
    if (contract != null) {
      return await sourceChain.getErc20TokenBalance(address: account, contract: contract);
    }
    final balance = await sourceChain.updateAddressBalance(account, tokens: false);
    return balance.map((e) => account.addressData.currencyBalance);
  }
}

class SolanaSwapAssetsWithBalance
    extends SwapAssetsWithBalance<ISolanaAddress, SolanaChain, SolanaSwapAsset> {
  SolanaSwapAssetsWithBalance(
      {required super.asset,
      required super.accounts,
      required super.sourceChain,
      required super.networkAsset});

  @override
  Future<IResult<BigInt>> getBalance(ISolanaAddress account) async {
    final mint = networkAsset.contractAddress;
    if (mint != null) {
      return await sourceChain.getSplTokenBalance(address: account, mint: mint);
    }
    final balance = await sourceChain.updateAddressBalance(account, tokens: false);
    return balance.map((e) => account.addressData.currencyBalance);
  }
}

class TronSwapAssetsWithBalance
    extends SwapAssetsWithBalance<ITronAddress, TronChain, TronSwapAsset> {
  TronSwapAssetsWithBalance(
      {required super.asset,
      required super.accounts,
      required super.sourceChain,
      required super.networkAsset});

  @override
  Future<IResult<BigInt>> getBalance(ITronAddress account) async {
    final contract = networkAsset.contractAddress;
    if (contract != null) {
      return await sourceChain.getTrc20TokenBalance(address: account, contract: contract);
    }
    final balance = await sourceChain.updateAddressBalance(account, tokens: false);
    return balance.map((e) => account.addressData.currencyBalance);
  }
}

class XRPSwapAssetsWithBalance
    extends SwapAssetsWithBalance<IXRPAddress, XRPChain, XRPSwapAsset> {
  XRPSwapAssetsWithBalance(
      {required super.asset,
      required super.accounts,
      required super.sourceChain,
      required super.networkAsset});

  @override
  Future<IResult<BigInt>> getBalance(IXRPAddress account) async {
    final balance = await sourceChain.updateAddressBalance(account, tokens: false);
    return balance.map((e) => account.addressData.currencyBalance);
  }
}

class CosmosSwapAssetsWithBalance
    extends SwapAssetsWithBalance<ICosmosAddress, CosmosChain, CosmosSwapAsset> {
  CosmosSwapAssetsWithBalance(
      {required super.asset,
      required super.accounts,
      required super.sourceChain,
      required super.networkAsset});

  @override
  Future<IResult<BigInt>> getBalance(ICosmosAddress account) async {
    final balance = await sourceChain.getTokenDenomBalance(
        address: account, denom: networkAsset.baseDenom);
    return balance.map((e) => account.addressData.currencyBalance);
  }
}

class ZcashSwapAssetsWithBalance
    extends SwapAssetsWithBalance<IZcashAddress, ZcashChain, ZcashSwapAsset> {
  ZcashSwapAssetsWithBalance(
      {required super.asset,
      required super.accounts,
      required super.sourceChain,
      required super.networkAsset});

  @override
  Future<IResult<BigInt>> getBalance(IZcashAddress account) async {
    final balance = await sourceChain.updateAddressBalance(account, tokens: false);
    return balance.map((e) => account.addressData.currencyBalance);
  }
}

class ADASwapAssetsWithBalance
    extends SwapAssetsWithBalance<ICardanoAddress, ADAChain, AdaSwapAsset> {
  ADASwapAssetsWithBalance(
      {required super.asset,
      required super.accounts,
      required super.sourceChain,
      required super.networkAsset});

  @override
  Future<IResult<BigInt>> getBalance(ICardanoAddress account) async {
    final balance = await sourceChain.updateAddressBalance(account, tokens: false);
    return balance.map((e) => account.addressData.currencyBalance);
  }
}

abstract class SwapAssetsWithBalance<ACCOUNT extends ChainAccount,
    CH extends APPCHAINACCOUNT<ACCOUNT>, SASSETS extends BaseSwapAsset> {
  final APPSwapAssets asset;
  final List<ACCOUNT> accounts;
  final CH sourceChain;
  final bool allowMultipleAccountSpent;
  final lock = SafeAtomicLock();
  final SASSETS networkAsset;

  bool _allowAddSource = false;
  bool get allowAddSource => _allowAddSource;
  StreamSubscription<ChainEvent>? _accountListener;
  SwapAssetsWithBalance(
      {required this.asset,
      required this.accounts,
      required this.sourceChain,
      required this.networkAsset})
      : allowMultipleAccountSpent = sourceChain.network.type.isBitcoin {
    _accountListener = sourceChain.stream.listen(onChangeEvent);
    _checkAddSource();
  }

  factory SwapAssetsWithBalance.from(
      {required APPSwapAssets asset,
      required List<ChainAccount> accounts,
      required Chain account}) {
    SwapAssetsWithBalance balance;
    switch (asset.network.type) {
      case NetworkType.bitcoinAndForked:
      case NetworkType.bitcoinCash:
        balance = BitcoinSwapAssetsWithBalance(
            asset: asset,
            accounts: accounts.cast(),
            sourceChain: account.cast(),
            networkAsset: asset.asset.cast());
        break;
      case NetworkType.xrpl:
        balance = XRPSwapAssetsWithBalance(
            asset: asset,
            accounts: accounts.cast(),
            sourceChain: account.cast(),
            networkAsset: asset.asset.cast());
        break;
      case NetworkType.ethereum:
        balance = EthereumSwapAssetsWithBalance(
            asset: asset,
            accounts: accounts.cast(),
            sourceChain: account.cast(),
            networkAsset: asset.asset.cast());
        break;
      case NetworkType.tron:
        balance = TronSwapAssetsWithBalance(
            asset: asset,
            accounts: accounts.cast(),
            sourceChain: account.cast(),
            networkAsset: asset.asset.cast());
        break;
      case NetworkType.solana:
        balance = SolanaSwapAssetsWithBalance(
            asset: asset,
            accounts: accounts.cast(),
            sourceChain: account.cast(),
            networkAsset: asset.asset.cast());
        break;
      case NetworkType.cardano:
        balance = ADASwapAssetsWithBalance(
            asset: asset,
            accounts: accounts.cast(),
            sourceChain: account.cast(),
            networkAsset: asset.asset.cast());
        break;
      case NetworkType.cosmos:
        balance = CosmosSwapAssetsWithBalance(
            asset: asset,
            accounts: accounts.cast(),
            sourceChain: account.cast(),
            networkAsset: asset.asset.cast());
        break;
      case NetworkType.zcash:
        balance = ZcashSwapAssetsWithBalance(
            asset: asset,
            accounts: accounts.cast(),
            sourceChain: account.cast(),
            networkAsset: asset.asset.cast());
        break;
      default:
        throw WalletExceptionConst.unsupportedSwapAsset;
    }
    if (balance is! SwapAssetsWithBalance<ACCOUNT, CH, SASSETS>) {
      throw AppInternalError.internalError("SwapAssetsWithBalance.from",
          reason: "Unknown asset.");
    }
    return balance;
  }
  StreamValue<BigInt?> balanceStream = StreamValue(null, name: "SwapAssetsWithBalance");

  Future<IResult<BigInt>> getBalance(ACCOUNT account);

  BigInt? get totalAccountsBalance => balanceStream.value;
  Map<ChainAccount, BigInt?> balances = {};
  BigInt? _getBalances() {
    if (accounts.isEmpty) return null;
    BigInt balances = BigInt.zero;
    for (final i in accounts) {
      final balance = this.balances[i];
      if (balance == null) return null;
      balances += balance;
    }
    return balances;
  }

  void checkBalance() {
    balanceStream.value = _getBalances();
  }

  void onChangeEvent(ChainEvent event) {
    if (event.type == DefaultChainNotify.address) {
      for (final i in [...accounts]) {
        if (!sourceChain.addresses.contains(i)) {
          accounts.remove(i);
          balances.remove(i);
          _checkAddSource();
        }
      }
    }
    checkBalance();
  }

  Future<void> updateBalance() async {
    await lock.run(() async {
      if (accounts.isEmpty) return;
      final client = (await sourceChain.client()).ok();
      if (client == null) return;
      await IResult.call(
        () => Future.wait(accounts.map((e) async {
          final balance = balances[e];
          if (balance != null) return;
          final newBalance = (await getBalance(e));
          newBalance.map((balance) {
            if (!accounts.contains(e)) return;
            balances[e] = balance;
          }).mapErr((e) {
            e.logError(
                mode: LoggerMode.info, function: "updateBalance", runtime: runtimeType);
            return e.exception;
          });
        })),
      );
      checkBalance();
    });
  }

  void _checkAddSource() {
    _allowAddSource = allowMultipleAccountSpent || accounts.isEmpty;
  }

  void removeAccount(ACCOUNT account) {
    accounts.remove(account);
    balances.remove(account);
    _checkAddSource();
    checkBalance();
  }

  void updateAccount(ACCOUNT account, {ACCOUNT? exitAccount}) {
    if (exitAccount != null) {
      accounts.clear();
      balances.clear();
      accounts.add(account);
    } else {
      assert(allowMultipleAccountSpent || accounts.isEmpty);
      accounts.add(account);
    }
    _checkAddSource();
    checkBalance();
    updateBalance();
  }

  void dispose() {
    _accountListener?.cancel();
    _accountListener = null;
    balanceStream.dispose();
  }
}
