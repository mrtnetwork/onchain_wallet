import 'dart:async';

import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:on_chain/tron/src/address/tron_address.dart';
import 'package:on_chain/tron/src/models/contract/base_contract/base_contract.dart';
import 'package:on_chain/tron/src/models/contract/transaction/transaction_raw.dart';
import 'package:on_chain/tron/src/provider/models/transaction.dart';
import 'package:on_chain_swap/on_chain_swap.dart';
import 'package:on_chain_wallet/app/error/exception.dart';
import 'package:on_chain_wallet/app/stream/live.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/controllers/fee.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/controllers/provider.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/transaction/types/types.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/tron/client/tron.dart';
import 'package:on_chain_wallet/wallet/chain/chain/chain.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';

class TronSwapClient extends BaseSwapTronClient
    with DisposableMixin, TronTransactionApiController, TronTransactionFeeController {
  @override
  final TronClient client;
  final List<ITronAddress> addresses;
  final TronChain account;
  TronSwapClient({required this.client, required this.addresses, required this.account});

  @override
  Future<int?> getAccountPermissionId(
      {required TronAddress address, required TronBaseContract contract}) async {
    final walletAddress =
        addresses.firstWhereNullable((e) => e.networkAddress == address);
    if (walletAddress == null) {
      throw WalletExceptionConst.accountDoesNotFound;
    }
    if (walletAddress.multiSigAccount) {
      return (walletAddress as ITronMultisigAddress).multiSignatureAccount.permissionID;
    }
    return null;
  }

  Future<SwapTronAccountAssetBalance> getAccountsAssetBalance(
      TronSwapAsset asset, TronAddress account) async {
    final contract = asset.contractAddress;

    final balance = switch (contract) {
      null => await getBalance(account),
      TronAddress contract =>
        await client.ethClient.getTokenBalance(contract: contract, address: account),
    };
    return SwapTronAccountAssetBalance(address: account, balance: balance, asset: asset);
  }

  @override
  Future<BigInt> getBalance(TronAddress address) async {
    final balance = await client.getAccountInfo(address);
    return balance?.balance ?? BigInt.zero;
  }

  @override
  Future<BigInt?> getBlockHeight() async {
    final block = await client.getNowBlock();
    return block.blockHeader.rawData.number;
  }

  @override
  Future<BigInt?> getTransactionFeeLimit(TransactionRaw transaction) async {
    final walletAddress =
        addresses.firstWhereNullable((e) => e.networkAddress == transaction.ownerAddress);
    if (walletAddress == null) {
      throw WalletExceptionConst.accountDoesNotFound;
    }
    int totalSigners = 1;
    if (walletAddress.multiSigAccount) {
      final multiSigAccount = walletAddress as ITronMultisigAddress;
      totalSigners = multiSigAccount.multiSignatureAccount.signers.length;
    }
    final resource = await walletAddress.getAccountResource_();
    final fee = await getRawTransactionFee(
        rawTransaction: transaction, resource: resource.ok(), totalSigners: totalSigners);
    return fee.fee.balance;
  }

  @override
  Future<BigInt> getTrc20TokenBalance(
      {required TronAddress address, required TronAddress contractAddress}) async {
    return await client.ethClient
        .getTokenBalance(contract: contractAddress, address: address);
  }

  @override
  Future<bool> initSwapClient() {
    return client.initSwapClient();
  }

  @override
  Future<TronBroadcastHexResponse> sendTransaction(String digest) {
    return client.sendTransaction(digest);
  }

  @override
  bool get closed => false;

  @override
  WalletTronNetwork get network => account.network;

  @override
  Future<TronSimulateTransaction> simulateTransaction() {
    throw WalletExceptionConst.unsuportedFeature;
  }

  @override
  Future<BigInt> getAllowance(
      {required TronAddress contract,
      required TronAddress owner,
      required TronAddress spender}) {
    return client.ethClient
        .getAllowance(contract: contract, owner: owner, spender: spender);
  }

  @override
  Future<TronGetTransactionByIdResponse> trackTransaction(
      {required String transactionId,
      Duration? timeout,
      Duration? periodicTimeOut}) async {
    Timer? timer;
    periodicTimeOut ??= Duration(seconds: account.network.coinParam.averageBlockTime);
    timeout ??= Duration(seconds: account.network.coinParam.totalConfirmationTime);
    try {
      final Completer<TronGetTransactionByIdResponse> completer =
          Completer<TronGetTransactionByIdResponse>();
      timer = Timer.periodic(periodicTimeOut, (_) async {
        final receipt =
            await client.getTransactionByTxId(transactionId).catchError((e, s) {
          return null;
        });
        if (receipt != null && !completer.isCompleted) {
          completer.complete(receipt);
        }
      });
      final receipt = await completer.future.timeout(timeout);
      return receipt;
    } on TimeoutException {
      throw AppException("transaction_confirmation_failed");
    } finally {
      timer?.cancel();
      timer = null;
    }
  }
}
