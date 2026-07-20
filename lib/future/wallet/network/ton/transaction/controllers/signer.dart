import 'package:blockchain_utils/signer/const/constants.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/signing.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/signing/signing.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:ton_dart/ton_dart.dart';

mixin TonTransactionSignerController on DisposableMixin {
  WalletTonNetwork get network;
  WalletProvider get walletProvider;
  Future<TonSignedTransaction> signTransactionInternal(
      {required Cell transaction,
      required ITonAddress signer,
      StateInit? stateInit,
      bool fakeSignature = false}) async {
    List<int> sig = List<int>.unmodifiable(
        List<int>.filled(CryptoSignerConst.ed25519SignatureLength, 0));

    if (!fakeSignature) {
      final signature = await walletProvider.wallet.signTransaction(
          params: WalletActionSign(
              request: WalletSigningRequest(
        addresses: [signer],
        network: network,
        sign: (generateSignature) async {
          final signRequest = GlobalSignRequest.ton(
              digest: transaction.hash(), index: signer.derivationIndex.cast());
          final response = await generateSignature(signRequest);
          return response.signature;
        },
      )));
      sig = signature.unwrap();
    }
    final message = signer.context.toExternalMessage(
        message: transaction,
        signature: sig,
        destination: signer.networkAddress,
        state: stateInit);
    return TonSignedTransaction(message: message, signatures: [sig]);
  }
}
