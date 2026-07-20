import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin/params/models/transaction.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin_cash/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin_cash/params/core/request.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin_cash/permission/models/account.dart';

class Web3BitcoinCashSignTransaction extends Web3BitcoinCashRequestParam<String>
    implements BaseWeb3BitcoinSignTransaction<Web3BitcoinCashChainAccount> {
  @override
  final List<Web3BitcoinCashChainAccount> accounts;
  @override
  final Web3BitcoinCashChainAccount accessAccount;
  @override
  final Psbt psbt;

  Web3BitcoinCashSignTransaction._({
    required this.accounts,
    required this.psbt,
    required this.accessAccount,
  });
  factory Web3BitcoinCashSignTransaction(
      {required List<Web3BitcoinCashChainAccount> accounts, required Psbt psbt}) {
    final networks = accounts.map((e) => e.id).toSet();
    if (networks.length != 1) {
      throw Web3RequestExceptionConst.invalidRequest;
    }
    return Web3BitcoinCashSignTransaction._(
        accounts: accounts, psbt: psbt, accessAccount: accounts[0]);
  }

  factory Web3BitcoinCashSignTransaction.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3MessageTypes.walletRequest.tag);
    return Web3BitcoinCashSignTransaction(
        accounts: values
            .listAt<CborTagValue>(1)
            .map((e) => Web3BitcoinCashChainAccount.deserialize(object: e))
            .toList(),
        psbt: Psbt.deserialize(values.rawValueAt(2)));
  }

  @override
  Web3BitcoinCashRequestMethods get method =>
      Web3BitcoinCashRequestMethods.signTransaction;

  @override
  Future<IResult<Web3BitcoinCashRequest<String, Web3BitcoinCashSignTransaction>>>
      toRequest(
          {required Web3RequestInformation request,
          required Web3RequestAuthentication authenticated,
          required WEB3REQUESTNETWORKCONTROLLER<IBitcoinAddress, BitcoinChain,
                  Web3BitcoinCashChainAccount>
              chainController}) async {
    final chain = await super.findRequestChain(
        request: request, authenticated: authenticated, chainController: chainController);
    return chain
        .map((chain) => Web3BitcoinCashRequest<String, Web3BitcoinCashSignTransaction>(
              params: this,
              authenticated: authenticated,
              chain: chain.$1,
              info: request,
              accounts: chain.$2,
            ));
  }

  @override
  List<Web3BitcoinCashChainAccount> get requiredAccounts => accounts;

  @override
  List<CborObject?> get serializationItems => [
        method.methodInfos,
        AppSerialization.listFromObjects(accounts.map((e) => e.toCbor()).toList()),
        CborBytesValue(psbt.serialize())
      ];
}
