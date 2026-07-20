import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/ripple/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/ripple/params/core/request.dart';
import 'package:on_chain_wallet/web3/web3/networks/ripple/permission/models/account.dart';

class Web3XRPSignMessageResponse with AppSerialization {
  final List<int> signature;
  final List<int> publicKey;
  Web3XRPSignMessageResponse({required List<int> signature, required List<int> publicKey})
      : signature = signature.asImmutableBytes,
        publicKey = publicKey.asImmutableBytes;
  factory Web3XRPSignMessageResponse.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.runtimeTag);
    return Web3XRPSignMessageResponse(
        signature: values.rawValueAt(0), publicKey: values.rawValueAt(1));
  }

  Map<String, dynamic> toWalletConnectJson() {
    return {
      "signature": BytesUtils.toHexString(signature, lowerCase: false),
      "public_key": BytesUtils.toHexString(publicKey, lowerCase: false),
    };
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems =>
      [CborBytesValue(signature), CborBytesValue(publicKey)];
}

class Web3XRPSignMessage extends Web3XRPRequestParam<Web3XRPSignMessageResponse> {
  final Web3XRPChainAccount accessAccount;
  final String challeng;
  final String? content;

  Web3XRPSignMessage({required this.accessAccount, required this.challeng, this.content});

  factory Web3XRPSignMessage.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: Web3MessageTypes.walletRequest.tag,
    );
    final List<int> challeng = values.rawValueAt(2);
    return Web3XRPSignMessage(
        accessAccount:
            Web3XRPChainAccount.deserialize(object: values.objectAt<CborTagValue>(1)),
        challeng: BytesUtils.toHexString(challeng, prefix: "0x"),
        content: values.rawValueAt(3));
  }

  @override
  Web3XRPRequestMethods get method => Web3XRPRequestMethods.signMessage;

  List<int> chalengBytes() {
    return BytesUtils.fromHexString(challeng);
  }

  @override
  Future<IResult<Web3XRPRequest<Web3XRPSignMessageResponse, Web3XRPSignMessage>>>
      toRequest(
          {required Web3RequestInformation request,
          required Web3RequestAuthentication authenticated,
          required WEB3REQUESTNETWORKCONTROLLER<IXRPAddress, XRPChain,
                  Web3XRPChainAccount>
              chainController}) async {
    final chain = await super.findRequestChain(
        request: request, authenticated: authenticated, chainController: chainController);
    return chain
        .map((chain) => Web3XRPRequest<Web3XRPSignMessageResponse, Web3XRPSignMessage>(
              params: this,
              authenticated: authenticated,
              chain: chain.$1,
              info: request,
              accounts: chain.$2,
            ));
  }

  @override
  List<Web3XRPChainAccount> get requiredAccounts => [accessAccount];

  @override
  Object? toJsWalletResponse(Web3XRPSignMessageResponse response) {
    return response.toCbor().encode();
  }

  @override
  List<CborObject?> get serializationItems => [
        method.methodInfos,
        accessAccount.toCbor(),
        CborBytesValue(BytesUtils.fromHexString(challeng)),
        content?.toCbor()
      ];
}
