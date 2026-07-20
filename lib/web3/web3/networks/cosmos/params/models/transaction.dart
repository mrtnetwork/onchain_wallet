import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cosmos_sdk/cosmos_sdk.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/cosmos/constant/constants/exception.dart';
import 'package:on_chain_wallet/web3/web3/networks/cosmos/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/cosmos/params/core/request.dart';
import 'package:on_chain_wallet/web3/web3/networks/cosmos/permission/models/account.dart';
import 'package:on_chain_wallet/web3/web3/utils/web3_validator_utils.dart';

abstract class Web3CosmosSignTransactionResponse with AppSerialization {
  final Web3CosmosRequestMethods method;
  final List<int> signature;
  final Any publicKey;
  String singaureAsBase64() {
    return StringUtils.decode(signature, encoding: StringEncoding.base64);
  }

  Web3CosmosSignTransactionResponse._(
      {required this.method, required List<int> signature, required this.publicKey})
      : signature = signature.asImmutableBytes;
  Map<String, dynamic> toWalletConnectJson();
  factory Web3CosmosSignTransactionResponse.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborTagValue cbor = AppSerialization.decode(
      cborBytes: bytes,
      cborObject: object,
    );
    final method = Web3CosmosRequestMethods.fromTags(cbor.tags);
    return switch (method) {
      Web3CosmosRequestMethods.signTransactionDirect =>
        Web3CosmosSignTransactionDirectSignResponse.deserialize(object: cbor),
      Web3CosmosRequestMethods.signTransactionAmino =>
        Web3CosmosSignTransactionAminoSignResponse.deserialize(object: cbor),
      _ => throw Web3RequestExceptionConst.invalidRequest
    };
  }

  T cast<T extends Web3CosmosSignTransactionResponse>() {
    if (this is! T) {
      throw Web3RequestExceptionConst.internalErr(
          "Web3CosmosSignTransactionResponse.cast",
          details: {"type": runtimeType.toString(), "expected": "$T"});
    }
    return this as T;
  }
}

class Web3CosmosSignTransactionDirectSignResponse
    extends Web3CosmosSignTransactionResponse {
  final List<int> bodyBytes;
  final List<int> authInfoBytes;
  final String chainId;
  final BigInt accountNumber;

  factory Web3CosmosSignTransactionDirectSignResponse.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3CosmosRequestMethods.signTransactionDirect.identifier);
    return Web3CosmosSignTransactionDirectSignResponse(
        signature: values.rawValueAt(0),
        publicKey: Any.deserialize(values.rawValueAt(1)),
        bodyBytes: values.rawValueAt(2),
        authInfoBytes: values.rawValueAt(3),
        chainId: values.rawValueAt(4),
        accountNumber: values.rawValueAt(5));
  }
  Web3CosmosSignTransactionDirectSignResponse(
      {required List<int> bodyBytes,
      required List<int> authInfoBytes,
      required super.signature,
      required this.chainId,
      required this.accountNumber,
      required super.publicKey})
      : bodyBytes = bodyBytes.asImmutableBytes,
        authInfoBytes = authInfoBytes.asImmutableBytes,
        super._(method: Web3CosmosRequestMethods.signTransactionDirect);

  factory Web3CosmosSignTransactionDirectSignResponse.fromJson(
      Map<String, dynamic> json) {
    return Web3CosmosSignTransactionDirectSignResponse(
        bodyBytes: (json["bodyBytes"] as List).cast(),
        authInfoBytes: (json["authInfoBytes"] as List).cast(),
        signature: (json["signature"] as List).cast(),
        chainId: json["chainId"],
        accountNumber: BigintUtils.parse(json["accountNumber"]),
        publicKey: Any.fromJson(json["pubKey"]));
  }

  @override
  Map<String, dynamic> toWalletConnectJson() {
    return {
      "signed": {
        "bodyBytes": StringUtils.decode(bodyBytes, encoding: StringEncoding.base64),
        "authInfoBytes":
            StringUtils.decode(authInfoBytes, encoding: StringEncoding.base64),
        "chainId": chainId,
        "accountNumber": accountNumber.toString()
      },
      "signature": {
        "signature": singaureAsBase64(),
        "pub_key": {"type": publicKey.typeUrl, "value": publicKey.toBase64()}
      },
    };
  }

  @override
  SerializationIdentifier get serializationIdentifier => method.identifier;

  @override
  List<CborObject?> get serializationItems => [
        CborBytesValue(signature),
        CborBytesValue(publicKey.toBuffer()),
        CborBytesValue(bodyBytes),
        CborBytesValue(authInfoBytes),
        chainId.toCbor(),
        accountNumber.toCbor()
      ];
}

