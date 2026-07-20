import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';

import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/core/core.dart';
import 'package:on_chain_wallet/web3/web3/networks/substrate/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/substrate/params/core/request.dart';
import 'package:on_chain_wallet/web3/web3/networks/substrate/params/models/transaction.dart';
import 'package:on_chain_wallet/web3/web3/networks/substrate/permission/models/account.dart';

class Web3SubstrateSignMessage
    extends Web3SubstrateRequestParam<Web3SubstrateSendTransactionResponse> {
  final Web3SubstrateChainAccount accessAccount;
  final String challeng;
  final String? content;

  Web3SubstrateSignMessage(
      {required this.accessAccount, required this.challeng, this.content});

  factory Web3SubstrateSignMessage.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
      cborBytes: bytes,
      cborObject: object,
      identifier: Web3MessageTypes.walletRequest.tag,
    );
    final List<int> challeng = values.rawValueAt(2);
    return Web3SubstrateSignMessage(
        accessAccount: Web3SubstrateChainAccount.deserialize(
            object: values.objectAt<CborTagValue>(1)),
        challeng: BytesUtils.toHexString(challeng, prefix: "0x"),
        content: values.rawValueAt(3));
  }

  @override
  Web3SubstrateRequestMethods get method => Web3SubstrateRequestMethods.signMessage;

  List<int> chalengBytes() {
    return BytesUtils.fromHexString(challeng);
  }

  @override
  Future<
      IResult<
          Web3SubstrateRequest<Web3SubstrateSendTransactionResponse,
              Web3SubstrateSignMessage>>> toRequest(
      {required Web3RequestInformation request,
      required Web3RequestAuthentication authenticated,
      required WEB3REQUESTNETWORKCONTROLLER<ISubstrateAddress, SubstrateChain,
              Web3SubstrateChainAccount>
          chainController}) async {
    final chain = await super.findRequestChain(
        request: request, authenticated: authenticated, chainController: chainController);
    return chain.map((chain) => Web3SubstrateRequest<Web3SubstrateSendTransactionResponse,
            Web3SubstrateSignMessage>(
          params: this,
          authenticated: authenticated,
          chain: chain.$1,
          info: request,
          accounts: chain.$2,
        ));
  }

  @override
  List<Web3SubstrateChainAccount> get requiredAccounts => [accessAccount];

  @override
  Object? toJsWalletResponse(Web3SubstrateSendTransactionResponse response) {
    return response.toCbor().encode();
  }

  @override
  List<CborObject?> get serializationItems => [
        method.methodInfos,
        accessAccount.toCbor(),
        CborBytesValue(BytesUtils.fromHexString(challeng)),
        content?.toCbor()
      ];
}
