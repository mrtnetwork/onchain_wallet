import 'package:blockchain_utils/base58/base58_base.dart';
import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';

import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/solana/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/solana/params/core/request.dart';
import 'package:on_chain_wallet/web3/web3/networks/solana/permission/models/account.dart';
import 'package:on_chain/ethereum/src/eip_4361/eip_4361.dart';
import 'package:on_chain/solana/solana.dart';
import 'package:on_chain_wallet/web3/web3/utils/web3_validator_utils.dart';

class Web3SolanaSignInParams extends Web3SolanaSignParams {
  final EIP4631 message;
  @override
  late final String content = message.toMessage();
  Web3SolanaSignInParams({required this.message, required super.account})
      : super(data: message.toHex());
  factory Web3SolanaSignInParams.fromJson(
      {required Map<String, dynamic> json, required Web3SolanaChainAccount account}) {
    const method = Web3SolanaRequestMethods.signIn;
    final message = EIP4631(
        domain: Web3ValidatorUtils.parseString(key: "domain", method: method, json: json),
        address: account.addressStr,
        statement:
            Web3ValidatorUtils.parseString(key: "statement", method: method, json: json),
        chainId:
            Web3ValidatorUtils.parseString(key: "chainId", method: method, json: json),
        expirationTime: Web3ValidatorUtils.parseString(
            key: "expirationTime", method: method, json: json),
        issuedAt:
            Web3ValidatorUtils.parseString(key: "issuedAt", method: method, json: json),
        nonce: Web3ValidatorUtils.parseString(key: "nonce", method: method, json: json),
        notBefore:
            Web3ValidatorUtils.parseString(key: "notBefore", method: method, json: json),
        requestId:
            Web3ValidatorUtils.parseString(key: "requestId", method: method, json: json),
        resources: Web3ValidatorUtils.parseList<List<String>?, String>(
            key: "resources", method: method, json: json),
        uri: Web3ValidatorUtils.parseString(key: "uri", method: method, json: json),
        version:
            Web3ValidatorUtils.parseString(key: "version", method: method, json: json));
    return Web3SolanaSignInParams(message: message, account: account);
  }
  factory Web3SolanaSignInParams.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.web3SolanaSignInParams);
    return Web3SolanaSignInParams(
      account:
          Web3SolanaChainAccount.deserialize(object: values.objectAt<CborTagValue>(0)),
      message: EIP4631.fromJson(StringUtils.toJson(values.rawValueAt(1))),
    );
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.web3SolanaSignInParams;

  @override
  List<CborObject?> get serializationItems => [
        account.toCbor(),
        CborStringValue(StringUtils.fromJson(message.toJson())),
      ];
}

class Web3SolanaSignMessageResponse {
  final SolAddress address;
  final List<int> signature;
  final List<int> signedMessage;
  Web3SolanaSignMessageResponse(
      {required this.address,
      required List<int> signature,
      required List<int> signedMessage})
      : signature = signature.asImmutableBytes,
        signedMessage = signedMessage.asImmutableBytes;
  factory Web3SolanaSignMessageResponse.fromJson(Map<String, dynamic> json) {
    return Web3SolanaSignMessageResponse(
      address: SolAddress(json["signer"]),
      signature: (json["signature"] as List).cast(),
      signedMessage: (json["signedMessage"] as List).cast(),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      "signer": address.address,
      "signerAddressBytes": address.toBytes(),
      "signature": signature,
      "signedMessage": signedMessage
    };
  }

  Map<String, dynamic> toWalletConnectJson() {
    return {
      "signature": Base58Encoder.encode(signature),
      "signedMessage": StringUtils.decode(signedMessage, encoding: StringEncoding.base64),
    };
  }
}

abstract class Web3SolanaSignParams with AppSerialization {
  final Web3SolanaChainAccount account;
  final String data;
  String? get content;

  List<int> dataBytes() {
    return BytesUtils.fromHexString(data).asImmutableBytes;
  }

