import 'dart:async';

import 'package:blockchain_utils/utils/atomic/atomic.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_swap/on_chain_swap.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/swap/clients/tron.dart';
import 'package:on_chain_wallet/future/wallet/swap/clients/xrp.dart';
import 'package:on_chain_wallet/future/wallet/swap/clients/zcash.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/networks/networks.dart';
import 'package:polkadot_dart/polkadot_dart.dart';
import 'package:xrpl_dart/xrpl_dart.dart';
import 'package:zcash_dart/zcash.dart';

class SwapTransactionStateController extends StateController {
  SwapTransactionStateController({required this.route, required this.wallet});
  final WalletProvider wallet;
  final APPSwapRoute route;
  List<ChainAccount> get sources => route.sources;
  ReceiptAddress get destAddress => route.destAddress;
  final _lock = SafeAtomicLock();
  final StreamPageProgressController progressKey = StreamPageProgressController();
  TransactionOperationStep? _step;
  TransactionOperationStep? get step => _step;

  void reset() {
    progressKey.backToIdle();
    _step = null;
    notify();
  }

  bool get inProgress => _step != null;
  SwapNetwork get network => route.route.route.quote.sourceAsset.network;
  Future<bool> onPop(FuncFutureNullableBool callback) async {
    if (allowPop) return true;
    final pop = await callback();
    if (pop == true) {
      allowPop = true;
      notify();
      return MethodUtils.executeAfterDelay(() async => true);
    }
    return false;
  }

  String? _latestError;
  String? get latestError => _latestError;
  bool allowPop = false;
  void _onUpdateState(TransactionOperationStep step, {String? transactionHash}) {
    _step = step;

    if (step == TransactionOperationStep.txHash) {
      allowPop = true;
      progressKey.success(
          backToIdle: false,
          progressWidget: SuccessTransactionTextView(
            txId: transactionHash ?? '',
            account: route.sourceChain,
          ));
    }
    notify();
  }

