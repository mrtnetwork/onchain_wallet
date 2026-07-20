import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/web3/pages/sign_message.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/web3/core/state.dart';
import 'package:on_chain_wallet/wallet/api/api.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/signing/signing.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/networks/solana/params/models/sign_message.dart';

class Web3SolanaSignMessageStateController extends Web3SolanaStateController<
    List<Web3SolanaSignMessageResponse>, SolanaNetworkClient?, Web3SolanaSignMessage> {
  List<Web3SolanaSignParamsData> _messages = [];
  List<Web3SolanaSignParamsData> get messages => _messages;
  Web3SolanaSignMessageStateController(
      {required super.walletProvider, required super.request});

  @override
  Future<Web3RequestResponseData<List<Web3SolanaSignMessageResponse>>>
      getResponse() async {
    final signatures = await walletProvider.wallet.signTransaction(
        params: WalletActionSign(
            request: WalletSigningRequest(
      addresses: messages.map((e) => e.address).toList(),
      network: network,
      sign: (generateSignature) async {
        final List<Web3SolanaSignMessageResponse> signedMessages = [];
        for (int i = 0; i < messages.length; i++) {
          final msg = messages[i];
          final signer = messages[i].address;
          final signMessage = msg.payload;
          final signRequest = GlobalSignRequest.solana(
              digest: signMessage, index: signer.derivationIndex.cast());
          final response = await generateSignature(signRequest);
          signedMessages.add(Web3SolanaSignMessageResponse(
              address: signer.networkAddress,
              signature: response.signature,
              signedMessage: signMessage));
        }

        return signedMessages;
      },
    )));
    return Web3RequestResponseData(response: signatures.unwrap());
  }

  @override
  Future<void> initForm(SolanaNetworkClient? client) async {
    await super.initForm(client);
    List<Web3SolanaSignParamsData> messages = [];
    final List<ISolanaAddress> signers = request.accounts;
    for (final i in request.params.messages) {
      final msg = Web3SolanaSignParamsData(
          payload: i.dataBytes(),
          address: signers.firstWhere((e) => e.networkAddress == i.account.address,
              orElse: () => throw Web3RequestExceptionConst.missingPermission),
          method: request.params.method,
          params: i);
      messages.add(msg);
    }
    _messages = messages.immutable;
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return Web3SolanaSignMessageStateView(this);
  }
}