  const Web3SolanaSignParams({required this.account, required this.data});
}

class Web3SolanaSignMessageParams extends Web3SolanaSignParams {
  @override
  final String? content;
  Web3SolanaSignMessageParams(
      {required super.data, required super.account, required this.content});
  factory Web3SolanaSignMessageParams.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.web3SolanaSignMessageParams);
    return Web3SolanaSignMessageParams(
        account:
            Web3SolanaChainAccount.deserialize(object: values.objectAt<CborTagValue>(0)),
        data: values.rawValueAt(1),
        content: values.rawValueAt(2));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.web3SolanaSignMessageParams;

  @override
  List<CborObject?> get serializationItems => [
        account.toCbor(),
        data.toCbor(),
        content?.toCbor(),
      ];
}

class Web3SolanaSignMessage
    extends Web3SolanaRequestParam<List<Web3SolanaSignMessageResponse>> {
  final List<Web3SolanaSignParams> messages;
  Web3SolanaSignMessage._(
      {required List<Web3SolanaSignParams> messages, required this.method})
      : messages = messages.immutable;
  factory Web3SolanaSignMessage(
      {required List<Web3SolanaSignParams> messages,
      required Web3SolanaRequestMethods method}) {
    switch (method) {
      case Web3SolanaRequestMethods.signMessage:
      case Web3SolanaRequestMethods.signIn:
        break;
      default:
        throw Web3RequestExceptionConst.invalidRequest;
    }
    // if (messages.isEmpty) {
    //   throw Web3RequestExceptionConst.invalidWalletStandardSignMessage;
    // }
    if (messages.map((e) => e.account.id).toSet().length != 1) {
      throw Web3RequestExceptionConst.multipleBatchRequestNetwork;
    }
    return Web3SolanaSignMessage._(messages: messages, method: method);
  }

  factory Web3SolanaSignMessage.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3MessageTypes.walletRequest.tag);
    final method =
        Web3NetworkRequestMethods.findMethod<Web3SolanaRequestMethods>(values.objectAt(0))
            .method;
    switch (method) {
      case Web3SolanaRequestMethods.signMessage:
        return Web3SolanaSignMessage(
            messages: values
                .listAt<CborTagValue>(1)
                .map((e) => Web3SolanaSignMessageParams.deserialize(object: e))
                .toList(),
            method: method);
      case Web3SolanaRequestMethods.signIn:
        return Web3SolanaSignMessage(
            messages: values
                .listAt<CborTagValue>(1)
                .map((e) => Web3SolanaSignInParams.deserialize(object: e))
                .toList(),
            method: method);
      default:
        throw Web3RequestExceptionConst.invalidRequest;
    }
  }

  @override
  final Web3SolanaRequestMethods method;

  @override
  Object? toJsWalletResponse(List<Web3SolanaSignMessageResponse> response) {
    return response.map((e) => e.toJson()).toList();
  }

  @override
  Future<
      IResult<
          Web3SolanaRequest<List<Web3SolanaSignMessageResponse>,
              Web3SolanaSignMessage>>> toRequest(
      {required Web3RequestInformation request,
      required Web3RequestAuthentication authenticated,
      required WEB3REQUESTNETWORKCONTROLLER<ISolanaAddress, SolanaChain,
              Web3SolanaChainAccount>
          chainController}) async {
    final chain = await super.findRequestChain(
        request: request, authenticated: authenticated, chainController: chainController);
    return chain.map((chain) =>
        Web3SolanaRequest<List<Web3SolanaSignMessageResponse>, Web3SolanaSignMessage>(
          params: this,
          authenticated: authenticated,
          chain: chain.$1,
          info: request,
          accounts: chain.$2,
        ));
  }

  @override
  List<Web3SolanaChainAccount> get requiredAccounts =>
      messages.map((e) => e.account).toList();

  @override
  List<CborObject?> get serializationItems => [
        method.methodInfos,
        AppSerialization.listFromObjects(messages.map((e) => e.toCbor()).toList()),
      ];
}