class Web3CosmosSignTransactionAminoSignResponse
    extends Web3CosmosSignTransactionResponse {
  final AminoTx tx;
  Web3CosmosSignTransactionAminoSignResponse({
    required super.signature,
    required this.tx,
    required super.publicKey,
  }) : super._(method: Web3CosmosRequestMethods.signTransactionAmino);
  factory Web3CosmosSignTransactionAminoSignResponse.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3CosmosRequestMethods.signTransactionAmino.identifier);
    return Web3CosmosSignTransactionAminoSignResponse(
        signature: values.rawValueAt(0),
        publicKey: Any.deserialize(values.rawValueAt(1)),
        tx: AminoTx.fromJson(
            StringUtils.decodeJson<Map<String, dynamic>>(values.rawValueAt(2))));
  }
  factory Web3CosmosSignTransactionAminoSignResponse.fromJson(Map<String, dynamic> json) {
    return Web3CosmosSignTransactionAminoSignResponse(
        signature: (json["signature"] as List).cast(),
        tx: AminoTx.fromJson(json["tx"]),
        publicKey: Any.fromJson(json["pubKey"]));
  }

  @override
  Map<String, dynamic> toWalletConnectJson() {
    return {
      "tx": tx.toJson(),
      "signed": tx.toJson(),
      "signature": {
        "signature": singaureAsBase64(),
        "pub_key": {"type": publicKey.typeUrl, "value": publicKey.toBase64()}
      },
    };
  }

  @override
  SerializationIdentifier get serializationIdentifier => method.identifier;

  @override
  List<CborObject?> get serializationItems => [
        CborBytesValue(signature),
        CborBytesValue(publicKey.toBuffer()),
        CborBytesValue(StringUtils.encodeJson(tx.toJson())),
      ];
}

abstract class Web3CosmosSignTransactionParams with AppSerialization {
  final Web3CosmosRequestMethods method;
  const Web3CosmosSignTransactionParams({required this.method});
  factory Web3CosmosSignTransactionParams.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborTagValue tag = AppSerialization.decode(
      cborBytes: bytes,
      cborObject: object,
    );
    final method = Web3CosmosRequestMethods.fromTags(tag.tags);
    return switch (method) {
      Web3CosmosRequestMethods.signTransactionAmino =>
        Web3CosmosSignTransactionAminoParams.deserialize(object: tag),
      Web3CosmosRequestMethods.signTransactionDirect =>
        Web3CosmosSignTransactionDirectParams.deserialize(object: tag),
      _ => throw Web3RequestExceptionConst.invalidRequest
    };
  }
}

class Web3CosmosSignTransactionDirectParams extends Web3CosmosSignTransactionParams {
  final List<int> bodyBytes;
  final List<int>? authInfos;
  final BigInt? accountNumber;
  Web3CosmosSignTransactionDirectParams({
    required List<int> bodyBytes,
    required List<int>? authInfos,
    required this.accountNumber,
  })  : bodyBytes = bodyBytes.asImmutableBytes,
        authInfos = authInfos?.asImmutableBytes,
        super(method: Web3CosmosRequestMethods.signTransactionDirect);
  factory Web3CosmosSignTransactionDirectParams.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3CosmosRequestMethods.signTransactionDirect.identifier);
    return Web3CosmosSignTransactionDirectParams(
        bodyBytes: values.rawValueAt(0),
        authInfos: values.rawValueAt(1),
        accountNumber: values.rawValueAt(2));
  }

  @override
  SerializationIdentifier get serializationIdentifier => method.identifier;

  @override
  List<CborObject?> get serializationItems =>
      [CborBytesValue(bodyBytes), authInfos?.toCborBytes()];
}

class Web3CosmosSignTransactionAminoParams extends Web3CosmosSignTransactionParams {
  final AminoTx tx;
  Web3CosmosSignTransactionAminoParams(this.tx)
      : super(method: Web3CosmosRequestMethods.signTransactionAmino);
  factory Web3CosmosSignTransactionAminoParams.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3CosmosRequestMethods.signTransactionAmino.identifier);
    final data =
        StringUtils.decodeJson<Map<String, dynamic>>(values.rawValueAt<List<int>>(0));
    return Web3CosmosSignTransactionAminoParams(AminoTx.fromJson(data));
  }

  @override
  SerializationIdentifier get serializationIdentifier => method.identifier;

  @override
  List<CborObject?> get serializationItems => [CborBytesValue(tx.toBuffer())];
}

