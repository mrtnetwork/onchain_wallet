import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain/ada/ada.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/signing.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/web3/core/state.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/web3_request_page_builder.dart';
import 'package:on_chain_wallet/wallet/api/api.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/signing/signing.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/cardano.dart';

class Web3ADASignDataStateController extends Web3CardanoStateController<
    Web3ADASignDataResponse, ADANetworkClient?, Web3ADASignData> {
  COSESign1Builder? _builder;
  Bip32DerivationIndex? _keyIndex;
  String? _message;
  String? get content => params.content;
  String get message => _message!;

  @override
  Future<Web3RequestResponseData<Web3ADASignDataResponse>> getResponse() async {
    final signature = await walletProvider.wallet.signTransaction(
        params: WalletActionSign(
            request: WalletSigningRequest(
      addresses: [defaultAccount],
      network: network,
      sign: (generateSignature) async {
        final signRequest = GlobalSignRequest.cardano(
            digest: _builder!.toSignMessageBytes(), index: _keyIndex!.cast());
        final response = await generateSignature(signRequest);
        final pubKeyBytes = response.signerPubKey.normalizedComprossedBytes;
        final key = COSEKey.fromEd25519Keypair(publicKey: pubKeyBytes);
        return Web3ADASignDataResponse(
            signature: _builder!.toSignBytes(response.signature),
            key: key.serialize(),
            pubKey: pubKeyBytes);
      },
    )));
    return Web3RequestResponseData(response: signature.unwrap());
  }

  Web3ADASignDataStateController({required super.walletProvider, required super.request});

  @override
  Widget widgetBuilder(BuildContext context) {
    return Web3StateSignMessageView(
        controller: this, message: message, content: content, isPersonalSign: true);
  }

  @override
  Future<void> initForm(ADANetworkClient? client) async {
    await super.initForm(client);
    final web3Account = params.accessAccount;
    DerivationIndex? correctKeyIndex;
    ADAAddress? address;
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
          address = mAccount.rewardAddress;
        }
      } else {
        final isPubKey = mAccount.addressInfo.credential.type.isPublicKey;
        if (isPubKey) {
          correctKeyIndex = mAccount.addressInfo.credential
              .cast<CardanoMultiSignatureKey>()
              .signer
              .derivationIndex;
          address = mAccount.networkAddress;
        }
      }
    } else {
      correctKeyIndex = defaultAccount.derivationIndex;
      address = defaultAccount.networkAddress;
    }

    if (correctKeyIndex == null || address == null) {
      throw Web3ADAExceptionConstant.unsuportedSigningMessageAccount;
    }
    _keyIndex = correctKeyIndex.cast();
    _builder = COSESign1Builder(
        headers: COSEHeaders(
            protected: COSEProtectedHeaderMap(
              CborMapValue<CborObject, CborObject>.definite({
                CborIntValue(COSEKeyType.okp.value):
                    CborIntValue(COSEAlgorithmId.eddsa.value),
                CborStringValue("address"): CborBytesValue(address.toBytes()),
              }).encode(),
            ),
            unprotected: COSEHeaderMap()),
        payload: params.chalengBytes(),
        externalAad: []);
    _message = BytesUtils.toHexString(_builder!.toSignMessageBytes());
  }
}
