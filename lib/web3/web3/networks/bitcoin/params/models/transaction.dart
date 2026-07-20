import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin/params/core/request.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin/permission/models/account.dart';

abstract class BaseWeb3BitcoinSignTransaction<
        WEB3CHAINACCOUNT extends Web3BitcoinChainAccount>
    extends BaseWeb3BitcoinRequestParam<String, WEB3CHAINACCOUNT> {
  abstract final List<WEB3CHAINACCOUNT> accounts;
  abstract final WEB3CHAINACCOUNT accessAccount;
  abstract final Psbt psbt;
}

class Web3BitcoinSignTransaction extends Web3BitcoinRequestParam<String>
    implements BaseWeb3BitcoinSignTransaction<Web3BitcoinChainAccount> {
  @override
  final List<Web3BitcoinChainAccount> accounts;
  @override
  final Web3BitcoinChainAccount accessAccount;
  @override
  final Psbt psbt;

  Web3BitcoinSignTransaction._({
    required this.accounts,
    required this.psbt,
    required this.accessAccount,
  });
  factory Web3BitcoinSignTransaction(
      {required List<Web3BitcoinChainAccount> accounts, required Psbt psbt}) {
    final networks = accounts.map((e) => e.id).toSet();
    if (networks.length != 1) {
      throw Web3RequestExceptionConst.invalidRequest;
    }
    return Web3BitcoinSignTransaction._(
        accounts: accounts, psbt: psbt, accessAccount: accounts[0]);
  }

  factory Web3BitcoinSignTransaction.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3MessageTypes.walletRequest.tag);
    return Web3BitcoinSignTransaction(
        accounts: values
            .listAt<CborTagValue>(1)
            .map((e) => Web3BitcoinChainAccount.deserialize(object: e))
            .toList(),
        psbt: Psbt.deserialize(values.rawValueAt(2)));
  }

  @override
  Web3BitcoinRequestMethods get method => Web3BitcoinRequestMethods.signTransaction;

  @override
  Future<IResult<Web3BitcoinRequest<String, Web3BitcoinSignTransaction>>> toRequest(
      {required Web3RequestInformation request,
      required Web3RequestAuthentication authenticated,
      required WEB3REQUESTNETWORKCONTROLLER<IBitcoinAddress, BitcoinChain,
              Web3BitcoinChainAccount>
          chainController}) async {
    final chain = await super.findRequestChain(
        request: request, authenticated: authenticated, chainController: chainController);
    return chain.map((chain) => Web3BitcoinRequest<String, Web3BitcoinSignTransaction>(
          params: this,
          authenticated: authenticated,
          chain: chain.$1,
          info: request,
          accounts: chain.$2,
        ));
  }

  @override
  List<Web3BitcoinChainAccount> get requiredAccounts => accounts;

  @override
  List<CborObject?> get serializationItems => [
        method.methodInfos,
        AppSerialization.listFromObjects(accounts.map((e) => e.toCbor()).toList()),
        CborBytesValue(psbt.serialize())
      ];
}
