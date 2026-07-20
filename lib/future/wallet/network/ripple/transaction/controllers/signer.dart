import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/wallet/keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/signing.dart';
import 'package:on_chain_wallet/crypto/networks/ripple/ripple.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/signing/signing.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:xrpl_dart/xrpl_dart.dart';

mixin RippleTransactionSignerController on DisposableMixin {
  WalletProvider get walletProvider;
  WalletXRPNetwork get network;

  Future<XRPSignedTransaction> signTransactionInternalFull(
      {required SubmittableTransaction transaction,
      required IXRPAddress address,
      bool fakeSignature = false}) async {
    bool needMultiSig = false;
    if (address.multiSigAccount) {
      final IXRPMultisigAddress addr = address as IXRPMultisigAddress;
      needMultiSig = !addr.multiSignatureAccount.isRegular;
    }
    final request = WalletSigningRequest<XRPSignedTransaction>(
      addresses: [address],
      network: network,
      sign: (generateSignature) async {
        if (!needMultiSig) {
          final DerivableIndex keyIndex = switch (address) {
            IXRPMultisigAddress msg =>
              msg.multiSignatureAccount.signers[0].derivationIndex,
            _ => address.derivationIndex.cast<DerivableIndex>()
          };
          final algorithm = XRPKeyAlgorithm.values.firstWhere(
              (element) => element.curveType == keyIndex.currencyCoin.conf.type);
          final pubkey =
              XRPPublicKey.fromBytes(address.publicKey, algorithm: algorithm).toHex();

          transaction.setSignature(XRPLSignature.signer(pubkey));
          final signRequest = GlobalSignRequest.ripple(
              digest: BytesUtils.fromHexString(
                  transaction.toSigningBlob(address.networkAddress)),
              index: keyIndex.cast());
          final signatureBytes = await generateSignature(signRequest);
          final xrplSignature = XRPLSignature.sign(
              pubkey, BytesUtils.toHexString(signatureBytes.signature));
          transaction.setSignature(xrplSignature);
          return XRPSignedTransaction(
              signature: xrplSignature,
              transaction: transaction,
              multiSignature: [],
              signatures: [signatureBytes.signature]);
        } else {
          final multiSigAddress = address as IXRPMultisigAddress;
          transaction.setMultiSigSignature(multiSigAddress.multiSignatureAccount.signers
              .map((e) => XRPLSigners(
                  account:
                      RippleUtils.strPublicKeyToRippleAddress(e.publicKey).classicAddress,
                  txnSignature: null,
                  signingPubKey: e.publicKey))
              .toList());
          final List<XRPLSigners> signerSignatures = [];
          List<List<int>> signatures = [];
          int threshHold = 0;
          for (final i in multiSigAddress.multiSignatureAccount.signers) {
            final address = RippleUtils.strPublicKeyToRippleAddress(i.publicKey);
            final blob = transaction.toSigningBlob(address);
            try {
              final signRequest = GlobalSignRequest.ripple(
                  digest: BytesUtils.fromHexString(blob), index: i.derivationIndex);
              final sss = await generateSignature(signRequest);
              signerSignatures.add(XRPLSigners(
                  account: address.classicAddress,
                  signingPubKey:
                      XRPPublicKey.fromHex(sss.signerPubKey.comprossed).toHex(),
                  txnSignature: BytesUtils.toHexString(sss.signature)));
              signatures.add(sss.signature);
              threshHold += i.weight;
              if (threshHold >= multiSigAddress.multiSignatureAccount.threshold) {
                break;
              }
            } catch (e) {
              continue;
            }
          }
          if (threshHold < multiSigAddress.multiSignatureAccount.threshold) {
            throw AppCryptoExceptionConst.privateKeyIsNotAvailable;
          }
          transaction.setMultiSigSignature(signerSignatures);
          return XRPSignedTransaction(
              multiSignature: signerSignatures,
              transaction: transaction,
              signatures: signatures);
        }
      },
    );
    final signedTx = await walletProvider.wallet
        .signTransaction(params: WalletActionSign(request: request));
    return signedTx.unwrap();
  }

  Future<XRPSignedTransaction> signTransactionInternalPart(
      {required SubmittableTransaction transaction,
      required IXRPAddress address,
      bool fakeSignature = false}) async {
    final request = WalletSigningRequest<XRPSignedTransaction>(
      addresses: [address],
      network: network,
      sign: (generateSignature) async {
        // final keyIndex = address.derivationIndex.cast();
        final DerivableIndex keyIndex = switch (address) {
          IXRPMultisigAddress msg => msg.multiSignatureAccount.isRegular
              ? msg.multiSignatureAccount.signers[0].derivationIndex
              : throw WalletExceptionConst.featureUnavailableForMultiSignature,
          _ => address.derivationIndex.cast<DerivableIndex>()
        };
        final algorithm = XRPKeyAlgorithm.values.firstWhere(
            (element) => element.curveType == keyIndex.currencyCoin.conf.type);
        final pubkey =
            XRPPublicKey.fromBytes(address.publicKey, algorithm: algorithm).toHex();

        transaction.setSignature(XRPLSignature.signer(pubkey));
        final signRequest = GlobalSignRequest.ripple(
            digest: transaction.toSigningBlobBytes(address.networkAddress),
            index: keyIndex.cast());
        final signatureBytes = await generateSignature(signRequest);
        final xrplSignature =
            XRPLSignature.sign(pubkey, BytesUtils.toHexString(signatureBytes.signature));
        transaction.setSignature(xrplSignature);
        return XRPSignedTransaction(
            transaction: transaction,
            signatures: [signatureBytes.signature],
            signature: xrplSignature);
      },
    );
    final signedTx = await walletProvider.wallet
        .signTransaction(params: WalletActionSign(request: request));
    return signedTx.unwrap();
  }
}
