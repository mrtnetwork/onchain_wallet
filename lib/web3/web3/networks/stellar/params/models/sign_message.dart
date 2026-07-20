import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/stellar/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/stellar/params/core/request.dart';
import 'package:on_chain_wallet/web3/web3/networks/stellar/permission/models/account.dart';

class Web3StellarSignMessageResponse with AppSerialization {
  final List<int> signature;
  Web3StellarSignMessageResponse({required List<int> signature})
      : signature = signature.asImmutableBytes;
  factory Web3StellarSignMessageResponse.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.runtimeTag);
    return Web3StellarSignMessageResponse(signature: values.rawValueAt(0));
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

class Web3StellarSignMessage
    extends Web3StellarRequestParam<Web3StellarSignMessageResponse> {
  final Web3StellarChainAccount accessAccount;
  final String challeng;
  final String? content;

  Web3StellarSignMessage(
      {required this.accessAccount, required this.challeng, this.content});

  factory Web3StellarSignMessage.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: Web3MessageTypes.walletRequest.tag,
    );
    final List<int> challeng = values.rawValueAt(2);
    return Web3StellarSignMessage(
        accessAccount:
            Web3StellarChainAccount.deserialize(object: values.objectAt<CborTagValue>(1)),
        challeng: BytesUtils.toHexString(challeng, prefix: "0x"),
        content: values.rawValueAt(3));
  }

  @override
  Web3StellarRequestMethods get method => Web3StellarRequestMethods.signMessage;

  List<int> chalengBytes() {
    return BytesUtils.fromHexString(challeng);
  }

  @override
  Future<
          IResult<
              Web3StellarRequest<Web3StellarSignMessageResponse, Web3StellarSignMessage>>>
      toRequest(
          {required Web3RequestInformation request,
          required Web3RequestAuthentication authenticated,
          required WEB3REQUESTNETWORKCONTROLLER<IStellarAddress, StellarChain,
                  Web3StellarChainAccount>
              chainController}) async {
    final chain = await super.findRequestChain(
        request: request, authenticated: authenticated, chainController: chainController);
    return chain.map((chain) =>
        Web3StellarRequest<Web3StellarSignMessageResponse, Web3StellarSignMessage>(
          params: this,
          authenticated: authenticated,
          chain: chain.$1,
          info: request,
          accounts: chain.$2,
        ));
  }

  @override
  List<Web3StellarChainAccount> get requiredAccounts => [accessAccount];

  @override
  Object? toJsWalletResponse(Web3StellarSignMessageResponse response) {
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
