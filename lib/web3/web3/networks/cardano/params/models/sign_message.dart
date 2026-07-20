import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';

import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/params/core/request.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/permission/models/account.dart';

class Web3ADASignMessageResponse with AppSerialization {
  final List<int> signature;
  Web3ADASignMessageResponse({required List<int> signature})
      : signature = signature.asImmutableBytes;
  factory Web3ADASignMessageResponse.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.runtimeTag);
    return Web3ADASignMessageResponse(signature: values.rawValueAt(0));
  }

  Map<String, dynamic> toWalletConnectJson() {
    return {"signature": BytesUtils.toHexString(signature, lowerCase: false)};
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.runtimeTag;

  @override
  List<CborObject?> get serializationItems => [CborBytesValue(signature)];
}

class Web3ADASignMessage extends Web3ADARequestParam<Web3ADASignMessageResponse> {
  final Web3ADAChainAccount accessAccount;
  final String challeng;
  final String? content;

  Web3ADASignMessage({required this.accessAccount, required this.challeng, this.content});

  factory Web3ADASignMessage.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: Web3MessageTypes.walletRequest.tag,
    );
    final List<int> challeng = values.rawValueAt(2);
    return Web3ADASignMessage(
        accessAccount:
            Web3ADAChainAccount.deserialize(object: values.objectAt<CborTagValue>(1)),
        challeng: BytesUtils.toHexString(challeng, prefix: "0x"),
        content: values.rawValueAt(3));
  }

  @override
  Web3ADARequestMethods get method => Web3ADARequestMethods.signMessage;

  List<int> chalengBytes() {
    return BytesUtils.fromHexString(challeng);
  }

  @override
  Future<IResult<Web3ADARequest<Web3ADASignMessageResponse, Web3ADASignMessage>>>
      toRequest(
          {required Web3RequestInformation request,
          required Web3RequestAuthentication authenticated,
          required WEB3REQUESTNETWORKCONTROLLER<ICardanoAddress, ADAChain,
                  Web3ADAChainAccount>
              chainController}) async {
    final chain = await super.findRequestChain(
        request: request, authenticated: authenticated, chainController: chainController);
    return chain.map((chain) =>
        Web3ADARequest<Web3ADASignMessageResponse, Web3ADASignMessage>(
            params: this,
            authenticated: authenticated,
            chain: chain.$1,
            info: request,
            accounts: chain.$2));
  }

  @override
  List<Web3ADAChainAccount> get requiredAccounts => [accessAccount];

  @override
  Object? toJsWalletResponse(Web3ADASignMessageResponse response) {
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