class Web3CosmosSignTransaction
    extends Web3CosmosRequestParam<Web3CosmosSignTransactionResponse> {
  final Web3CosmosChainAccount accessAccount;
  final String chainId;
  final Web3CosmosSignTransactionParams transaction;
  final bool? preferNoSetFee;
  final bool? preferNoSetMemo;
  final bool? disableBalanceCheck;
  final BigInt? timeoutHeight;

  Web3CosmosSignTransaction._(
      {required this.accessAccount,
      required this.chainId,
      required this.transaction,
      required this.preferNoSetFee,
      required this.preferNoSetMemo,
      required this.disableBalanceCheck,
      required this.timeoutHeight});
  factory Web3CosmosSignTransaction({
    required Web3CosmosChainAccount account,
    required String chainId,
    required Web3CosmosSignTransactionParams transaction,
    bool? preferNoSetFee,
    bool? preferNoSetMemo,
    bool? disableBalanceCheck,
    BigInt? timeoutHeight,
  }) {
    switch (transaction.method) {
      case Web3CosmosRequestMethods.signTransactionAmino:
      case Web3CosmosRequestMethods.signTransactionDirect:
        break;
      default:
        throw Web3RequestExceptionConst.invalidRequest;
    }
    return Web3CosmosSignTransaction._(
        accessAccount: account,
        chainId: chainId,
        disableBalanceCheck: disableBalanceCheck,
        preferNoSetFee: preferNoSetFee,
        preferNoSetMemo: preferNoSetMemo,
        transaction: transaction,
        timeoutHeight: timeoutHeight);
  }

  factory Web3CosmosSignTransaction.fromJson(
      {required Map<String, dynamic> json,
      required Web3CosmosRequestMethods method,
      required Web3CosmosChainAccount account,
      required String chainId}) {
    // final String? requestChainId = Web3ValidatorUtils.parseString(
    //     key: "chainId", method: method, json: json);
    if (method == Web3CosmosRequestMethods.signTransactionAmino) {
      final aminoJson = Web3ValidatorUtils.tryObjectAsMap(json["signDoc"]);
      if (aminoJson == null) {
        throw Web3CosmosExceptionConstant.invalidAminoSignDoc;
      }
      final AminoTx amino = AminoTx.fromJson(aminoJson);
      if (chainId != amino.chainId) {
        throw Web3CosmosExceptionConstant.mismatchChainId;
      }
      return Web3CosmosSignTransaction(
          account: account,
          chainId: amino.chainId,
          transaction: Web3CosmosSignTransactionAminoParams(amino));
    }
    final Map<String, dynamic> signDoc = Web3ValidatorUtils.parseMap(
        key: "signDoc", method: method, json: json, requiredKeys: ["bodyBytes"]);
    final List<int> bodyBytes = Web3ValidatorUtils.parseBase64(
        key: "bodyBytes", method: method, json: signDoc, allowBytes: true);
    final List<int>? authInfoBytes = Web3ValidatorUtils.parseBase64(
        key: "authInfoBytes", method: method, json: signDoc, allowBytes: true);
    final BigInt? accountNumber = Web3ValidatorUtils.parseBigInt(
        key: "accountNumber", method: method, json: signDoc, sign: false);
    return Web3CosmosSignTransaction(
        account: account,
        chainId: chainId,
        transaction: Web3CosmosSignTransactionDirectParams(
            bodyBytes: bodyBytes,
            authInfos: authInfoBytes,
            accountNumber: accountNumber));
  }

  factory Web3CosmosSignTransaction.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3MessageTypes.walletRequest.tag);
    return Web3CosmosSignTransaction(
        account:
            Web3CosmosChainAccount.deserialize(object: values.objectAt<CborTagValue>(1)),
        chainId: values.rawValueAt(2),
        transaction: Web3CosmosSignTransactionParams.deserialize(
            object: values.objectAt<CborTagValue>(3)),
        disableBalanceCheck: values.rawValueAt(4),
        preferNoSetFee: values.rawValueAt(5),
        preferNoSetMemo: values.rawValueAt(6));
  }

  @override
  Web3CosmosRequestMethods get method => transaction.method;

  @override
  Object? toJsWalletResponse(Web3CosmosSignTransactionResponse response) {
    return response.toCbor().encode();
  }

  @override
  Future<
      IResult<
          Web3CosmosRequest<Web3CosmosSignTransactionResponse,
              Web3CosmosSignTransaction>>> toRequest(
      {required Web3RequestInformation request,
      required Web3RequestAuthentication authenticated,
      required WEB3REQUESTNETWORKCONTROLLER<ICosmosAddress, CosmosChain,
              Web3CosmosChainAccount>
          chainController}) async {
    final chain = await super.findRequestChain(
        request: request, authenticated: authenticated, chainController: chainController);
    return chain.map((chain) =>
        Web3CosmosRequest<Web3CosmosSignTransactionResponse, Web3CosmosSignTransaction>(
          params: this,
          authenticated: authenticated,
          chain: chain.$1,
          info: request,
          accounts: chain.$2,
        ));
  }

  @override
  List<Web3CosmosChainAccount> get requiredAccounts => [accessAccount];

  @override
  List<CborObject?> get serializationItems => [
        method.methodInfos,
        accessAccount.toCbor(),
        chainId.toCbor(),
        transaction.toCbor(),
        disableBalanceCheck?.toCbor(),
        preferNoSetFee?.toCbor(),
        preferNoSetMemo?.toCbor()
      ];
}
