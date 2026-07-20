import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin/params/core/request.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin_cash/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin_cash/params/models/send_transaction.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin_cash/params/models/sign_message.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin_cash/params/models/transaction.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin_cash/permission/models/account.dart';

abstract class Web3BitcoinCashRequestParam<RESPONSE>
    extends BaseWeb3BitcoinRequestParam<RESPONSE, Web3BitcoinCashChainAccount> {
  @override
  abstract final Web3BitcoinCashRequestMethods method;

  Web3BitcoinCashRequestParam();

  factory Web3BitcoinCashRequestParam.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3MessageTypes.walletRequest.tag);
    final method = Web3NetworkRequestMethods.findMethod(values.objectAt(0)).method;
    final Web3BitcoinCashRequestParam param;
    switch (method) {
      case Web3BitcoinCashRequestMethods.signTransaction:
        param = Web3BitcoinCashSignTransaction.deserialize(bytes: bytes, object: object);
        break;
      case Web3BitcoinCashRequestMethods.signPersonalMessage:
        param = Web3BitcoinCashSignMessage.deserialize(bytes: bytes, object: object);
        break;
      case Web3BitcoinCashRequestMethods.sendTransaction:
        param = Web3BitcoinCashSendTransaction.deserialize(bytes: bytes, object: object);
        break;

      default:
        throw Web3RequestExceptionConst.methodDoesNotExist;
    }

    return param.cast<Web3BitcoinCashRequestParam<RESPONSE>>();
  }
}

class Web3BitcoinCashRequest<RESPONSE,
        PARAMS extends Web3BitcoinCashRequestParam<RESPONSE>>
    extends BaseWeb3BitcoinRequest<RESPONSE, Web3BitcoinCashChainAccount, PARAMS> {
  Web3BitcoinCashRequest(
      {required super.params,
      required super.info,
      required super.authenticated,
      required super.chain,
      required super.accounts});

  // Web3BitcoinCashRequest<R, P>
  //     cast<R, P extends Web3BitcoinCashRequestParam<R>>() {
  //   return this as Web3BitcoinCashRequest<R, P>;
  // }
}
