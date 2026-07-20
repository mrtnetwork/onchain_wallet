import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/signing.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/web3_request_page_builder.dart';
import 'package:on_chain_wallet/future/wallet/web3/core/state.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/networks/ethereum/params/models/personal_sign.dart';

class Web3EthereumEthSignStateController extends Web3EthereumStateController<String,
    EthereumNetworkClient?, Web3EthreumPersonalSign> {
  String? get content => params.content;
  String get message => params.message;
  late final List<int> payloadMessage = params.chalengBytes();

  Web3EthereumEthSignStateController(
      {required super.walletProvider, required super.request});

  @override
  Future<Web3RequestResponseData<String>> getResponse() async {
    final account = defaultAccount;
    final WalletSigningRequest<ETHSignature> signingRequest =
        WalletSigningRequest<ETHSignature>(
      addresses: [account],
      network: network,
      sign: (generateSignature) async {
        final signRequest = GlobalSignRequest.eth(
            digest: payloadMessage, index: account.derivationIndex.cast());
        final ethSignature = await generateSignature(signRequest);
        return ETHSignature.fromBytes(ethSignature.signature);
      },
    );
    final signature = await walletProvider.wallet
        .signTransaction(params: WalletActionSign(request: signingRequest));
    return Web3RequestResponseData<String>(response: signature.unwrap().toHex());
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return Web3StateSignMessageView(controller: this, message: message, content: content);
  }
}
