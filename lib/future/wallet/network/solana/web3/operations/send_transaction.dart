import 'dart:async';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:flutter/material.dart';
import 'package:on_chain/solana/src/rpc/models/models/commitment.dart';
import 'package:on_chain/solana/src/rpc/models/models/encoding.dart';
import 'package:on_chain/solana/src/transaction/transaction/transaction.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/signing.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/web3/controllers/controllers.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/web3/pages/send_transaction.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/web3/types/transaction.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/web3.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/solana/solana.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/signing/signing.dart';
import 'package:on_chain_wallet/wallet/models/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/networks/solana/params/models/transaction.dart';

class WebSolanaSignTransactionStateController
    extends Web3SolanaTransactionStateController<List<Web3SolanaTransactionResponse>,
        Web3SolanaSendTransaction, IWeb3SolanaTransactionRawData> {
  IWeb3SolanaTransactionRawData? _transactionData;
  IWeb3SolanaTransactionRawData get transactionData => _transactionData!;
  bool _hasSimulateError = false;
  bool get hasSimulateError => _hasSimulateError;
  bool _hasFeeError = false;
  bool get hasFeeError => _hasFeeError;
  late final StreamValue<IntegerBalance> totalFee = StreamValue(
      IntegerBalance.zero(network.token),
      name: "WebSolanaSignTransactionStateController");
  // late final StreamValue<IntegerBalance> totalSol =
  //     StreamValue(IntegerBalance.zero(network.token));

  WebSolanaSignTransactionStateController(
      {required super.walletProvider, required super.request});

  @override
  Future<SubmitTransactionResult> submitTransaction(
      {required IWeb3SolanaSignedTransaction<IWeb3SolanaTransactionRawData>
          signedTransaction}) async {
    throw UnimplementedError();
  }

  Future<SubmitTransactionResult> submitTransactionInternal(
      {required SolanaWeb3TransactionInfo transaction,
      required IWeb3SolanaSignedTransaction<IWeb3SolanaTransactionRawData>
          signedTransaction}) async {
    final config = transaction.sendTransactionOptions;
    final txId = await IResult.call(() async {
      return await client.sendTransaction(
        transaction.transaction,
        encoding: SolanaRequestEncoding.base64,
        skipPreflight: config?.skipPreflight ?? false,
        maxRetries: config?.maxRetries ?? 5,
        minContextSlot: config?.minContextSlot,
        commitment: Commitment.fromName(config?.commitment ?? "",
            defaultValue: Commitment.processed),
      );
    });
    if (txId.isErr) {
      return SubmitTransactionFailed(txId.unwrapErr().localizationError);
    }
    return SubmitTransactionSuccess(
        txId: txId.unwrap(), signedTransaction: signedTransaction);
  }

  void onMessageChanged(void _) {
    totalFee.value.updateBalance(transactionData.messagess.map((e) => e.fee.balance).sum);
    _hasFeeError = transactionData.messagess.any((e) => e.feeStatus.isError);
    totalFee.notify();
    _hasSimulateError = transactionData.messagess.any((e) => e.status.isError);
    onStateUpdated();
  }

  @override
  TransactionStateStatus getStateStatus() {
    if (transactionData.messagess.any((e) => e.status.isPending)) {
      return TransactionStateStatus.error();
    }
    if (transactionData.messagess.any((e) => e.feeStatus.isPending)) {
      return TransactionStateStatus.error();
    }
    if (transactionData.messagess.any((e) => e.status.isError)) {
      return TransactionStateStatus.ready(warning: "transaction_simulation_failed".tr);
    }

    return TransactionStateStatus.ready();
  }

  @override
  Future<IWeb3SolanaTransaction<IWeb3SolanaTransactionRawData>> buildTransaction(
      {bool simulate = false}) async {
    return IWeb3SolanaTransaction(
        account: defaultAccount, transactionData: transactionData);
  }

  @override
  Future<IWeb3SolanaTransactionRawData> buildTransactionData(
      {bool simulate = false}) async {
    return _transactionData ??= await () async {
      final List<SolanaWeb3TransactionInfo> messagess = [];
      List<ISolanaAddress> addresses = [];
      final List<ISolanaAddress> signers = request.accounts;
      for (final i in params.messages) {
        final permission = signers.firstWhere(
            (e) => e.networkAddress == i.account.address,
            orElse: () => throw Web3RequestExceptionConst.missingPermission);
        addresses.add(permission);
        final message = SolanaWeb3TransactionInfo(
            transaction: SolanaTransaction.deserialize(i.messageBytes),
            signer: permission,
            network: network,
            sendTransactionOptions: i.sendConfig,
            client: client);
        messagess.add(message);
      }
      bool isSend = params.isSend;
      bool canReplaceBlockHash = isSend && messagess.any((e) => e.canUpdateBlockHash);
      final hasSameOwner = messagess.map((e) => e.signer.networkAddress).toSet().length !=
          messagess.length;

      final messages = IWeb3SolanaTransactionRawData(
          messagess: messagess,
          isSend: isSend,
          canReplaceBlockHash: canReplaceBlockHash,
          isMultipleTransaction: params.isBatchRequest,
          isMultipleWithSameOwner: params.isBatchRequest && hasSameOwner,
          mode: params.mode ?? SolanaSignAndSendAllTransactionMode.serial);
      return messages;
    }();
  }

  @override
  Future<List<IWalletTransaction<SolanaWalletTransaction, ISolanaAddress>>>
      buildWalletTransaction(
          {required IWeb3SolanaSignedTransaction<IWeb3SolanaTransactionRawData> signedTx,
          required SubmitTransactionSuccess<
                  IWeb3SolanaSignedTransaction<IWeb3SolanaTransactionRawData>>?
              txId}) async {
    if (txId == null) return [];
    final id = StringUtils.encode(txId.txId, encoding: StringEncoding.base58);
    final tx = txId.signedTransaction.finalTransactionData.firstWhereOrNull(
        (e) => e.info.transaction.signatures.any((e) => BytesUtils.bytesEqual(e, id)));
    assert(tx != null);
    if (tx == null) return [];

    final transaction = SolanaWalletTransaction(
      txId: txId.txId,
      type: WalletTransactionType.web3Tx,
      web3Client: web3ClientInfo(),
      outputs: [],
      network: network,
    );
    return [IWalletTransaction(transaction: transaction, account: tx.info.signer)];
  }

  @override
  Future<
          Web3RequestTransactionResponseData<
              List<Web3SolanaTransactionResponse>,
              SubmitTransactionSuccess<
                  IWeb3SolanaSignedTransaction<IWeb3SolanaTransactionRawData>>>>
      getResponse() async {
    final transaction = await buildTransaction();
    final signedTransaction = await signTransaction(transaction);
    final result = signedTransaction.finalTransactionData
        .map((e) => Web3SolanaTransactionResponse(
            signature: e.signature, signedTx: e.info.transaction.serialize()))
        .toList();
    if (!transactionData.isSend) {
      return Web3RequestTransactionResponseData(response: result);
    }
    final isSerial =
        transaction.transactionData.mode == SolanaSignAndSendAllTransactionMode.serial;
    List<SubmitTransactionResult> results = [];

    for (final i in signedTransaction.finalTransactionData) {
      final result = await submitTransactionInternal(
          transaction: i.info, signedTransaction: signedTransaction);
      results.add(result);
      if (result.status.isFailed && isSerial) break;
    }
    return Web3RequestTransactionResponseData.submitTx(response: result, txIds: results);
  }

  @override
  Future<IWeb3SolanaSignedTransaction<IWeb3SolanaTransactionRawData>> signTransaction(
      IWeb3SolanaTransaction<IWeb3SolanaTransactionRawData> transaction,
      {bool fakeSignature = false}) async {
    final messages = transaction.transactionData.messagess;
    final signers = transaction.transactionData.messagess.map((e) => e.signer).toList();
    final signatures = await walletProvider.wallet.signTransaction(
        params: WalletActionSign(
            request: WalletSigningRequest(
      network: network,
      addresses: signers,
      sign: (generateSignature) async {
        final List<SolanaWeb3SignedTransactionInfo> signatures = [];
        for (final i in messages) {
          final digest = List<int>.unmodifiable(i.transaction.serializeMessage());
          final Bip32DerivationIndex signer = i.signer.derivationIndex.cast();
          final signRequest = GlobalSignRequest.solana(digest: digest, index: signer);
          final signingResponse = await generateSignature(signRequest);
          i.transaction.addSignature(i.signer.networkAddress, signingResponse.signature);
          final signignInfo = SolanaWeb3SignedTransactionInfo(
              info: i, signature: signingResponse.signature);
          signatures.add(signignInfo);
        }
        return signatures;
      },
    )));
    return IWeb3SolanaSignedTransaction(
        transaction: transaction,
        signatures: signatures.unwrap().map((e) => e.signature).toList(),
        finalTransactionData: signatures.unwrap());
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return Web3SolanaSignOrSendTransactionsStateView(this);
  }

  @override
  Future<void> initForm(SolanaNetworkClient client) async {
    await super.initForm(client);
    _transactionData = await buildTransactionData();
    for (final message in transactionData.messagess) {
      message.stream.listen(onMessageChanged);
      message.simulate();
      message.getFee();
    }
  }

  @override
  void dispose() {
    super.dispose();
    final messages = _transactionData?.messagess ?? [];
    for (final i in messages) {
      i.dispose();
    }
  }
}
