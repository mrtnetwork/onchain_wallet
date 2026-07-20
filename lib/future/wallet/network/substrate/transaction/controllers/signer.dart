import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/signing.dart';
import 'package:on_chain_wallet/crypto/networks/substrate/substrate.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/transaction/types/types.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/signing/signing.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';

mixin SubstrateTransactionSignerController on DisposableMixin {
  WalletProvider get walletProvider;
  WalletSubstrateNetwork get network;
  Future<SubstrateSignedTransaction> signTransactionInternal({
    required List<int> payloadBytes,
    required ISubstrateAddress signer,
    bool fakeSignature = false,
  }) async {
    List<int> signature;
    if (fakeSignature) {
      signature = SubstrateUtils.createFakeSignature(signer.coin.conf.type);
    } else {
      final sig = await walletProvider.wallet.signTransaction(
          params: WalletActionSign(
              request: WalletSigningRequest<List<int>>(
        addresses: [signer],
        network: network,
        sign: (generateSignature) async {
          final signature = await generateSignature(GlobalSignRequest.substrate(
              digest: payloadBytes, index: signer.derivationIndex.cast()));
          return signature.signature;
        },
      )));
      signature = sig.unwrap();
    }
    return SubstrateSignedTransaction(signatures: [signature], payload: payloadBytes);
  }
}
