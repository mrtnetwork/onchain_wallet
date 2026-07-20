import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/crypto.dart';
import 'package:on_chain_wallet/future/wallet/network/zcash/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/web3_request_page_builder.dart';
import 'package:on_chain_wallet/future/wallet/web3/core/state.dart';
import 'package:on_chain_wallet/wallet/api/api.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/networks/zcash/constant/constants/exception.dart';
import 'package:on_chain_wallet/web3/web3/networks/zcash/params/models/sign_message.dart';

class Web3ZcashSignMessageStateController extends Web3ZcashStateController<
    Web3ZcashSignMessageResponse, ZcashNetworkClient?, Web3ZcashSignMessage> {
  Bip32DerivationIndex? index;
  String get message => request.params.challeng;
  String? get content => request.params.content;
  String get messagePrefix => BitcoinSignerUtils.signMessagePrefix;
  BIP137Mode get mode => BIP137Mode.p2pkhCompressed;
  bool get isPersonalMessage => true;
  Web3ZcashSignMessageStateController(
      {required super.walletProvider, required super.request});

  @override
  Future<Web3RequestResponseData<Web3ZcashSignMessageResponse>> getResponse() async {
    final index = this.index;
    if (index == null) {
      throw Web3ZcashExceptionConstant.unsuportedSigningMessageAccount(
          defaultAccount.address);
    }
    IResult<CryptoBitcoinPersonalSignResponse> sign = await walletProvider.wallet
        .doAction(WalletActionWalletRequest(
            request: WalletRequestBitcoinSignMessage(
                message: BytesUtils.fromHexString(params.challeng),
                index: index,
                useTaproot: false,
                mode: mode,
                messagePrefix: messagePrefix)));
    final signature = sign.unwrap();
    return Web3RequestResponseData(
        response: Web3ZcashSignMessageResponse(
            signature: signature.signature, digest: signature.digest));
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return Web3StateSignMessageView(
      controller: this,
      message: message,
      content: content,
      isPersonalSign: true,
      prefix: messagePrefix,
    );
  }

  @override
  Future<void> initForm(ZcashNetworkClient? client) async {
    final account = defaultAccount.networkAddress.tryToTransparentAddreses();
    final protocolAccount =
        defaultAccount.account.getProtocolReceiver(ZcashProtocol.transparent);
    if (account == null ||
        protocolAccount == null ||
        account.type != P2pkhAddressType.p2pkh) {
      throw Web3ZcashExceptionConstant.unsuportedSigningMessageAccount(
          defaultAccount.address);
    }
    index = protocolAccount.index.cast();
  }
}
