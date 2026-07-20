import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/stellar/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/stellar/params/core/request.dart';
import 'package:on_chain_wallet/web3/web3/networks/stellar/permission/models/account.dart';

class Web3StellarSendTransactionResponse with AppSerialization {
  final String envlope;
  final String? txHash;

  const Web3StellarSendTransactionResponse({required this.envlope, this.txHash});
  factory Web3StellarSendTransactionResponse.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.runtimeTag);
    return Web3StellarSendTransactionResponse(
        envlope: values.rawValueAt(0), txHash: values.rawValueAt(1));
  }

  Map<String, dynamic> toWalletConnectJson() {
    return {if (txHash != null) "txId": txHash, "envlope": envlope};
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [envlope.toCbor(), txHash?.toCbor()];
}

class Web3StellarSendTransaction
    extends Web3StellarRequestParam<Web3StellarSendTransactionResponse> {
  final List<int> transaction;
  Web3StellarSendTransaction._({
    required this.accessAccount,
    required List<int> transaction,
    required this.method,
  }) : transaction = transaction.asImmutableBytes;
  factory Web3StellarSendTransaction({
    required Web3StellarChainAccount account,
    required List<int> transaction,
    required Web3StellarRequestMethods method,
  }) {
    switch (method) {
      case Web3StellarRequestMethods.sendTransaction:
      case Web3StellarRequestMethods.signTransaction:
        break;
      default:
        throw Web3RequestExceptionConst.invalidRequest;
    }
    return Web3StellarSendTransaction._(
        accessAccount: account, transaction: transaction, method: method);
  }

  factory Web3StellarSendTransaction.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3MessageTypes.walletRequest.tag);
    return Web3StellarSendTransaction(
        account:
            Web3StellarChainAccount.deserialize(object: values.objectAt<CborTagValue>(1)),
        transaction: values.rawValueAt(2),
        method: Web3NetworkRequestMethods.findMethod<Web3StellarRequestMethods>(
                values.objectAt(0))
            .method);
  }

  @override
  final Web3StellarRequestMethods method;

  @override
  Future<
      IResult<
          Web3StellarRequest<Web3StellarSendTransactionResponse,
              Web3StellarSendTransaction>>> toRequest(
      {required Web3RequestInformation request,
      required Web3RequestAuthentication authenticated,
      required WEB3REQUESTNETWORKCONTROLLER<IStellarAddress, StellarChain,
              Web3StellarChainAccount>
          chainController}) async {
    final chain = await super.findRequestChain(
        request: request, authenticated: authenticated, chainController: chainController);
    return chain.map((chain) => Web3StellarRequest<Web3StellarSendTransactionResponse,
            Web3StellarSendTransaction>(
          params: this,
          authenticated: authenticated,
          chain: chain.$1,
          info: request,
          accounts: chain.$2,
        ));
  }

  @override
  Object? toJsWalletResponse(Web3StellarSendTransactionResponse response) {
    return response.toCbor().encode();
  }

  final Web3StellarChainAccount accessAccount;

  @override
  List<Web3StellarChainAccount> get requiredAccounts => [accessAccount];

  @override
  List<CborObject?> get serializationItems =>
      [method.methodInfos, accessAccount.toCbor(), CborBytesValue(transaction)];
}
