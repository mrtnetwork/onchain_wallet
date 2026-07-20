import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain/sui/src/keypair/types/types.dart';
import 'package:on_chain/sui/src/keypair/utils/utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages.dart';
import 'package:on_chain_wallet/future/wallet/network/sui/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/web3_request_page_builder.dart';
import 'package:on_chain_wallet/future/wallet/web3/core/state.dart';
import 'package:on_chain_wallet/wallet/api/api.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/signing/signing.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/networks/sui/params/models/sign_message.dart';

class Web3SuiSignMessageStateController extends Web3SuiStateController<
    Web3SuiSignMessageResponse, SuiNetworkClient?, Web3SuiSignMessage> {
  String? get content => params.content;
  String get message => params.challeng;
  late final List<int> payloadMessage =
      BytesUtils.fromHexString(params.challeng).toImutableBytes;

  Web3SuiSignMessageStateController(
      {required super.walletProvider, required super.request});

  @override
  Future<Web3RequestResponseData<Web3SuiSignMessageResponse>> getResponse() async {
    final digest = SuiCryptoUtils.generatePersonalMessageDigest(payloadMessage);
    final signatures = await walletProvider.wallet.signTransaction(
        params: WalletActionSign(
            request: WalletSigningRequest(
      network: network,
      addresses: [defaultAccount],
      sign: (generateSignature) async {
        if (defaultAccount.multiSigAccount) {
          final multisigAccount = defaultAccount as ISuiMultiSigAddress;
          List<SuiGenericSignature> signatures = [];
          int weight = 0;
          for (final i in multisigAccount.multiSignatureAddress.publicKeys) {
            final Bip32DerivationIndex signer = i.derivationIndex;
            final signRequest = GlobalSignRequest.sui(digest: digest, index: signer);
            final signature = await generateSignature(signRequest);
            signatures.add(SuiGenericSignature(
                signature: signature.signature, algorithm: i.keyScheme.suiKeyAlgorithm));
            weight += i.weight;
            if (weight >= multisigAccount.multiSignatureAddress.threshold) {
              break;
            }
          }
          if (weight < multisigAccount.multiSignatureAddress.threshold) {
            throw AppException("insufficient_signatures");
          }
          return signatures;
        } else {
          final Bip32DerivationIndex signer = defaultAccount.derivationIndex.cast();
          final signRequest = GlobalSignRequest.sui(digest: digest, index: signer);
          final signature = await generateSignature(signRequest);
          final suiSignature = SuiGenericSignature(
              signature: signature.signature,
              algorithm: defaultAccount.keyScheme.suiKeyAlgorithm);
          return [suiSignature];
        }
      },
    )));
    final signature = defaultAccount.createTransactionAuthenticated(signatures.unwrap());
    return Web3RequestResponseData<Web3SuiSignMessageResponse>(
        response: Web3SuiSignMessageResponse(
            messageBytes: payloadMessage, signature: signature.toVariantBcs()));
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return Web3StateSignMessageView(
        controller: this, message: message, content: content, isPersonalSign: true);
  }
}
