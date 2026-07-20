import 'package:flutter/material.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/web3_request_page_builder.dart';
import 'package:on_chain_wallet/future/wallet/web3/core/state.dart';
import 'package:on_chain_wallet/wallet/api/api.dart';
import 'package:on_chain_wallet/wallet/models/signing/signing.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/networks/ripple/params/models/sign_message.dart';

class Web3XRPSignMessageStateController extends Web3XRPStateController<
    Web3XRPSignMessageResponse, XRPNetworkClient?, Web3XRPSignMessage> {
  String? get content => params.content;
  String get message => params.challeng;
  late final List<int> payloadMessage = params.chalengBytes();

  Web3XRPSignMessageStateController(
      {required super.walletProvider, required super.request});

  @override
  Future<Web3RequestResponseData<Web3XRPSignMessageResponse>> getResponse() async {
    final sign = await walletProvider.wallet.signTransaction(
      params: WalletActionSign(
          request: WalletSigningRequest(
        addresses: [defaultAccount],
        network: network,
        sign: (generateSignature) async {
          final signRequest = GlobalSignRequest.ripple(
              digest: payloadMessage, index: defaultAccount.derivationIndex.cast());
          final response = await generateSignature(signRequest);
          return Web3XRPSignMessageResponse(
              signature: response.signature,
              publicKey: defaultAccount.toXRPPublicKey().toBytes());
        },
      )),
    );
    return Web3RequestResponseData<Web3XRPSignMessageResponse>(response: sign.unwrap());
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return Web3StateSignMessageView(
        controller: this, message: message, content: content, isPersonalSign: true);
  }
}
