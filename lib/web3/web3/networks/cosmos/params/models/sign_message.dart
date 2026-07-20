import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';

import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/cosmos/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/cosmos/params/core/request.dart';
import 'package:on_chain_wallet/web3/web3/networks/cosmos/permission/models/account.dart';

class Web3CosmosSignMessageResponse with AppSerialization {
  final List<int> messageBytes;
  final List<int> signature;
  Web3CosmosSignMessageResponse(
      {required List<int> messageBytes, required List<int> signature})
      : messageBytes = messageBytes.asImmutableBytes,
        signature = signature.asImmutableBytes;
  factory Web3CosmosSignMessageResponse.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.runtimeTag);

    return Web3CosmosSignMessageResponse(
        messageBytes: values.rawValueAt(0), signature: values.rawValueAt(1));
  }

  Map<String, dynamic> toWalletConnectJson() {
    return {
      "messageBytes": StringUtils.decode(messageBytes, encoding: StringEncoding.base64),
      "signature": StringUtils.decode(signature, encoding: StringEncoding.base64)
    };
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems =>
      [CborBytesValue(messageBytes), CborBytesValue(signature)];
}

class Web3CosmosSignMessage
    extends Web3CosmosRequestParam<Web3CosmosSignMessageResponse> {
  final String challeng;
  final String? content;
  Web3CosmosSignMessage._({
    required this.accessAccount,
    required this.challeng,
    required this.content,
  });
  factory Web3CosmosSignMessage({
    required Web3CosmosChainAccount account,
    required String challeng,
    String? content,
  }) {
    return Web3CosmosSignMessage._(
        accessAccount: account, challeng: challeng, content: content);
  }

  factory Web3CosmosSignMessage.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3MessageTypes.walletRequest.tag);

    return Web3CosmosSignMessage(
        account:
            Web3CosmosChainAccount.deserialize(object: values.objectAt<CborTagValue>(1)),
        challeng: values.rawValueAt(2),
        content: values.rawValueAt(3));
  }

  @override
  Web3CosmosRequestMethods get method => Web3CosmosRequestMethods.signMessage;

  final Web3CosmosChainAccount accessAccount;
  @override
  Future<IResult<Web3CosmosRequest<Web3CosmosSignMessageResponse, Web3CosmosSignMessage>>>
      toRequest(
          {required Web3RequestInformation request,
          required Web3RequestAuthentication authenticated,
          required WEB3REQUESTNETWORKCONTROLLER<ICosmosAddress, CosmosChain,
                  Web3CosmosChainAccount>
              chainController}) async {
    final chain = await super.findRequestChain(
        request: request, authenticated: authenticated, chainController: chainController);
    return chain.map((chain) =>
        Web3CosmosRequest<Web3CosmosSignMessageResponse, Web3CosmosSignMessage>(
          params: this,
          authenticated: authenticated,
          chain: chain.$1,
          info: request,
          accounts: chain.$2,
        ));
  }

  @override
  Object? toJsWalletResponse(Web3CosmosSignMessageResponse response) {
    return response.toCbor().encode();
  }

  @override
  List<Web3CosmosChainAccount> get requiredAccounts => [accessAccount];

  @override
  List<CborObject?> get serializationItems =>
      [method.methodInfos, accessAccount.toCbor(), challeng.toCbor(), content?.toCbor()];
}
