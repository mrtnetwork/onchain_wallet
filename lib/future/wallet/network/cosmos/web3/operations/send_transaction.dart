import 'dart:async';
import 'package:blockchain_utils/signer/const/constants.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:cosmos_sdk/cosmos_sdk.dart';
import 'package:cosmos_sdk/proto_messages/cosmos/tx/signing/v1beta1/src/signing.dart';
import 'package:cosmos_sdk/proto_messages/cosmos/tx/v1beta1/models.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/web3/controllers/controllers.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/web3/pages/send_transaction.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/web3/types/fee.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/web3.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/cosmos/clients/cosmos.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/networks/cosmos/extension/extension.dart';
import 'package:on_chain_wallet/wallet/models/networks/cosmos/models/network_types.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/cosmos.dart';
import 'package:on_chain_wallet/web3/web3/web3.dart';

class WebCosmosSignTransactionStateController
    extends Web3CosmosTransactionStateController<Web3CosmosSignTransactionResponse,
        Web3CosmosSignTransaction, IWeb3CosmosTransactionRawData> {
  StreamSubscription<void>? _feeListener;
  bool get isThorChain =>
      network.coinParam.networkType == CosmosNetworkTypes.thorAndForked;
  IWeb3CosmosTransactionRawData? _transactionData;
  IWeb3CosmosTransactionRawData get transactionData => _transactionData!;
  CosmosTransactionRequirment? _transactionRequirment;
  CosmosTransactionRequirment get transactionRequirment => _transactionRequirment!;
  CosmosWeb3TransactionFeeInfo? _currentFee;
  CosmosWeb3TransactionFeeInfo get fee => _currentFee!;

  WebCosmosSignTransactionStateController(
      {required super.walletProvider, required super.request});
  @override
  bool onUpdateMemo(String? memo) {
    if (super.onUpdateMemo(memo)) {
      simulateTransaction();
      onStateUpdated();
      return true;
    }
    return false;
  }

  @override
  void onRemoveMemo() {
    memo.setValue(null);
    simulateTransaction();
    onStateUpdated();
  }

  void onFeeUpdated(void _) {
    onStateUpdated();
  }

  @override
  TransactionStateStatus getStateStatus() {
    if (fee.simulateStatus.isProgress) {
      return TransactionStateStatus.error();
    }
    return TransactionStateStatus.ready(warning: fee.status.error);
  }

  Future<IWeb3CosmosTransactionRawData> _buildAminoTransactionData(
      {required Web3CosmosSignTransactionAminoParams params,
      required CosmosTransactionRequirment transactionRequirment}) async {
    final messages = params.tx.messages
        .map((e) => CosmosWeb3MessagesInfo(
              value:
                  StringUtils.fromJson(e.toJson(), indent: '', toStringEncodable: true),
              typeUrl: e.declarationId.getAminoType(),
            ))
        .toList();
    final auth = AuthInfo(signerInfos: [
      defaultAccount.signerInfo.copyWith(
          sequence: params.tx.sequence,
          modeInfo:
              ModeInfo(single: ModeInfoSingle(mode: SignMode.signModeLegacyAminoJson)))
    ], fee: Fee(amount: params.tx.fee.amount, gasLimit: params.tx.fee.gas));
    return IWeb3CosmosTransactionRawData(
        messages: messages,
        memo: params.tx.memo.isEmpty ? null : params.tx.memo,
        txBody: params.tx.messages.whereType<UnknownAminoService>().isEmpty
            ? TxBody(
                messages: params.tx.messages.map((e) => e.toAny()).toList(),
                memo: params.tx.memo,
                timeoutHeight: this.params.timeoutHeight)
            : null,
        auth: auth,
        accountNumber: params.tx.accountNumber);
  }

  Future<IWeb3CosmosTransactionRawData> _buildDirectTransactionData(
      {required Web3CosmosSignTransactionDirectParams params}) async {
    final txBody = TxBody.deserialize(params.bodyBytes);
    final memo = txBody.memo;
    final messages = txBody.messages;
    final messageInfos = messages.map((e) {
      return CosmosWeb3MessagesInfo(
          value: switch (e) {
            AnyBinary() => e.toBase64(),
            AnyJson(:final value) =>
              StringUtils.fromJson(value, indent: '', toStringEncodable: true),
          },
          typeUrl: e.typeUrl ?? "");
    }).toList();
    AuthInfo auth;
    final account = await client.tryGetAccount(defaultAccount.networkAddress);
    if (params.authInfos != null) {
      auth = AuthInfo.deserialize(params.authInfos!);
    } else {
      auth = AuthInfo(signerInfos: [
        defaultAccount.signerInfo.copyWith(sequence: account?.sequence ?? BigInt.zero)
      ], fee: Fee(amount: []));
    }
    return IWeb3CosmosTransactionRawData(
        messages: messageInfos,
        memo: memo,
        txBody: txBody,
        auth: auth,
        accountNumber: params.accountNumber ?? account?.accountNumber ?? BigInt.zero);
  }

  @override
  Future<IWeb3CosmosTransactionRawData> buildTransactionData(
      {bool simulate = false}) async {
    return _transactionData ??= await () async {
      try {
        final txRequirment = await getTransactionRequirment(owner: defaultAccount);
        switch (request.params.method) {
          case Web3CosmosRequestMethods.signTransactionAmino:
            return _buildAminoTransactionData(
                params: params.transaction as Web3CosmosSignTransactionAminoParams,
                transactionRequirment: txRequirment);
          case Web3CosmosRequestMethods.signTransactionDirect:
            return _buildDirectTransactionData(
              params: params.transaction as Web3CosmosSignTransactionDirectParams,
            );
          default:
            throw Web3RequestExceptionConst.methodDoesNotSupport;
        }
      } catch (e) {
        if (e == WalletExceptionConst.feeTokenNotFound) {
          throw Web3CosmosExceptionConstant.feeCoinNotFound;
        }
        rethrow;
      }
    }();
  }

  IWeb3CosmosTransaction<IWeb3CosmosTransactionRawData> _buildSigningDirectTransaction() {
    TxBody finalTx = transactionData.txBody!;
    finalTx = TxBody(
        messages: finalTx.messages,
        extensionOptions: finalTx.extensionOptions,
        memo: memo.output,
        nonCriticalExtensionOptions: finalTx.nonCriticalExtensionOptions,
        unordered: finalTx.unordered,
        timeoutHeight: finalTx.timeoutHeight);

    final auth = transactionData.auth.copyWith(fee: fee.toTransactionFee());
    final signDoc = SignDoc(
        bodyBytes: finalTx.toBuffer(),
        authInfoBytes: auth.toBuffer(),
        chainId: network.coinParam.chainId,
        accountNumber: transactionData.accountNumber);
    return IWeb3CosmosTransaction(
        account: defaultAccount,
        transactionData: transactionData,
        signDoc: signDoc,
        payloadBytes: signDoc.toBuffer(),
        auth: auth);
  }

  IWeb3CosmosTransaction<IWeb3CosmosTransactionRawData> _buildSigningAminoTransaction() {
    final params = request.params.transaction as Web3CosmosSignTransactionAminoParams;
    final aminoTx = params.tx.copyWith(fee: fee.toAminoFee(), memo: memo.output ?? '');

    return IWeb3CosmosTransaction(
        account: defaultAccount,
        transactionData: transactionData,
        aminoTransaction: aminoTx,
        payloadBytes: aminoTx.toBuffer(),
        auth: transactionData.auth.copyWith(fee: fee.toTransactionFee()));
  }

  @override
  Future<IWeb3CosmosTransaction<IWeb3CosmosTransactionRawData>> buildTransaction(
      {bool simulate = false}) async {
    switch (request.params.method) {
      case Web3CosmosRequestMethods.signTransactionAmino:
        return _buildSigningAminoTransaction();
      case Web3CosmosRequestMethods.signTransactionDirect:
        return _buildSigningDirectTransaction();
      default:
        throw Web3RequestExceptionConst.methodDoesNotSupport;
    }
  }

  @override
  Future<
          Web3RequestTransactionResponseData<
              Web3CosmosSignTransactionResponse,
              SubmitTransactionSuccess<
                  IWeb3CosmosSignedTransaction<IWeb3CosmosTransactionRawData>>>>
      getResponse() async {
    final transaction = await buildTransaction();
    final signedTransaction = await signTransaction(transaction);
    return Web3RequestTransactionResponseData(
        response: signedTransaction.finalTransactionData);
  }

  @override
  Future<IWeb3CosmosSignedTransaction<IWeb3CosmosTransactionRawData>> signTransaction(
      IWeb3CosmosTransaction<IWeb3CosmosTransactionRawData> transaction,
      {bool fakeSignature = false}) async {
    final signature = await signTransactionInternal(
        payload: transaction.payloadBytes,
        signer: transaction.account,
        fakeSignature: fakeSignature);
    switch (request.params.method) {
      case Web3CosmosRequestMethods.signTransactionDirect:
        final signDoc = transaction.signDoc!;
        return IWeb3CosmosSignedTransaction(
            transaction: transaction,
            signatures: [signature.signature],
            finalTransactionData: Web3CosmosSignTransactionDirectSignResponse(
                bodyBytes: signDoc.bodyBytes ?? [],
                authInfoBytes: signDoc.authInfoBytes ?? [],
                signature: signature.signature,
                chainId: network.coinParam.chainId,
                accountNumber: signDoc.accountNumber ?? BigInt.zero,
                publicKey: defaultAccount.toCosmosPublicKey().toAny()));
      case Web3CosmosRequestMethods.signTransactionAmino:
        return IWeb3CosmosSignedTransaction(
            transaction: transaction,
            signatures: [signature.signature],
            finalTransactionData: Web3CosmosSignTransactionAminoSignResponse(
                signature: signature.signature,
                tx: transaction.aminoTransaction!,
                publicKey: defaultAccount.toCosmosPublicKey().toAny()));
      default:
        throw Web3RequestExceptionConst.invalidRequest;
    }
  }

  @override
  Future<List<IWalletTransaction<CosmosWalletTransaction, ICosmosAddress>>>
      buildWalletTransaction(
          {required IWeb3CosmosSignedTransaction<IWeb3CosmosTransactionRawData> signedTx,
          required SubmitTransactionSuccess<
                  IWeb3CosmosSignedTransaction<IWeb3CosmosTransactionRawData>>?
              txId}) async {
    if (txId == null) return [];

    return [
      IWalletTransaction(
          transaction: CosmosWalletTransaction(
              txId: txId.txId,
              time: DateTime.now(),
              outputs: [],
              totalOutput: null,
              network: network,
              web3Client: web3ClientInfo()),
          account: defaultAccount)
    ];
  }

  @override
  Future<SubmitTransactionResult> submitTransaction(
      {required IWeb3CosmosSignedTransaction<IWeb3CosmosTransactionRawData>
          signedTransaction}) async {
    throw UnimplementedError();
  }

  Future<void> simulateTransaction() async {
    if (!fee.allowSimulate) return;
    fee.setPending();

    final tx = Tx(
        body: transactionData.txBody!,
        authInfo: transactionData.auth,
        signatures: [List<int>.filled(CryptoSignerConst.ecdsaSignatureLength, 0)]);
    final simulate = await IResult.call(() async {
      return simulateWeb3Transaction(tx.toBuffer());
    });
    if (simulate.isErr) {
      fee.setFail(
          CosmosWeb3TransactionSimulate.fail(simulate.unwrapErr().localizationError));
    } else {
      fee.setSimulate(CosmosWeb3TransactionSimulate.simulate(simulate.unwrap()));
    }
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return Web3CosmosSignOrSendTransactionsStateView(this);
  }

  @override
  Future<void> initForm(CosmosNetworkClient client) async {
    await super.initForm(client);
    _transactionData ??= await buildTransactionData();
    if (transactionData.memo != null) {
      memo.setValue(transactionData.memo);
    }
    final fee = transactionData.auth.fee;
    _transactionRequirment = await getTransactionRequirment(
        owner: defaultAccount, fee: transactionData.auth.fee);
    if (transactionRequirment.account == null) {
      throw Web3RequestExceptionConst.inactiveAccount;
    }
    _currentFee = CosmosWeb3TransactionFeeInfo(
        fee: fee!,
        totalMessage: transactionData.messages.length,
        transactionRequirment: transactionRequirment,
        feeTokens: transactionRequirment.feeTokens,
        allowSimulate: transactionData.txBody != null,
        network: network);
    _currentFee?.onStateUpdated();
    simulateTransaction();
    _feeListener = _currentFee?.notifier.stream.listen(onFeeUpdated);
  }

  @override
  void dispose() {
    super.dispose();
    _feeListener?.cancel();
    _feeListener = null;
    _currentFee?.dispose();
  }
}
