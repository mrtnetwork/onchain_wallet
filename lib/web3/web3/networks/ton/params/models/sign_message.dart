import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/ton/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/ton/params/core/request.dart';
import 'package:on_chain_wallet/web3/web3/networks/ton/permission/models/account.dart';

class Web3TonSignMessageResponse with AppSerialization {
  final List<int> signature;
  Web3TonSignMessageResponse({required List<int> signature})
      : signature = signature.asImmutableBytes;
  factory Web3TonSignMessageResponse.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.runtimeTag);
    return Web3TonSignMessageResponse(signature: values.rawValueAt(0));
  }

  Map<String, dynamic> toWalletConnectJson() {
    return {"signature": StringUtils.decode(signature, encoding: StringEncoding.base64)};
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [signature.toCborBytes()];
}

class Web3TonSignMessage extends Web3TonRequestParam<Web3TonSignMessageResponse> {
  final Web3TonChainAccount accessAccount;
  final String challeng;
  final String? content;

  Web3TonSignMessage({required this.accessAccount, required this.challeng, this.content});

  factory Web3TonSignMessage.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: Web3MessageTypes.walletRequest.tag,
    );
    final List<int> challeng = values.rawValueAt(2);
    return Web3TonSignMessage(
        accessAccount:
            Web3TonChainAccount.deserialize(object: values.objectAt<CborTagValue>(1)),
        challeng: BytesUtils.toHexString(challeng, prefix: "0x"),
        content: values.rawValueAt(3));
  }

  @override
  Web3TonRequestMethods get method => Web3TonRequestMethods.signMessage;

  List<int> chalengBytes() {
    return BytesUtils.fromHexString(challeng);
  }

  @override
  Future<IResult<Web3TonRequest<Web3TonSignMessageResponse, Web3TonSignMessage>>>
      toRequest(
          {required Web3RequestInformation request,
          required Web3RequestAuthentication authenticated,
          required WEB3REQUESTNETWORKCONTROLLER<ITonAddress, TonChain,
                  Web3TonChainAccount>
              chainController}) async {
    final chain = await super.findRequestChain(
        request: request, authenticated: authenticated, chainController: chainController);
    return chain
        .map((chain) => Web3TonRequest<Web3TonSignMessageResponse, Web3TonSignMessage>(
              params: this,
              authenticated: authenticated,
              chain: chain.$1,
              info: request,
              accounts: chain.$2,
            ));
  }

  @override
  List<Web3TonChainAccount> get requiredAccounts => [accessAccount];

  @override
  Object? toJsWalletResponse(Web3TonSignMessageResponse response) {
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
