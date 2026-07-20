import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/tron/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/tron/params/core/request.dart';
import 'package:on_chain_wallet/web3/web3/networks/tron/permission/models/account.dart';

class Web3TronSignMessageV2 extends Web3TronRequestParam<String> {
  final Web3TronChainAccount accessAccount;
  final String challeng;
  final String? content;

  Web3TronSignMessageV2(
      {required this.accessAccount, required this.challeng, this.content});

  factory Web3TronSignMessageV2.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: Web3MessageTypes.walletRequest.tag,
    );
    final List<int> challeng = values.rawValueAt(2);
    return Web3TronSignMessageV2(
        accessAccount:
            Web3TronChainAccount.deserialize(object: values.objectAt<CborTagValue>(1)),
        challeng: BytesUtils.toHexString(challeng, prefix: "0x"),
        content: values.rawValueAt(3));
  }

  @override
  Web3TronRequestMethods get method => Web3TronRequestMethods.signMessageV2;

  List<int> chalengBytes() {
    return BytesUtils.fromHexString(challeng);
  }

  @override
  Future<IResult<Web3TronRequest<String, Web3TronSignMessageV2>>> toRequest(
      {required Web3RequestInformation request,
      required Web3RequestAuthentication authenticated,
      required WEB3REQUESTNETWORKCONTROLLER<ITronAddress, TronChain, Web3TronChainAccount>
          chainController}) async {
    final chain = await super.findRequestChain(
        request: request, authenticated: authenticated, chainController: chainController);
    return chain.map((chain) => Web3TronRequest<String, Web3TronSignMessageV2>(
          params: this,
          authenticated: authenticated,
          chain: chain.$1,
          info: request,
          accounts: chain.$2,
        ));
  }

  @override
  List<Web3TronChainAccount> get requiredAccounts => [accessAccount];

  @override
  List<CborObject?> get serializationItems => [
        method.methodInfos,
        accessAccount.toCbor(),
        CborBytesValue(BytesUtils.fromHexString(challeng)),
        content?.toCbor()
      ];
}
