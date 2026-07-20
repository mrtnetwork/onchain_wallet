import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain/aptos/aptos.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/wallet/keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages.dart';
import 'package:on_chain_wallet/crypto/networks/aptos/aptos.dart';
import 'package:on_chain_wallet/future/wallet/network/aptos/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/web3_request_page_builder.dart';
import 'package:on_chain_wallet/future/wallet/web3/core/state.dart';
import 'package:on_chain_wallet/wallet/api/api.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/signing/signing.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/networks/aptos/constant/constants/constant.dart';
import 'package:on_chain_wallet/web3/web3/networks/aptos/params/models/sign_message.dart';

class Web3AptosSignInMessageStateController extends Web3AptosStateController<
    Web3AptosSignMessageResponse, AptosNetworkClient?, Web3AptosSignMessage> {
  late final String? content;
  late final String message;
  late final List<int> payloadMessage;
  String? _address;
  String? _application;
  int? _chainId;

  Web3AptosSignInMessageStateController(
      {required super.walletProvider, required super.request});

  @override
  Future<Web3RequestResponseData<Web3AptosSignMessageResponse>> getResponse() async {
    final address = defaultAccount;
    final signedTr = await walletProvider.wallet.signTransaction(
        params: WalletActionSign(
            request: WalletSigningRequest(
      network: network,
      addresses: [address],
      sign: (generateSignature) async {
        if (address.multiSigAccount) {
          List<AptosAnySignature> signatures = [];
          final multisigAddress =
              address.cast<IAptosMultiSigAddress>().multiSignatureAddress;
          for (int i = 0; i < multisigAddress.requiredSignature; i++) {
            final publicKey = multisigAddress.publicKeys[i];
            final Bip32DerivationIndex signer = publicKey.derivationIndex;
            final signRequest =
                GlobalSignRequest.aptos(digest: payloadMessage, index: signer);
            final signature = await generateSignature(signRequest);
            signatures.add(AptosUtils.generateSignature(
                signature.signature, publicKey.keyScheme.curve));
          }
          return signatures;
        }
        final Bip32DerivationIndex signer = address.derivationIndex.cast();
        final signRequest =
            GlobalSignRequest.aptos(digest: payloadMessage, index: signer);
        final signature = await generateSignature(signRequest);
        return [
          AptosUtils.generateSignature(signature.signature, address.keyScheme.curve)
        ];
      },
    )));

    final auth = address.createAccountAuthenticated(signedTr.unwrap());
    final signature = auth.signature.toBytes();
    final result = Web3AptosSignMessageResponse.aptos(
        message: request.params.message!,
        nonce: request.params.nonce!,
        fullMessage: message,
        prefix: Web3AptosConst.signMessagePrefix,
        signature: signature,
        address: _address,
        application: _application,
        chainId: _chainId);
    return Web3RequestResponseData(response: result);
  }

  @override
  Future<void> initForm(AptosNetworkClient? client) async {
    if (params.messageBytes != null) {
      message = params.messageBytes!;
      payloadMessage = BytesUtils.fromHexString(message).asImmutableBytes;
      content = StringUtils.tryDecode(payloadMessage);
      return;
    }
    final address = defaultAccount;
    String signingMessage = Web3AptosConst.signMessagePrefix;
    if (params.application ?? false) {
      signingMessage += APPConst.name;
      _application = APPConst.name;
    }
    if (params.address ?? false) {
      signingMessage += address.networkAddress.address;
      _address = address.networkAddress.address;
    }
    signingMessage += params.nonce!;
    if (params.chainId ?? false) {
      final chainId = await client!.getCurrenctChainId();
      signingMessage += chainId.toString();
      _chainId = chainId;
    }
    signingMessage += params.message!;
    message = signingMessage;
    payloadMessage = StringUtils.encode(message).asImmutableBytes;
    content = null;
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return Web3StateSignMessageView(controller: this, message: message, content: content);
  }
}
