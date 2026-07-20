import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/stellar/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/stellar/params/models/sign_message.dart';
import 'package:on_chain_wallet/web3/web3/networks/stellar/params/models/transaction.dart';
import 'package:on_chain_wallet/web3/web3/networks/stellar/permission/permission.dart';
import 'package:stellar_dart/stellar_dart.dart';

abstract class Web3StellarRequestParam<RESPONSE> extends Web3RequestParams<RESPONSE,
    StellarAddress, IStellarAddress, StellarChain, Web3StellarChainAccount> {
  @override
  abstract final Web3StellarRequestMethods method;

  Web3StellarRequestParam();

  factory Web3StellarRequestParam.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3MessageTypes.walletRequest.tag);
    final method = Web3NetworkRequestMethods.findMethod(values.objectAt(0)).method;
    final Web3StellarRequestParam param;
    switch (method) {
      case Web3StellarRequestMethods.signTransaction:
      case Web3StellarRequestMethods.sendTransaction:
        param = Web3StellarSendTransaction.deserialize(bytes: bytes, object: object);
      case Web3StellarRequestMethods.signMessage:
        param = Web3StellarSignMessage.deserialize(bytes: bytes, object: object);
      default:
        throw Web3RequestExceptionConst.methodDoesNotExist;
    }

    return param.cast<Web3StellarRequestParam<RESPONSE>>();
  }
}

class Web3StellarRequest<RESPONSE, PARAMS extends Web3StellarRequestParam<RESPONSE>>
    extends Web3NetworkRequest<RESPONSE, StellarAddress, IStellarAddress, StellarChain,
        Web3StellarChainAccount, PARAMS> {
  Web3StellarRequest(
      {required super.params,
      required super.info,
      required super.authenticated,
      required super.chain,
      required super.accounts});

  Web3StellarRequest<R, P> cast<R, P extends Web3StellarRequestParam<R>>() {
    return this as Web3StellarRequest<R, P>;
  }
}
