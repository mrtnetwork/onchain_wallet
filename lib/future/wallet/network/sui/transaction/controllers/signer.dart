import 'package:on_chain/sui/src/keypair/types/types.dart';
import 'package:on_chain/sui/src/keypair/utils/utils.dart';
import 'package:on_chain/sui/src/transaction/types/types.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/signing.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/sui/transaction/types/types.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/signing/signing.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';

mixin SuiTransactionSignerController on DisposableMixin {
  WalletProvider get walletProvider;
  WalletSuiNetwork get network;
  Future<SuiSignedTransaction> signTransactionInternal(
      {required SuiTransactionDataV1 transaction, required ISuiAddress signer}) async {
    final transactionDigest = SuiCryptoUtils.generateTransactionDigest(
        txBytes: transaction.serializeSign(), hashDigest: true);
    List<List<int>> signatures = [];
    final genericSignature = await walletProvider.wallet.signTransaction(
        params: WalletActionSign(
            request: WalletSigningRequest(
      network: network,
      addresses: [signer],
      sign: (generateSignature) async {
        if (signer.multiSigAccount) {
          final multisigAccount = signer as ISuiMultiSigAddress;
          List<SuiGenericSignature> genericSignatures = [];
          int weight = 0;
          for (final i in multisigAccount.multiSignatureAddress.publicKeys) {
            final Bip32DerivationIndex signer = i.derivationIndex;
            final signRequest =
                GlobalSignRequest.sui(digest: transactionDigest, index: signer);
            final signature = await generateSignature(signRequest);
            signatures.add(signature.signature);
            genericSignatures.add(SuiGenericSignature(
                signature: signature.signature, algorithm: i.keyScheme.suiKeyAlgorithm));
            weight += i.weight;
            if (weight >= multisigAccount.multiSignatureAddress.threshold) {
              break;
            }
          }
          if (weight < multisigAccount.multiSignatureAddress.threshold) {
            throw AppException("insufficient_signatures");
          }
          return genericSignatures;
        } else {
          final Bip32DerivationIndex keyIndex = signer.derivationIndex.cast();
          final signRequest =
              GlobalSignRequest.sui(digest: transactionDigest, index: keyIndex);
          final signature = await generateSignature(signRequest);
          final suiSignature = SuiGenericSignature(
              signature: signature.signature,
              algorithm: signer.keyScheme.suiKeyAlgorithm);
          signatures.add(signature.signature);
          return [suiSignature];
        }
      },
    )));
    final signature = signer.createTransactionAuthenticated(genericSignature.unwrap());
    return SuiSignedTransaction(
        suiSignature: signature, signatures: signatures, transaction: transaction);
  }
}
