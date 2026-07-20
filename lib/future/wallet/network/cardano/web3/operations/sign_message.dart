import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/signing.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/web3_request_page_builder.dart';
import 'package:on_chain_wallet/future/wallet/web3/core/state.dart';
import 'package:on_chain_wallet/wallet/api/api.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/signing/signing.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/cardano.dart';

class Web3ADASignMessageStateController extends Web3CardanoStateController<
    Web3ADASignMessageResponse, ADANetworkClient?, Web3ADASignMessage> {
  Bip32DerivationIndex? _keyIndex;

  String? get content => params.content;
  String get message => params.challeng;
  late final List<int> payloadMessage =
      BytesUtils.fromHexString(params.challeng).toImutableBytes;

  @override
  Future<Web3RequestResponseData<Web3ADASignMessageResponse>> getResponse() async {
    final signature = await walletProvider.wallet.signTransaction(
        params: WalletActionSign(
            request: WalletSigningRequest(
      addresses: [defaultAccount],
      network: network,
      sign: (generateSignature) async {
        final signRequest =
            GlobalSignRequest.cardano(digest: payloadMessage, index: _keyIndex!.cast());
        final response = await generateSignature(signRequest);
        return Web3ADASignMessageResponse(signature: response.signature);
      },
    )));
    return Web3RequestResponseData(response: signature.unwrap());
  }

  Web3ADASignMessageStateController(
      {required super.walletProvider, required super.request});

  @override
  Widget widgetBuilder(BuildContext context) {
    return Web3StateSignMessageView(
        controller: this, message: message, content: content, isPersonalSign: false);
  }

  @override
  Future<void> initForm(ADANetworkClient? client) async {
    await super.initForm(client);
    final web3Account = params.accessAccount;
    DerivationIndex? correctKeyIndex;
    final keyIndex = web3Account.derivationIndex;
    if (keyIndex.isMultiSig) {
      final mAccount = defaultAccount as ICardanoMultiSigAddress;
      if (web3Account.isRewardAddress) {
        final isPubKey = mAccount.addressInfo.stakeCredential?.type.isPublicKey ?? false;
        if (isPubKey) {
          correctKeyIndex = mAccount.addressInfo.stakeCredential!
              .cast<CardanoMultiSignatureKey>()
              .signer
              .derivationIndex;
        }
      } else {
        final isPubKey = mAccount.addressInfo.credential.type.isPublicKey;
        if (isPubKey) {
          correctKeyIndex = mAccount.addressInfo.credential
              .cast<CardanoMultiSignatureKey>()
              .signer
              .derivationIndex;
        }
      }
    } else {
      correctKeyIndex = defaultAccount.derivationIndex;
    }

    if (correctKeyIndex == null) {
      throw Web3ADAExceptionConstant.unsuportedSigningMessageAccount;
    }
    _keyIndex = correctKeyIndex.cast();
  }
}
