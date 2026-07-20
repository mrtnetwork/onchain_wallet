import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain/ada/src/models/transaction/transaction/transaction.dart';
import 'package:on_chain/ada/src/models/transaction/witnesses/models/transaction_witness_set.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/params/core/request.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/permission/permission.dart';

class Web3ADASignTransactionResponse with AppSerialization {
  final TransactionWitnessSet witness;
  final String txId;
  final String? error;
  Web3ADASignTransactionResponse(
      {required this.txId, required this.witness, required this.error});
  factory Web3ADASignTransactionResponse.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.runtimeTag);

    return Web3ADASignTransactionResponse(
        txId: values.rawValueAt(0),
        witness: TransactionWitnessSet.fromCborBytes(values.rawValueAt(1)),
        error: values.rawValueAt(2));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems =>
      [txId.toCbor(), CborBytesValue(witness.serialize()), error?.toCbor()];
}

class Web3ADASignTransactionsResponse with AppSerialization {
  final List<Web3ADASignTransactionResponse> witnesses;
  Web3ADASignTransactionsResponse(
      {required List<Web3ADASignTransactionResponse> witnesses})
      : witnesses = witnesses.immutable;
  factory Web3ADASignTransactionsResponse.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.runtimeTag);
    return Web3ADASignTransactionsResponse(
        witnesses: values
            .listAt<CborTagValue>(0)
            .map((e) => Web3ADASignTransactionResponse.deserialize(object: e))
            .toList());
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems =>
      [CborListValue.definite(witnesses.map((e) => e.toCbor()).toList())];
}

class Web3ADASignTransactionParams with AppSerialization {
  final ADATransaction transaction;
  final bool partialSign;
  Web3ADASignTransactionParams({required this.transaction, required this.partialSign});
  factory Web3ADASignTransactionParams.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.runtimeTag);
    return Web3ADASignTransactionParams(
        transaction: ADATransaction.fromCborBytes(values.rawValueAt(0)),
        partialSign: values.rawValueAt(1));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [
        CborBytesValue(transaction.serialize()),
        partialSign.toCbor(),
      ];
}

class Web3ADASignTransaction
    extends Web3ADARequestParam<Web3ADASignTransactionsResponse> {
  final List<Web3ADASignTransactionParams> transactions;
  final List<Web3ADAChainAccount> accounts;

  @override
  List<Web3ADAChainAccount> get requiredAccounts => accounts;

  Web3ADASignTransaction._({
    required List<Web3ADAChainAccount> accounts,
    required List<Web3ADASignTransactionParams> transactions,
    required this.method,
  })  : accounts = accounts.immutable,
        transactions = transactions.immutable;
  factory Web3ADASignTransaction(
      {required List<Web3ADAChainAccount> accounts,
      required Web3NetworkRequestMethods method,
      required List<Web3ADASignTransactionParams> transactions}) {
    if (accounts.isEmpty || transactions.isEmpty) {
      throw Web3RequestExceptionConst.invalidRequest;
    }
    switch (method) {
      case Web3ADARequestMethods.signTx:
      case Web3ADARequestMethods.submitTx:
      case Web3ADARequestMethods.submitUnsignedTx:
        if (transactions.length > 1) {
          throw Web3RequestExceptionConst.invalidRequest;
        }
        break;
      case Web3ADARequestMethods.signTransaction:
      case Web3ADARequestMethods.signAndSendTransaction:
      case Web3ADARequestMethods.submitTxs:
      case Web3ADARequestMethods.signTxs:
        break;
      default:
        throw Web3RequestExceptionConst.invalidRequest;
    }
    return Web3ADASignTransaction._(
        transactions: transactions, accounts: accounts, method: method.cast());
  }

  factory Web3ADASignTransaction.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3MessageTypes.walletRequest.tag);
    return Web3ADASignTransaction(
        method: Web3NetworkRequestMethods.findMethod(values.objectAt(0)).method,
        transactions: values
            .listAt<CborTagValue>(1)
            .map((e) => Web3ADASignTransactionParams.deserialize(object: e))
            .toList(),
        accounts: values
            .listAt<CborTagValue>(2)
            .map((e) => Web3ADAChainAccount.deserialize(object: e))
            .toList());
  }

  @override
  final Web3ADARequestMethods method;

  @override
  Future<IResult<Web3ADARequest<Web3ADASignTransactionsResponse, Web3ADASignTransaction>>>
      toRequest(
          {required Web3RequestInformation request,
          required Web3RequestAuthentication authenticated,
          required WEB3REQUESTNETWORKCONTROLLER<ICardanoAddress, ADAChain,
                  Web3ADAChainAccount>
              chainController}) async {
    final chain = await super.findRequestChain(
        request: request, authenticated: authenticated, chainController: chainController);
    return chain.map((chain) =>
        Web3ADARequest<Web3ADASignTransactionsResponse, Web3ADASignTransaction>(
            params: this,
            authenticated: authenticated,
            chain: chain.$1,
            info: request,
            accounts: chain.$2));
  }

  @override
  Object? toJsWalletResponse(Web3ADASignTransactionsResponse response) {
    return response.toCbor().encode();
  }

  @override
  List<CborObject?> get serializationItems => [
        method.methodInfos,
        CborListValue.definite(transactions.map((e) => e.toCbor()).toList()),
        AppSerialization.listFromObjects(accounts.map((e) => e.toCbor()).toList())
      ];
}
