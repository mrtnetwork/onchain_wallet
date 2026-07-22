import 'package:blockchain_utils/signer/types/eth_signature.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain/ethereum/src/models/access_list.dart';
import 'package:on_chain/ethereum/src/transaction/eth_transaction.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/signing.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/transaction/controllers/fee.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/web3/controllers/controllers.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/web3/controllers/provider.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/web3/pages/send_transaction.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/web3.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/networks/ethereum/params/models/send_transaction.dart';

class Web3EthereumSendTransactionStateController
    extends Web3EthereumTransactionStateController<String, Web3EthreumSendTransaction,
        IWeb3EthereumTransactionData>
    with SolidityWeb3TransactionApiController, EthereumTransactionFeeController {
  IWeb3EthereumTransactionData? _transactionData;
  IWeb3EthereumTransactionData get transactionData => _transactionData!;

  int? _gasLimit;

  @override
  int? get fixedGasLimit => _gasLimit;

  @override
  EthereumNetworkClient get solidityClient => client;

  Web3EthereumSendTransactionStateController(
      {required super.walletProvider, required super.request});
  @override
  BigInt getMaxFeeInput() {
    final account = defaultAccount;
    return account.addressData.currencyBalance - params.value;
  }

  @override
  Future<IWeb3EthereumTransaction<IWeb3EthereumTransactionData>> buildTransaction(
      {bool simulate = false}) async {
    final account = defaultAccount;
    final fee = txFee.fee;
    final nonce = await client.getAccountNonce(account.networkAddress);
    final transaction = ETHTransaction(
        type: transactionData.transactionInfos.type,
        from: account.networkAddress,
        chainId: network.coinParam.chainId,
        data: params.data,
        nonce: nonce,
        accessList: params.accessList
            ?.map((e) => AccessEntry(
                address: e.address,
                storageKeys:
                    e.storageKeys.map((e) => BytesUtils.toHexString(e)).toList()))
            .toList(),
        gasPrice: fee.gasPrice,
        maxFeePerGas: fee.maxFeePerGas,
        maxPriorityFeePerGas: fee.maxPriorityFeePerGas,
        gasLimit: BigInt.from(fee.gasLimit),
        value: params.value,
        to: params.to);
    return IWeb3EthereumTransaction(
        account: account, transactionData: transactionData, transaction: transaction);
  }

  @override
  Future<IWeb3EthereumTransactionData> buildTransactionData(
      {bool simulate = false}) async {
    return _transactionData ??= await () async {
      final account = defaultAccount;
      final data = await getWeb3TransactionInfos(
          from: account, transaction: params, chain: this.account);
      return IWeb3EthereumTransactionData(transactionInfos: data);
    }();
  }

  @override
  Future<List<IWalletTransaction<EthWalletTransaction, IEthereumAddress>>>
      buildWalletTransaction(
          {required IWeb3EthereumSignedTransaction<IWeb3EthereumTransactionData> signedTx,
          required SubmitTransactionSuccess? txId}) async {
    if (txId == null) return [];
    final EthWalletTransaction transaction = EthWalletTransaction(
        txId: txId.txId,
        outputs: [],
        type: WalletTransactionType.web3Tx,
        totalOutput: WalletTransactionIntegerAmount(
            amount: signedTx.transaction.transaction.value, network: network),
        web3Client: WalletWeb3ClientTransaction(
            name: request.authenticated.name,
            applicationId: request.authenticated.applicationId,
            image: request.authenticated.icon),
        network: network);
    return [
      IWalletTransaction(transaction: transaction, account: signedTx.transaction.account)
    ];
  }

  @override
  Map<String, dynamic> buildEstimateTx() {
    final address = defaultAccount.networkAddress;
    final transaction = ETHTransaction(
        type: transactionData.transactionInfos.type,
        from: address,
        to: params.to,
        nonce: 0,
        gasLimit: BigInt.zero,
        data: params.data,
        value: BigInt.zero,
        accessList: params.accessList
            ?.map((e) => AccessEntry(
                address: e.address,
                storageKeys:
                    e.storageKeys.map((e) => BytesUtils.toHexString(e)).toList()))
            .toList(),
        chainId: network.coinParam.chainId);
    return transaction.toEstimate();
  }

  @override
  Future<IWeb3EthereumSignedTransaction<IWeb3EthereumTransactionData>> signTransaction(
      IWeb3EthereumTransaction<IWeb3EthereumTransactionData> transaction,
      {bool fakeSignature = false}) async {
    final account = transaction.account;
    final ethTransaction = transaction.transaction;
    final WalletSigningRequest<ETHSignature> request = WalletSigningRequest<ETHSignature>(
      addresses: [account],
      network: network,
      sign: (generateSignature) async {
        final signRequest = GlobalSignRequest.eth(
            digest: ethTransaction.serialized, index: account.derivationIndex.cast());
        final ethSignature = await generateSignature(signRequest);
        return ETHSignature.fromBytes(ethSignature.signature);
      },
    );
    final signature = await walletProvider.wallet
        .signTransaction(params: WalletActionSign(request: request));
    final serializedData = BytesUtils.toHexString(
        ethTransaction.signedSerialized(signature.unwrap()),
        prefix: "0x");
    return IWeb3EthereumSignedTransaction(
        transaction: transaction,
        signatures: [signature.unwrap().toBytes()],
        finalTransactionData: serializedData);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return Web3EthereumSendTransactionStateView(this);
  }

  Future<void> buildFee() async {
    final estimateTxJson = buildEstimateTx();
    final gasLimit = await client.estimateGasLimit(estimateTxJson);
    final feeData = transactionData.transactionInfos.initFee;
    EthereumTransactionFee? fee;
    EthereumFeeMode mode;
    switch (transactionData.transactionInfos.type) {
      case ETHTransactionType.eip1559:
        mode = EthereumFeeMode.eip1559;
        final maxFeePerGas = feeData?.maxFeePerGas;
        final maxPriorityFeePerGas = feeData?.maxPriorityFeePerGas;
        if (maxPriorityFeePerGas != null && maxFeePerGas != null) {
          fee = EthereumTransactionFee.eip1559(
              feeToken: network.token,
              gasLimit: feeData?.gasLimit ?? gasLimit.toInt(),
              maxPriorityFeePerGas: maxPriorityFeePerGas,
              maxFeePerGas: maxFeePerGas,
              baseFee: BigInt.zero,
              type: TxFeeTypes.manually);
        }
        break;
      default:
        mode = EthereumFeeMode.legacy;
        final gasPrice = feeData?.gasPrice;
        if (gasPrice != null) {
          fee = EthereumTransactionFee.legacy(
              feeToken: network.token,
              gasLimit: feeData?.gasLimit ?? gasLimit.toInt(),
              gasPrice: gasPrice,
              type: TxFeeTypes.manually);
        }
        break;
    }
    await super.initFee(mode: mode);
    if (fee != null) {
      txFee.setFee(fee);
    }
    _gasLimit = fee == null ? feeData?.gasLimit : null;
    estimateFee();
  }

  @override
  Future<void> initForm(EthereumNetworkClient client) async {
    _transactionData = await buildTransactionData(simulate: false);
    await buildFee();
    txFee.stream.listen((_) => onStateUpdated());
  }

  @override
  Future<
          Web3RequestTransactionResponseData<
              String,
              SubmitTransactionSuccess<
                  IWeb3EthereumSignedTransaction<IWeb3EthereumTransactionData>>>>
      getResponse() async {
    final txId = await buildSignAndSendTransaction();
    return Web3RequestTransactionResponseData.submitTx(
        response: txId.txId, txIds: [txId]);
  }

  @override
  TransactionStateStatus getStateStatus() {
    if (txFee.isPending) return TransactionStateStatus.error();
    return super.getStateStatus();
  }
}
