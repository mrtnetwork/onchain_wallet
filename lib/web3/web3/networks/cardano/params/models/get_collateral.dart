import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain/ada/src/models/transaction/input/models/transaction_unspent_output.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/params/core/request.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/permission/models/account.dart';

class Web3ADAGetCollateral extends Web3ADARequestParam<List<TransactionUnspentOutput>> {
  final List<Web3ADAChainAccount> accounts;
  final BigInt? coin;
  Web3ADAGetCollateral._(
      {required List<Web3ADAChainAccount> accounts, required this.coin})
      : accounts = accounts.immutable;
  factory Web3ADAGetCollateral(
      {required List<Web3ADAChainAccount> accounts, BigInt? coin}) {
    if (accounts.isEmpty || accounts.map((e) => e.id).toSet().length != 1) {
      throw Web3RequestExceptionConst.invalidRequest;
    }
    return Web3ADAGetCollateral._(accounts: accounts, coin: coin);
  }

  factory Web3ADAGetCollateral.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: Web3MessageTypes.walletRequest.tag,
    );
    return Web3ADAGetCollateral(
        accounts: values
            .listAt<CborTagValue>(1)
            .map((e) => Web3ADAChainAccount.deserialize(object: e))
            .toList(),
        coin: values.rawValueAt(2));
  }

  @override
  Web3ADARequestMethods get method => Web3ADARequestMethods.getCollateral;

  @override
  Future<IResult<Web3ADARequest<List<TransactionUnspentOutput>, Web3ADAGetCollateral>>>
      toRequest(
          {required Web3RequestInformation request,
          required Web3RequestAuthentication authenticated,
          required WEB3REQUESTNETWORKCONTROLLER<ICardanoAddress, ADAChain,
                  Web3ADAChainAccount>
              chainController}) async {
    final chain = await super.findRequestChain(
        request: request, authenticated: authenticated, chainController: chainController);
    return chain.map((chain) =>
        Web3ADARequest<List<TransactionUnspentOutput>, Web3ADAGetCollateral>(
            params: this,
            authenticated: authenticated,
            chain: chain.$1,
            info: request,
            accounts: chain.$2));
  }

  @override
  List<Web3ADAChainAccount> get requiredAccounts => accounts;

  @override
  Object? toJsWalletResponse(List<TransactionUnspentOutput> response) {
    return response.map((e) => e.toCbor().encode()).toList();
  }

  @override
  List<CborObject?> get serializationItems => [
        method.methodInfos,
        CborListValue.definite(accounts.map((e) => e.toCbor()).toList()),
        coin?.toCbor()
      ];
}
