import 'package:flutter/material.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/wallet/requests/personal_sign.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/web3_request_page_builder.dart';
import 'package:on_chain_wallet/future/wallet/web3/core/state.dart';
import 'package:on_chain_wallet/wallet/api/api.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/networks/ethereum/params/models/personal_sign.dart';

class Web3EthereumPersonalSignStateController extends Web3EthereumStateController<String,
    EthereumNetworkClient?, Web3EthreumPersonalSign> {
  String? get content => params.content;
  String get message => params.message;
  late final List<int> payloadMessage = params.chalengBytes();

  Web3EthereumPersonalSignStateController(
      {required super.walletProvider, required super.request});

  @override
  Future<Web3RequestResponseData<String>> getResponse() async {
    final account = defaultAccount;
    final sign = await walletProvider.wallet.doAction(
      WalletActionWalletRequest(
          request: WalletRequestSignMessage(
              message: request.params.cast<Web3EthreumPersonalSign>().chalengBytes(),
              index: account.derivationIndex.cast(),
              network: NetworkType.ethereum)),
    );
    return Web3RequestResponseData<String>(response: sign.unwrap().signatureHex);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return Web3StateSignMessageView(
        controller: this, message: message, content: content, isPersonalSign: true);
  }
}
