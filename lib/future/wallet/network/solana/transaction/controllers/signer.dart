import 'package:on_chain/solana/src/transaction/transaction/transaction.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/signing.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/transaction/types/types.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';

import 'package:on_chain_wallet/wallet/wallet.dart';

mixin SolanaTransactionSignerController on DisposableMixin {
  WalletSolanaNetwork get network;
  WalletProvider get walletProvider;

  Future<SolanaSignedTransaction> signTransactionInternal(
      {required SolanaTransaction transaction,
      required List<ISolanaAddress> signers}) async {
    final signature = await walletProvider.wallet.signTransaction(
        params: WalletActionSign(
            request: WalletSigningRequest(
      network: network,
      addresses: signers,
      sign: (generateSignature) async {
        final List<List<int>> signatures = [];
        final digest = List<int>.unmodifiable(transaction.serializeMessage());
        for (int i = 0; i < signers.length; i++) {
          final addr = signers.elementAt(i);
          final Bip32DerivationIndex signer = addr.derivationIndex.cast();
          final signRequest = GlobalSignRequest.solana(digest: digest, index: signer);
          final signature = await generateSignature(signRequest);
          signatures.add(signature.signature);
          transaction.addSignature(addr.networkAddress, signature.signature);
        }
        return SolanaSignedTransaction(transaction: transaction, signatures: signatures);
      },
    )));
    return signature.unwrap();
  }
}
