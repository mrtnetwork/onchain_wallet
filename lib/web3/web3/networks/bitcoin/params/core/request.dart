import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin/params/models/send_transaction.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin/params/models/sign_message.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin/params/models/transaction.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin/permission/models/account.dart';

abstract class BaseWeb3BitcoinRequestParam<RESPONSE,
        WEB3CHAINACCOUNT extends Web3BitcoinChainAccount>
    extends Web3RequestParams<RESPONSE, BitcoinNetworkAddress, IBitcoinAddress,
        BitcoinChain, WEB3CHAINACCOUNT> {}

abstract class Web3BitcoinRequestParam<RESPONSE>
    extends BaseWeb3BitcoinRequestParam<RESPONSE, Web3BitcoinChainAccount> {
  @override
  abstract final Web3BitcoinRequestMethods method;

  Web3BitcoinRequestParam();

  factory Web3BitcoinRequestParam.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3MessageTypes.walletRequest.tag);
    final method = Web3NetworkRequestMethods.findMethod(values.objectAt(0)).method;
    final Web3BitcoinRequestParam param;
    switch (method) {
      case Web3BitcoinRequestMethods.signTransaction:
        param = Web3BitcoinSignTransaction.deserialize(bytes: bytes, object: object);
        break;
      case Web3BitcoinRequestMethods.signPersonalMessage:
        param = Web3BitcoinSignMessage.deserialize(bytes: bytes, object: object);
        break;
      case Web3BitcoinRequestMethods.sendTransaction:
        param = Web3BitcoinSendTransaction.deserialize(bytes: bytes, object: object);
        break;

      default:
        throw Web3RequestExceptionConst.methodDoesNotExist;
    }

    return param.cast<Web3BitcoinRequestParam<RESPONSE>>();
  }
}

abstract class BaseWeb3BitcoinRequest<
        RESPONSE,
        // ADDRESS extends IBitcoinAddress,
        WEB3CHAINACCOUNT extends Web3BitcoinChainAccount,
        PARAMS extends BaseWeb3BitcoinRequestParam<RESPONSE, WEB3CHAINACCOUNT>>
    extends Web3NetworkRequest<RESPONSE, BitcoinNetworkAddress, IBitcoinAddress,
        BitcoinChain, WEB3CHAINACCOUNT, PARAMS> {
  BaseWeb3BitcoinRequest(
      {required super.params,
      required super.info,
      required super.authenticated,
      required super.chain,
      required super.accounts});

  BaseWeb3BitcoinRequest<R, Web3BitcoinChainAccount, P>
      cast<R, P extends BaseWeb3BitcoinRequestParam<R, Web3BitcoinChainAccount>>() {
    return this as BaseWeb3BitcoinRequest<R, Web3BitcoinChainAccount, P>;
  }
}

class Web3BitcoinRequest<RESPONSE, PARAMS extends Web3BitcoinRequestParam<RESPONSE>>
    extends BaseWeb3BitcoinRequest<RESPONSE, Web3BitcoinChainAccount, PARAMS> {
  Web3BitcoinRequest(
      {required super.params,
      required super.info,
      required super.authenticated,
      required super.chain,
      required super.accounts});

  // Web3BitcoinRequest<R, P> cast<R, P extends Web3BitcoinRequestParam<R>>() {
  //   return this as Web3BitcoinRequest<R, P>;
  // }
}
