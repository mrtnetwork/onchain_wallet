import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/ripple/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/ripple/params/core/request.dart';
import 'package:on_chain_wallet/web3/web3/networks/ripple/permission/models/account.dart';

final class Web3XRPTransactionSignatureResponse with AppSerialization {
  final String? txnSignature;
  final String? signingPubKey;
  final List<Web3XRPTransactionSignatureMultiSignerResponse>? signers;
  Map<String, dynamic> toJson() {
    return {
      'SigningPubKey': signingPubKey ?? '',
      'TxnSignature': txnSignature,
      "Signers": signers?.map((e) => e.toJson()).toList()
    };
  }

  Web3XRPTransactionSignatureResponse._({
    this.txnSignature,
    this.signingPubKey,
    List<Web3XRPTransactionSignatureMultiSignerResponse>? signers,
  }) : signers = signers?.emptyAsNull?.immutable;
  factory Web3XRPTransactionSignatureResponse(
      {required String txnSignature, required String signingPubKey}) {
    return Web3XRPTransactionSignatureResponse._(
        txnSignature: txnSignature, signingPubKey: signingPubKey);
  }
  factory Web3XRPTransactionSignatureResponse.multiSigner(
      List<Web3XRPTransactionSignatureMultiSignerResponse> signers) {
    return Web3XRPTransactionSignatureResponse._(signers: signers);
  }
  factory Web3XRPTransactionSignatureResponse.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.runtimeTag);
    return Web3XRPTransactionSignatureResponse._(
        txnSignature: values.rawValueAt(0),
        signingPubKey: values.rawValueAt(1),
        signers: values
            .listAt<CborTagValue>(2)
            .map((e) =>
                Web3XRPTransactionSignatureMultiSignerResponse.deserialize(object: e))
            .toList());
  }

  Map<String, dynamic> toWalletConnectJson() {
    return toJson();
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [
        txnSignature?.toCbor(),
        signingPubKey?.toCbor(),
        AppSerialization.listFromObjects(signers?.map((e) => e.toCbor()).toList() ?? [])
      ];
}

final class Web3XRPTransactionSignatureMultiSignerResponse with AppSerialization {
  final String account;
  final String txnSignature;
  final String signingPubKey;
  const Web3XRPTransactionSignatureMultiSignerResponse(
      {required this.account, required this.txnSignature, required this.signingPubKey});
  factory Web3XRPTransactionSignatureMultiSignerResponse.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.runtimeTag);
    return Web3XRPTransactionSignatureMultiSignerResponse(
        account: values.rawValueAt(0),
        txnSignature: values.rawValueAt(1),
        signingPubKey: values.rawValueAt(2));
  }
  Map<String, dynamic> toJson() {
    return {
      'Signer': {
        'Account': account,
        'TxnSignature': txnSignature,
        'SigningPubKey': signingPubKey
      }
    };
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems =>
      [account.toCbor(), txnSignature.toCbor(), signingPubKey.toCbor()];
}

final class Web3XRPTransactionResponse with AppSerialization {
  final Web3XRPTransactionSignatureResponse signature;
  final String txBlob;
  final String? txId;
  const Web3XRPTransactionResponse(
      {required this.signature, required this.txBlob, this.txId});
  factory Web3XRPTransactionResponse.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.runtimeTag);
    return Web3XRPTransactionResponse(
        signature: Web3XRPTransactionSignatureResponse.deserialize(
            object: values.objectAt<CborTagValue>(0)),
        txBlob: values.rawValueAt(1),
        txId: values.rawValueAt(2));
  }

  Map<String, dynamic> toJson() {
    return {
      "txId": txId,
      "tx_blob": txBlob,
      ...signature.toJson(),
    }.withoutNullValue;
  }

  Map<String, dynamic> toWalletConnectJson() {
    return toJson();
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems =>
      [signature.toCbor(), txBlob.toCbor(), txId?.toCbor()];
}

class Web3XRPSendTransaction extends Web3XRPRequestParam<Web3XRPTransactionResponse> {
  final List<int> txBlob;
  final Web3XRPChainAccount account;
  Web3XRPSendTransaction._({
    required List<int> txBlob,
    required this.method,
    required this.account,
  }) : txBlob = txBlob.asImmutableBytes;
  factory Web3XRPSendTransaction(
      {required List<int> txBlob,
      required Web3NetworkRequestMethods method,
      required Web3XRPChainAccount account}) {
    switch (method) {
      case Web3XRPRequestMethods.sendTransaction:
      case Web3XRPRequestMethods.signTransaction:
        break;
      default:
        throw Web3RequestExceptionConst.invalidRequest;
    }
    return Web3XRPSendTransaction._(
        txBlob: txBlob, method: method.cast(), account: account);
  }

  factory Web3XRPSendTransaction.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3MessageTypes.walletRequest.tag);
    final method = Web3NetworkRequestMethods.findMethod(values.objectAt(0)).method;

    return Web3XRPSendTransaction(
        method: method,
        txBlob: values.rawValueAt(1),
        account:
            Web3XRPChainAccount.deserialize(object: values.objectAt<CborTagValue>(2)));
  }

  @override
  final Web3XRPRequestMethods method;

  @override
  Future<IResult<Web3XRPRequest<Web3XRPTransactionResponse, Web3XRPSendTransaction>>>
      toRequest(
          {required Web3RequestInformation request,
          required Web3RequestAuthentication authenticated,
          required WEB3REQUESTNETWORKCONTROLLER<IXRPAddress, XRPChain,
                  Web3XRPChainAccount>
              chainController}) async {
    final chain = await super.findRequestChain(
        request: request, authenticated: authenticated, chainController: chainController);
    return chain.map((chain) =>
        Web3XRPRequest<Web3XRPTransactionResponse, Web3XRPSendTransaction>(
            params: this,
            authenticated: authenticated,
            chain: chain.$1,
            info: request,
            accounts: chain.$2));
  }

  @override
  List<Web3XRPChainAccount> get requiredAccounts => [account];

  @override
  Object? toJsWalletResponse(Web3XRPTransactionResponse response) {
    return response.toCbor().encode();
  }

  @override
  List<CborObject?> get serializationItems =>
      [method.methodInfos, CborBytesValue(txBlob), account.toCbor()];
}