  Future<void> _signTransaction(
      SafeStreamController<(TransactionOperationStep, String?)> onUpdateState) async {
    final transaction = route.transaction;
    final source = route.sourceChain;
    final client = (await source.client()).unwrapOr(
        (e) => throw AppException("swap_source_chain_provider_connection_error"));
    final accounts = route.sources;
    void statusChanged(TransactionOperationStep step, {String? transactionHash}) {
      assert(!onUpdateState.isClosed);
      onUpdateState.add((step, transactionHash));
    }

    switch (transaction.runtimeType) {
      case const (SwapRouteEthereumTransactionBuilder):
        return await (transaction as SwapRouteEthereumTransactionBuilder)
            .buildTransactions(
                stepsCallBack: statusChanged,
                client: (network) async {
                  return client as BaseSwapEthereumClient;
                },
                signer: (e) async {
                  final ethChain = route.sourceChain.cast<EthereumChain>();
                  return SwapWeb3SignerEthereum(
                      onSign: (e) async {
                        final params = WalletActionInAppWeb3Request<String>(
                            request: Web3EthreumSendTransaction(
                                account: Web3EthereumChainAccount.fromChainAccount(
                                    address: accounts.first.cast<IEthereumAddress>(),
                                    id: ethChain.network.value,
                                    isDefault: true),
                                to: e.to,
                                value: e.value,
                                gas: e.gasLimit?.toInt(),
                                data: BytesUtils.fromHexString(e.data),
                                chainId: e.chainId,
                                gasPrice: e.gasPrice,
                                maxPriorityFeePerGas: e.maxPriorityFeePerGas,
                                maxFeePerGas: e.maxFeePerGas));
                        return (await wallet.wallet.doAction(params)).unwrap();
                      },
                      onSigner: () async => accounts
                          .map((e) => e.networkAddress)
                          .cast<ETHAddress>()
                          .toList());
                });
      case const (SwapRouteTronTransactionBuilder):
        return await (transaction as SwapRouteTronTransactionBuilder).buildTransactions(
            stepsCallBack: statusChanged,
            client: (network) async {
              return TronSwapClient(
                  client: client.cast(),
                  addresses: accounts.cast<ITronAddress>(),
                  account: source.cast());
            },
            signer: (e) async {
              final ethChain = route.sourceChain.cast<TronChain>();
              return SwapWeb3SignerTron(
                  onSign: (e) async {
                    final params = WalletActionInAppWeb3Request<Transaction>(
                        request: Web3TronSignTransaction(
                            transaction: e.transaction.toBuffer(),
                            txId: e.transaction.rawData.txID,
                            accessAccount: Web3TronChainAccount.fromChainAccount(
                                address: accounts.first.cast<ITronAddress>(),
                                id: ethChain.network.value,
                                isDefault: true)));
                    return (await wallet.wallet.doAction(params)).unwrap();
                  },
                  onSigner: () async =>
                      accounts.map((e) => e.networkAddress).cast<TronAddress>().toList());
            });
      case const (SwapRouteXRPTransactionBuilder):
        return await (transaction as SwapRouteXRPTransactionBuilder).buildTransactions(
            stepsCallBack: statusChanged,
            client: (network) async {
              return XRPSwapClinet(
                  client: client.cast(),
                  addresses: accounts.cast<IXRPAddress>(),
                  account: source.cast());
            },
            signer: (e) async {
              final ethChain = route.sourceChain.cast<XRPChain>();
              return SwapWeb3SignerXRP(
                  onSign: (e) async {
                    final params =
                        WalletActionInAppWeb3Request<Web3XRPTransactionResponse>(
                            request: Web3XRPSendTransaction(
                                txBlob: e.toTransactionBlobBytes(),
                                method: Web3XRPRequestMethods.sendTransaction,
                                account: Web3XRPChainAccount.fromChainAccount(
                                    address: accounts.first.cast<IXRPAddress>(),
                                    id: ethChain.network.value,
                                    isDefault: true)));
                    final result = (await wallet.wallet.doAction(params)).unwrap();
                    final txId = result.txId;
                    if (txId == null) {
                      throw AppInternalError.internalError("_signTransaction",
                          reason: "Unexpected XRP Response.");
                    }
                    return txId;
                  },
                  onSigner: () async => accounts
                      .map((e) => e.networkAddress)
                      .cast<XRPBaseAddress>()
                      .toList());
            });
      case const (SwapRouteZcashTransactionBuilder):
        return await (transaction as SwapRouteZcashTransactionBuilder).buildTransactions(
            stepsCallBack: statusChanged,
            client: (network) async {
              return ZcashSwapClinet(client.cast());
            },
            signer: (e) async {
              return SwapWeb3SignerZcash(
                  onSign: (e) async {
                    final accounts = sources.cast<IZcashAddress>();
                    final params = WalletActionInAppWeb3Request<
                            Web3ZcashTransactionResponse>(
                        request: Web3ZcashSendTransaction(
                            destintions: e.destinations
                                .map((e) => Web3ZcashTransactionParams(
                                    address: e.destination,
                                    amount: e.amount,
                                    protocol: e.protocol,
                                    memo: null))
                                .toList(),
                            privacy: Web3ZcashTransferPrivacy.auto,
                            transparentMemos: e.transparentMemos,
                            accounts: accounts
                                .map((e) => Web3ZcashChainAccount.fromChainAccount(
                                    address: e, id: source.networkId, isDefault: false))
                                .toList()));
                    final result = (await wallet.wallet.doAction(params)).unwrap();
                    final txId = result.txId;
                    return txId;
                  },
                  onSigner: () async => accounts
                      .map((e) => e.networkAddress)
                      .cast<ZcashAddress>()
                      .toList());
            });

      case const (SwapRouteCosmosTransactionBuilder):
        return await (transaction as SwapRouteCosmosTransactionBuilder).buildTransactions(
            stepsCallBack: statusChanged,
            client: (network) async => client as BaseSwapCosmosClient,
            signer: (e) async {
              return SwapWeb3SignerCosmos(onSigner: () async {
                final cosmosAccounts = accounts.cast<ICosmosAddress>();
                return cosmosAccounts
                    .map((e) => CosmosSpenderAddress(
                        address: e.networkAddress, publicKey: e.toCosmosPublicKey()))
                    .toList();
              }, onSign: (e) async {
                final bodyBytes = e.signDoc.bodyBytes;
                final chainId = e.signDoc.chainId;
                if (bodyBytes == null || chainId == null) {
                  throw AppInternalError.internalError(
                      "SwapTransactionStateController._signTransaction");
                }
                final cosmosChain = route.sourceChain.cast<CosmosChain>();
                final transaction = Web3CosmosSignTransactionDirectParams(
                    bodyBytes: bodyBytes,
                    authInfos: e.signDoc.authInfoBytes,
                    accountNumber: e.signDoc.accountNumber);
                final params =
                    WalletActionInAppWeb3Request<Web3CosmosSignTransactionResponse>(
                        request: Web3CosmosSignTransaction(
                            account: Web3CosmosChainAccount.fromChainAccount(
                                address: accounts.first.cast<ICosmosAddress>(),
                                id: cosmosChain.network.value,
                                isDefault: false),
                            chainId: chainId,
                            transaction: transaction));
                final signature = (await wallet.wallet.doAction(params))
                    .unwrap()
                    .cast<Web3CosmosSignTransactionDirectSignResponse>();
                return CosmosSignResponse(
                    bodyBytes: signature.bodyBytes,
                    authBytes: signature.authInfoBytes,
                    signature: signature.signature);
              });
            });
      case const (SwapRouteSubstrateTransactionBuilder):
        return await (transaction as SwapRouteSubstrateTransactionBuilder)
            .buildTransactions(
                stepsCallBack: statusChanged,
                client: (network) async => client as BaseSwapSubstrateClient,
                signer: (e) async {
                  return SwapWeb3SignerSubstrate(
                      onSigner: () async => accounts
                          .map((e) => e.networkAddress)
                          .cast<BaseSubstrateAddress>()
                          .toList(),
                      onSign: (e) async {
                        final substrateChain = route.sourceChain.cast<SubstrateChain>();
                        final param = WalletActionInAppWeb3Request<
                                Web3SubstrateSendTransactionResponse>(
                            request: Web3SubstrateSendTransaction(
                                json: e.toJson(),
                                address: Web3SubstrateChainAccount.fromChainAccount(
                                    address: accounts.first.cast(),
                                    id: substrateChain.network.value,
                                    isDefault: false)));
                        final signature = (await wallet.wallet.doAction(param)).unwrap();
                        return signature.signatureHex;
                      });
                });
      case const (SwapRouteSolanaTransactionBuilder):
        return await (transaction as SwapRouteSolanaTransactionBuilder).buildTransactions(
            stepsCallBack: statusChanged,
            client: (network) async => client as BaseSwapSolanaClient,
            signer: (e) async {
              return SwapWeb3SignerSolana(
                  onSigner: () async =>
                      accounts.map((e) => e.networkAddress).cast<SolAddress>().toList(),
                  onSign: (e) async {
                    final substrateChain = route.sourceChain.cast<SolanaChain>();
                    final param =
                        WalletActionInAppWeb3Request<List<Web3SolanaTransactionResponse>>(
                            request: Web3SolanaSendTransaction(messages: [
                      Web3SolanaSendTransactionData(
                          account: Web3SolanaChainAccount.fromChainAccount(
                              address: accounts.first.cast(),
                              id: substrateChain.network.value,
                              network: substrateChain.network.coinParam.type,
                              isDefault: false),
                          messageByte: e.v0.serialize(),
                          sendConfig: null)
                    ], method: Web3SolanaRequestMethods.signTransaction));
                    final signedTransactions =
                        (await wallet.wallet.doAction(param)).unwrap();
                    return SolanaTransaction.deserialize(
                        signedTransactions.elementAt(0).signedTx);
                  });
            });
      case const (SwapRouteBitcoinTransactionBuilder):
        final btcAccounts = accounts.cast<IBitcoinAddress>();
        return await (transaction as SwapRouteBitcoinTransactionBuilder)
            .buildTransactions(
                stepsCallBack: statusChanged,
                client: (network) async => client as BaseSwapBitcoinClient,
                signer: (e) async {
                  return SwapWeb3SignerBitcoin(onSigner: () async {
                    return btcAccounts.map((e) {
                      return BitcoinSpenderAddress(
                          address: e.networkAddress,
                          taprootInternal: e.xOnly(),
                          witnessScript: e.witnessScript(),
                          p2shreedemScript: e.redeemScript());
                    }).toList();
                  }, onSendPayment: (e) async {
                    final bitcoinChain = route.sourceChain.cast<BitcoinChain>();
                    final param = WalletActionInAppWeb3Request<String>(
                        request: Web3BitcoinSendTransaction(
                            requiredAccount: Web3BitcoinChainAccount.fromChainAccount(
                                address: accounts
                                    .firstWhere(
                                        (i) => i.address == e.source.address.address)
                                    .cast(),
                                isDefault: false,
                                network: bitcoinChain.network),
                            outputs: e.outputs
                                .map((e) => Web3BitcoinSendTransactionOutput(
                                    value: e.value,
                                    scriptPubKey: e.script,
                                    address: e.address))
                                .toList(),
                            accounts: btcAccounts
                                .map((e) => Web3BitcoinChainAccount.fromChainAccount(
                                    address: e,
                                    isDefault: false,
                                    network: bitcoinChain.network))
                                .toList()));
                    return (await wallet.wallet.doAction(param)).unwrap();
                  });
                });

      default:
    }
  }

