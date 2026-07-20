import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/web3/web3/networks/ripple/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/ripple/params/models/sign_message.dart';
import 'package:on_chain_wallet/web3/web3/networks/ripple/params/models/transaction.dart';
import 'package:on_chain_wallet/web3/web3/networks/ripple/permission/models/account.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:xrpl_dart/xrpl_dart.dart';

abstract class Web3XRPRequestParam<RESPONSE> extends Web3RequestParams<RESPONSE,
    XRPBaseAddress, IXRPAddress, XRPChain, Web3XRPChainAccount> {
  @override
  abstract final Web3XRPRequestMethods method;

  Web3XRPRequestParam();

  factory Web3XRPRequestParam.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3MessageTypes.walletRequest.tag);
    final method = Web3NetworkRequestMethods.findMethod(values.objectAt(0)).method;
    final Web3XRPRequestParam param;
    switch (method) {
      case Web3XRPRequestMethods.signTransaction:
      case Web3XRPRequestMethods.sendTransaction:
        param = Web3XRPSendTransaction.deserialize(bytes: bytes, object: object);
      case Web3XRPRequestMethods.signMessage:
        param = Web3XRPSignMessage.deserialize(bytes: bytes, object: object);
      default:
        throw Web3RequestExceptionConst.methodDoesNotExist;
    }
    return param.cast<Web3XRPRequestParam<RESPONSE>>();
  }
}

class Web3XRPRequest<RESPONSE, PARAMS extends Web3XRPRequestParam<RESPONSE>>
    extends Web3NetworkRequest<RESPONSE, XRPBaseAddress, IXRPAddress, XRPChain,
        Web3XRPChainAccount, PARAMS> {
  Web3XRPRequest(
      {required super.params,
      required super.info,
      required super.authenticated,
      required super.chain,
      required super.accounts});

  Web3XRPRequest<R, P> cast<R, P extends Web3XRPRequestParam<R>>() {
    return this as Web3XRPRequest<R, P>;
  }
}
