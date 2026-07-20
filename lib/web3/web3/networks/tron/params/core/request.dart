import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/web3/web3/networks/tron/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/tron/params/models/sign_message_v2.dart';
import 'package:on_chain_wallet/web3/web3/networks/tron/params/models/transaction.dart';
import 'package:on_chain_wallet/web3/web3/networks/tron/permission/permission.dart';
import 'package:on_chain/on_chain.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';

abstract class Web3TronRequestParam<RESPONSE> extends Web3RequestParams<RESPONSE,
    TronAddress, ITronAddress, TronChain, Web3TronChainAccount> {
  @override
  abstract final Web3TronRequestMethods method;
  Web3TronRequestParam();

  @override
  List<Web3TronChainAccount> get requiredAccounts => [];

  factory Web3TronRequestParam.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3MessageTypes.walletRequest.tag);
    final method = Web3NetworkRequestMethods.findMethod(values.objectAt(0)).method;
    final Web3TronRequestParam param;
    switch (method) {
      case Web3TronRequestMethods.signTransaction:
        param = Web3TronSignTransaction.deserialize(bytes: bytes, object: object);
        break;
      case Web3TronRequestMethods.signMessageV2:
        param = Web3TronSignMessageV2.deserialize(bytes: bytes, object: object);
        break;
      default:
        throw Web3RequestExceptionConst.methodDoesNotExist;
    }

    return param.cast<Web3TronRequestParam<RESPONSE>>();
  }
}

class Web3TronRequest<RESPONSE, PARAMS extends Web3TronRequestParam<RESPONSE>>
    extends Web3NetworkRequest<RESPONSE, TronAddress, ITronAddress, TronChain,
        Web3TronChainAccount, PARAMS> {
  Web3TronRequest(
      {required super.params,
      required super.info,
      required super.authenticated,
      required super.chain,
      required super.accounts});

  Web3TronRequest<R, P> cast<R, P extends Web3TronRequestParam<R>>() {
    return this as Web3TronRequest<R, P>;
  }
}