  Future<void> signTransaction() async {
    await _lock.run(() async {
      SafeStreamController<(TransactionOperationStep, String?)> onstatus =
          SafeStreamController(name: "SwapTransactionStateController.signTransaction");
      _latestError = null;
      _step = TransactionOperationStep.client;
      allowPop = false;
      notify();
      onstatus
          .stream()
          .listen((event) => _onUpdateState(event.$1, transactionHash: event.$2));
      final r = await IResult.call(() async {
        return _signTransaction(onstatus);
      });
      r.mapErr((e) {
        _step = null;
        if (e.tryAs<DartOnChainSwapPluginException>()
            case DartOnChainSwapPluginException(:final message)) {
          _latestError = message;
        } else {
          _latestError = e.localizationError;
        }
        return e.exception;
      });

      allowPop = true;
      notify();
      onstatus.close();
    });
  }

  @override
  void close() {
    super.close();
    progressKey.dispose();
  }
}

class SwapWeb3SignerEthereum implements Web3SignerEthereum {
  final Future<String> Function(Web3TransactionEthereum transaction) onSign;
  final Future<List<ETHAddress>> Function() onSigner;
  const SwapWeb3SignerEthereum({required this.onSign, required this.onSigner});
  @override
  Future<String> excuteTransaction(Web3TransactionEthereum transaction) {
    return onSign(transaction);
  }

