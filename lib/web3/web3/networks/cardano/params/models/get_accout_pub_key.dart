import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/params/core/request.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/permission/models/account.dart';

class Web3ADAGetAccountPub extends Web3ADARequestParam<List<int>> {
  final Web3ADAChainAccount accessAccount;

  Web3ADAGetAccountPub({required this.accessAccount});

  factory Web3ADAGetAccountPub.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: Web3MessageTypes.walletRequest.tag,
    );
    return Web3ADAGetAccountPub(
        accessAccount:
            Web3ADAChainAccount.deserialize(object: values.objectAt<CborTagValue>(1)));
  }

  @override
  Web3ADARequestMethods get method => Web3ADARequestMethods.getAccountPub;

  @override
  Future<IResult<Web3ADARequest<List<int>, Web3ADAGetAccountPub>>> toRequest(
      {required Web3RequestInformation request,
      required Web3RequestAuthentication authenticated,
      required WEB3REQUESTNETWORKCONTROLLER<ICardanoAddress, ADAChain,
              Web3ADAChainAccount>
          chainController}) async {
    final chain = await super.findRequestChain(
        request: request, authenticated: authenticated, chainController: chainController);
    return chain.map((chain) => Web3ADARequest<List<int>, Web3ADAGetAccountPub>(
        params: this,
        authenticated: authenticated,
        chain: chain.$1,
        info: request,
        accounts: chain.$2));
  }

  @override
  List<Web3ADAChainAccount> get requiredAccounts => [accessAccount];

  @override
  Object? toJsWalletResponse(List<int> response) {
    return response;
  }

  @override
  List<CborObject?> get serializationItems =>
      [method.methodInfos, accessAccount.toCbor()];
}
