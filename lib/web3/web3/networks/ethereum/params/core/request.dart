import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/ethereum/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/ethereum/params/requests.dart';
import 'package:on_chain_wallet/web3/web3/networks/ethereum/permission/permission.dart';

import 'package:on_chain/ethereum/src/address/evm_address.dart';

abstract class Web3EthereumRequestParam<RESPONSE> extends Web3RequestParams<RESPONSE,
    ETHAddress, IEthereumAddress, EthereumChain, Web3EthereumChainAccount> {
  @override
  abstract final Web3EthereumRequestMethods method;

  Web3EthereumRequestParam();
  @override
  List<Web3EthereumChainAccount> get requiredAccounts => [];

  factory Web3EthereumRequestParam.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3MessageTypes.walletRequest.tag);
    final method = Web3NetworkRequestMethods.findMethod(values.objectAt(0)).method;
    final Web3EthereumRequestParam param;
    switch (method) {
      case Web3EthereumRequestMethods.addEthereumChain:
        param = Web3EthereumAddNewChain.deserialize(bytes: bytes, object: object);
        break;
      case Web3EthereumRequestMethods.ethSign:
      case Web3EthereumRequestMethods.persoalSign:
        param = Web3EthreumPersonalSign.deserialize(bytes: bytes, object: object);
        break;
      case Web3EthereumRequestMethods.sendTransaction:
        param = Web3EthreumSendTransaction.deserialize(bytes: bytes, object: object);
        break;
      case Web3EthereumRequestMethods.typedData:
        param = Web3EthreumTypdedData.deserialize(bytes: bytes, object: object);
        break;
      default:
        throw Web3RequestExceptionConst.methodDoesNotExist;
    }

    return param.cast<Web3EthereumRequestParam<RESPONSE>>();
  }
}

class Web3EthereumRequest<RESPONSE, PARAMS extends Web3EthereumRequestParam<RESPONSE>>
    extends Web3NetworkRequest<RESPONSE, ETHAddress, IEthereumAddress, EthereumChain,
        Web3EthereumChainAccount, PARAMS> {
  Web3EthereumRequest(
      {required super.params,
      required super.info,
      required super.authenticated,
      required super.chain,
      required super.accounts});
  Web3EthereumRequest<R, P> cast<R, P extends Web3EthereumRequestParam<R>>() {
    return this as Web3EthereumRequest<R, P>;
  }
}
