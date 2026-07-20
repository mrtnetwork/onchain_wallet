import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/zcash/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/zcash/params/core/request.dart';
import 'package:on_chain_wallet/web3/web3/networks/zcash/permission/models/account.dart';

class Web3ZcashSignMessageResponse with AppSerialization {
  final List<int> signature;
  final List<int> digest;
  Web3ZcashSignMessageResponse({required List<int> signature, required List<int> digest})
      : signature = signature.asImmutableBytes,
        digest = digest.asImmutableBytes;
  factory Web3ZcashSignMessageResponse.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.runtimeTag);
    return Web3ZcashSignMessageResponse(
        signature: values.rawValueAt(0), digest: values.rawValueAt(1));
  }

  Map<String, dynamic> toWalletConnectJson() {
    return {
      "signature": BytesUtils.toHexString(signature),
      "digest": BytesUtils.toHexString(digest)
    };
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems =>
      [CborBytesValue(signature), CborBytesValue(digest)];
}

class Web3ZcashSignMessage extends Web3ZcashRequestParam<Web3ZcashSignMessageResponse> {
  final Web3ZcashChainAccount accessAccount;
  final String challeng;
  final String? content;

  Web3ZcashSignMessage(
      {required this.accessAccount, required this.challeng, this.content});

  factory Web3ZcashSignMessage.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: Web3MessageTypes.walletRequest.tag,
    );
    final List<int> challeng = values.rawValueAt(2);
    return Web3ZcashSignMessage(
        accessAccount:
            Web3ZcashChainAccount.deserialize(object: values.objectAt<CborTagValue>(1)),
        challeng: BytesUtils.toHexString(challeng, prefix: "0x"),
        content: values.rawValueAt(3));
  }

  @override
  Web3ZcashRequestMethods get method => Web3ZcashRequestMethods.signMessage;

  List<int> chalengBytes() {
    return BytesUtils.fromHexString(challeng);
  }

  @override
  Future<IResult<Web3ZcashRequest<Web3ZcashSignMessageResponse, Web3ZcashSignMessage>>>
      toRequest(
          {required Web3RequestInformation request,
          required Web3RequestAuthentication authenticated,
          required WEB3REQUESTNETWORKCONTROLLER<IZcashAddress, ZcashChain,
                  Web3ZcashChainAccount>
              chainController}) async {
    final chain = await super.findRequestChain(
        request: request, authenticated: authenticated, chainController: chainController);
    return chain.map(
        (chain) => Web3ZcashRequest<Web3ZcashSignMessageResponse, Web3ZcashSignMessage>(
              params: this,
              authenticated: authenticated,
              chain: chain.$1,
              info: request,
              accounts: chain.$2,
            ));
  }

  @override
  List<Web3ZcashChainAccount> get requiredAccounts => [accessAccount];

  @override
  Object? toJsWalletResponse(Web3ZcashSignMessageResponse response) {
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