  @override
  Future<List<ETHAddress>> signers() {
    return onSigner();
  }
}

class SwapWeb3SignerTron implements Web3SignerTron {
  final Future<Transaction> Function(Web3TransactionTron transaction) onSign;
  final Future<List<TronAddress>> Function() onSigner;
  const SwapWeb3SignerTron({required this.onSign, required this.onSigner});
  @override
  Future<Transaction> signTransaction(Web3TransactionTron transaction) {
    return onSign(transaction);
  }

  @override
  Future<List<TronAddress>> signers() {
    return onSigner();
  }
}

class SwapWeb3SignerXRP implements Web3SignerXRP {
  final Future<String> Function(SubmittableTransaction transaction) onSign;
  final Future<List<XRPBaseAddress>> Function() onSigner;
  const SwapWeb3SignerXRP({required this.onSign, required this.onSigner});
  @override
  Future<String> sendTransaction(SubmittableTransaction transaction) {
    return onSign(transaction);
  }

  @override
  Future<List<XRPBaseAddress>> signers() {
    return onSigner();
  }
}

class SwapWeb3SignerZcash implements Web3SignerZcash {
  final Future<String> Function(Web3TransactionZcash transaction) onSign;
  final Future<List<ZcashAddress>> Function() onSigner;
  const SwapWeb3SignerZcash({required this.onSign, required this.onSigner});
  @override
  Future<String> excuteTransaction(Web3TransactionZcash transaction) {
    return onSign(transaction);
  }

  @override
  Future<List<ZcashAddress>> signers() {
    return onSigner();
  }
}

class SwapWeb3SignerSolana implements Web3SignerSolana {
  final Future<List<SolAddress>> Function() onSigner;
  final Future<SolanaTransaction> Function(Web3TransactionSolana transaction) onSign;
  const SwapWeb3SignerSolana({required this.onSigner, required this.onSign});
  @override
  Future<SolanaTransaction> signTransaction(Web3TransactionSolana transaction) {
    return onSign(transaction);
  }

  @override
  Future<List<SolAddress>> signers() {
    return onSigner();
  }
}

class SwapWeb3SignerBitcoin implements Web3SignerBitcoin {
  final Future<List<BitcoinSpenderAddress>> Function() onSigner;
  final Future<String> Function(Web3TransactionBitcoin transaction) onSendPayment;
  const SwapWeb3SignerBitcoin({required this.onSigner, required this.onSendPayment});
  @override
  Future<String> signPsbt(Web3TransactionBitcoin transaction) {
    throw UnimplementedError();
  }

  @override
  Future<List<BitcoinSpenderAddress>> signers() {
    return onSigner();
  }

  @override
  BitcoinSigningScheme get signingSchames => BitcoinSigningScheme.sendPayment;

  @override
  Future<String> sendPayment(Web3TransactionBitcoin transaction) {
    return onSendPayment(transaction);
  }
}

class SwapWeb3SignerSubstrate implements Web3SignerSubstrate {
  final Future<List<BaseSubstrateAddress>> Function() onSigner;
  final Future<String> Function(Web3TransactionSubstrate transaction) onSign;
  const SwapWeb3SignerSubstrate({required this.onSigner, required this.onSign});

  @override
  Future<String> signTransaction(Web3TransactionSubstrate transaction) {
    return onSign(transaction);
  }

  @override
  Future<List<BaseSubstrateAddress>> signers() {
    return onSigner();
  }
}

class SwapWeb3SignerCosmos implements Web3SignerCosmos {
  final Future<List<CosmosSpenderAddress>> Function() onSigner;
  final Future<CosmosSignResponse> Function(Web3TransactionCosmos transaction) onSign;
  const SwapWeb3SignerCosmos({required this.onSigner, required this.onSign});

  @override
  Future<CosmosSignResponse> signRaw(Web3TransactionCosmos transaction) {
    return onSign(transaction);
  }

  @override
  Future<List<CosmosSpenderAddress>> signers() {
    return onSigner();
  }

  @override
  List<CosmosSigningScheme> get signingSchames =>
      [CosmosSigningScheme.amino, CosmosSigningScheme.direct];
}
