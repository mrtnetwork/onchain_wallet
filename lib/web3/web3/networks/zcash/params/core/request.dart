import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/zcash/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/zcash/params/models/sign_message.dart';
import 'package:on_chain_wallet/web3/web3/networks/zcash/params/models/transaction.dart';
import 'package:on_chain_wallet/web3/web3/networks/zcash/permission/models/account.dart';
import 'package:zcash_dart/zcash.dart';

abstract class Web3ZcashRequestParam<RESPONSE> extends Web3RequestParams<RESPONSE,
    ZcashAddress, IZcashAddress, ZcashChain, Web3ZcashChainAccount> {
  @override
  abstract final Web3ZcashRequestMethods method;

  Web3ZcashRequestParam();

  factory Web3ZcashRequestParam.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3MessageTypes.walletRequest.tag);
    final method = Web3NetworkRequestMethods.findMethod(values.objectAt(0)).method;
    final Web3ZcashRequestParam param;
    switch (method) {
      case Web3ZcashRequestMethods.sendTransaction:
        param = Web3ZcashSendTransaction.deserialize(bytes: bytes, object: object);
      case Web3ZcashRequestMethods.signMessage:
        param = Web3ZcashSignMessage.deserialize(bytes: bytes, object: object);
      default:
        throw Web3RequestExceptionConst.methodDoesNotExist;
    }
    return param.cast<Web3ZcashRequestParam<RESPONSE>>();
  }
}

class Web3ZcashRequest<RESPONSE, PARAMS extends Web3ZcashRequestParam<RESPONSE>>
    extends Web3NetworkRequest<RESPONSE, ZcashAddress, IZcashAddress, ZcashChain,
        Web3ZcashChainAccount, PARAMS> {
  Web3ZcashRequest(
      {required super.params,
      required super.info,
      required super.authenticated,
      required super.chain,
      required super.accounts});

  Web3ZcashRequest<R, P> cast<R, P extends Web3ZcashRequestParam<R>>() {
    return this as Web3ZcashRequest<R, P>;
  }
}
