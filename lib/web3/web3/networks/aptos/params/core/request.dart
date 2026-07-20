import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/web3/web3/networks/aptos/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/aptos/params/models/sign_message.dart';
import 'package:on_chain_wallet/web3/web3/networks/aptos/params/models/transaction.dart';
import 'package:on_chain_wallet/web3/web3/networks/aptos/permission/permission.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain/aptos/aptos.dart';

abstract class Web3AptosRequestParam<RESPONSE> extends Web3RequestParams<RESPONSE,
    AptosAddress, IAptosAddress, AptosChain, Web3AptosChainAccount> {
  @override
  abstract final Web3AptosRequestMethods method;

  @override
  List<Web3AptosChainAccount> get requiredAccounts => [];

  Web3AptosRequestParam();

  factory Web3AptosRequestParam.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3MessageTypes.walletRequest.tag);
    final method =
        Web3NetworkRequestMethods.findMethod<Web3AptosRequestMethods>(values.objectAt(0))
            .method;
    final Web3AptosRequestParam param;
    switch (method) {
      case Web3AptosRequestMethods.signTransaction:
        param = Web3AptosSendTransaction.deserialize(bytes: bytes, object: object);
        break;
      case Web3AptosRequestMethods.signMessage:
        param = Web3AptosSignMessage.deserialize(bytes: bytes, object: object);
        break;
      default:
        throw Web3RequestExceptionConst.methodDoesNotExist;
    }

    return param.cast<Web3AptosRequestParam<RESPONSE>>();
  }
}

class Web3AptosRequest<RESPONSE, PARAMS extends Web3AptosRequestParam<RESPONSE>>
    extends Web3NetworkRequest<RESPONSE, AptosAddress, IAptosAddress, AptosChain,
        Web3AptosChainAccount, PARAMS> {
  Web3AptosRequest(
      {required super.params,
      required super.info,
      required super.authenticated,
      required super.chain,
      required super.accounts});

  Web3AptosRequest<R, P> cast<R, P extends Web3AptosRequestParam<R>>() {
    return this as Web3AptosRequest<R, P>;
  }
}
