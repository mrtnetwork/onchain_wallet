import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/substrate/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/substrate/params/models/add_chain.dart';
import 'package:on_chain_wallet/web3/web3/networks/substrate/params/models/sign_message.dart';
import 'package:on_chain_wallet/web3/web3/networks/substrate/params/models/transaction.dart';
import 'package:on_chain_wallet/web3/web3/networks/substrate/permission/permission.dart';
import 'package:polkadot_dart/polkadot_dart.dart';

abstract class Web3SubstrateRequestParam<RESPONSE> extends Web3RequestParams<RESPONSE,
    BaseSubstrateAddress, ISubstrateAddress, SubstrateChain, Web3SubstrateChainAccount> {
  @override
  abstract final Web3SubstrateRequestMethods method;
  @override
  List<Web3SubstrateChainAccount> get requiredAccounts => [];
  Web3SubstrateRequestParam();

  factory Web3SubstrateRequestParam.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3MessageTypes.walletRequest.tag);
    final method = Web3NetworkRequestMethods.findMethod(values.objectAt(0)).method;
    final Web3SubstrateRequestParam param;
    switch (method) {
      case Web3SubstrateRequestMethods.signTransaction:
        param = Web3SubstrateSendTransaction.deserialize(bytes: bytes, object: object);

      case Web3SubstrateRequestMethods.signMessage:
        param = Web3SubstrateSignMessage.deserialize(bytes: bytes, object: object);
      case Web3SubstrateRequestMethods.addSubstrateChain:
        param = Web3SubstrateAddNewChain.deserialize(bytes: bytes, object: object);
      default:
        throw Web3RequestExceptionConst.methodDoesNotExist;
    }
    return param.cast<Web3SubstrateRequestParam<RESPONSE>>();
  }
}

class Web3SubstrateRequest<RESPONSE, PARAMS extends Web3SubstrateRequestParam<RESPONSE>>
    extends Web3NetworkRequest<RESPONSE, BaseSubstrateAddress, ISubstrateAddress,
        SubstrateChain, Web3SubstrateChainAccount, PARAMS> {
  Web3SubstrateRequest(
      {required super.params,
      required super.info,
      required super.authenticated,
      required super.chain,
      required super.accounts});

  Web3SubstrateRequest<R, P> cast<R, P extends Web3SubstrateRequestParam<R>>() {
    return this as Web3SubstrateRequest<R, P>;
  }
}
