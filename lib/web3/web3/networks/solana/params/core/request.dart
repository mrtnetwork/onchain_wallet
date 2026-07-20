import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/web3/web3/networks/solana/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/solana/params/models/sign_message.dart';
import 'package:on_chain_wallet/web3/web3/networks/solana/params/models/transaction.dart';
import 'package:on_chain_wallet/web3/web3/networks/solana/permission/models/account.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain/solana/solana.dart';

abstract class Web3SolanaRequestParam<RESPONSE> extends Web3RequestParams<RESPONSE,
    SolAddress, ISolanaAddress, SolanaChain, Web3SolanaChainAccount> {
  @override
  abstract final Web3SolanaRequestMethods method;

  Web3SolanaRequestParam();

  factory Web3SolanaRequestParam.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: Web3MessageTypes.walletRequest.tag);
    final method = Web3NetworkRequestMethods.findMethod(values.objectAt(0)).method;
    final Web3SolanaRequestParam param;
    switch (method) {
      case Web3SolanaRequestMethods.signTransaction:
      case Web3SolanaRequestMethods.signAndSendAllTransactions:
      case Web3SolanaRequestMethods.sendTransaction:
      case Web3SolanaRequestMethods.signAllTransactions:
        param = Web3SolanaSendTransaction.deserialize(bytes: bytes, object: object);
      case Web3SolanaRequestMethods.signIn:
      case Web3SolanaRequestMethods.signMessage:
        param = Web3SolanaSignMessage.deserialize(bytes: bytes, object: object);
      default:
        throw Web3RequestExceptionConst.methodDoesNotExist;
    }
    return param.cast<Web3SolanaRequestParam<RESPONSE>>();
  }
}

class Web3SolanaRequest<RESPONSE, PARAMS extends Web3SolanaRequestParam<RESPONSE>>
    extends Web3NetworkRequest<RESPONSE, SolAddress, ISolanaAddress, SolanaChain,
        Web3SolanaChainAccount, PARAMS> {
  Web3SolanaRequest(
      {required super.params,
      required super.info,
      required super.authenticated,
      required super.chain,
      required super.accounts});

  Web3SolanaRequest<R, P> cast<R, P extends Web3SolanaRequestParam<R>>() {
    return this as Web3SolanaRequest<R, P>;
  }
}
