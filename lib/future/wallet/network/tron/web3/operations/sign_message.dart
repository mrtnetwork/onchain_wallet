import 'package:blockchain_utils/signer/const/constants.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/web3_request_page_builder.dart';
import 'package:on_chain_wallet/future/wallet/web3/core/state.dart';
import 'package:on_chain_wallet/wallet/api/api.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/networks/tron/params/models/sign_message_v2.dart';

class Web3TronSignMessageStateController
    extends Web3TronStateController<String, TronClient?, Web3TronSignMessageV2> {
  String? get content => params.content;
  String get message => params.challeng;
  late final List<int> payloadMessage = params.chalengBytes();

  Web3TronSignMessageStateController(
      {required super.walletProvider, required super.request});

  @override
  Future<Web3RequestResponseData<String>> getResponse() async {
    final sign = await walletProvider.wallet.doAction(WalletActionWalletRequest(
        request: WalletRequestSignMessage(
            message: payloadMessage,
            index: defaultAccount.derivationIndex.cast(),
            network: NetworkType.tron)));
    return Web3RequestResponseData<String>(response: sign.unwrap().signatureHex);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return Web3StateSignMessageView(
      controller: this,
      message: message,
      content: content,
      isPersonalSign: true,
      prefix: CryptoSignerConst.tronSignMessagePrefix,
    );
  }
}
