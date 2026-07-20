import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:on_chain/tron/src/models/contract/transaction/transaction.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/tron/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/tron/params/core/request.dart';
import 'package:on_chain_wallet/web3/web3/networks/tron/permission/models/account.dart';

class Web3TronSignTransaction extends Web3TronRequestParam<Transaction> {
  final List<int> transaction;
  final String? txId;
  final Web3TronChainAccount accessAccount;
  @override
  List<Web3TronChainAccount> get requiredAccounts => [accessAccount];

  Web3TronSignTransaction(
      {required List<int> transaction, this.txId, required this.accessAccount})
      : transaction = transaction.asImmutableBytes;

  factory Web3TronSignTransaction.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: Web3MessageTypes.walletRequest.tag,
    );
    return Web3TronSignTransaction(
        transaction: values.rawValueAt(1),
        txId: values.rawValueAt(2),
        accessAccount:
            Web3TronChainAccount.deserialize(object: values.objectAt<CborTagValue>(3)));
  }

  @override
  Web3TronRequestMethods get method => Web3TronRequestMethods.signTransaction;

  @override
  Future<IResult<Web3TronRequest<Transaction, Web3TronSignTransaction>>> toRequest(
      {required Web3RequestInformation request,
      required Web3RequestAuthentication authenticated,
      required WEB3REQUESTNETWORKCONTROLLER<ITronAddress, TronChain, Web3TronChainAccount>
          chainController}) async {
    final chain = await super.findRequestChain(
        request: request, authenticated: authenticated, chainController: chainController);
    return chain.map((chain) => Web3TronRequest<Transaction, Web3TronSignTransaction>(
          params: this,
          authenticated: authenticated,
          chain: chain.$1,
          info: request,
          accounts: chain.$2,
        ));
  }

  @override
  Object? toJsWalletResponse(Transaction response) {
    return response.toHex;
  }

  @override
  List<CborObject?> get serializationItems => [
        method.methodInfos,
        CborBytesValue(transaction),
        txId?.toCbor(),
        accessAccount.toCbor()
      ];
}
