import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/ton/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/ton/params/params.dart';
import 'package:on_chain_wallet/web3/web3/networks/ton/permission/models/account.dart';
import 'package:ton_dart/ton_dart.dart';

abstract class Web3TonRequestParam<RESPONSE> extends Web3RequestParams<RESPONSE,
    TonAddress, ITonAddress, TonChain, Web3TonChainAccount> {
  @override
  abstract final Web3TonRequestMethods method;

  Web3TonRequestParam();

  factory Web3TonRequestParam.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3MessageTypes.walletRequest.tag);
    final method = Web3NetworkRequestMethods.findMethod(values.objectAt(0)).method;
    final Web3TonRequestParam param;
    switch (method) {
      case Web3TonRequestMethods.sendTransaction:
      case Web3TonRequestMethods.signTransaction:
        param = Web3TonSendTransaction.deserialize(bytes: bytes, object: object);
      case Web3TonRequestMethods.signMessage:
        param = Web3TonSignMessage.deserialize(bytes: bytes, object: object);
      default:
        throw Web3RequestExceptionConst.methodDoesNotExist;
    }
    return param.cast<Web3TonRequestParam<RESPONSE>>();
  }
}

class Web3TonRequest<RESPONSE, PARAMS extends Web3TonRequestParam<RESPONSE>>
    extends Web3NetworkRequest<RESPONSE, TonAddress, ITonAddress, TonChain,
        Web3TonChainAccount, PARAMS> {
  Web3TonRequest(
      {required super.params,
      required super.info,
      required super.authenticated,
      required super.chain,
      required super.accounts});

  Web3TonRequest<R, P> cast<R, P extends Web3TonRequestParam<R>>() {
    return this as Web3TonRequest<R, P>;
  }
}
