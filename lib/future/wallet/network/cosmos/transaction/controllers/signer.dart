import 'package:blockchain_utils/signer/const/constants.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/signing.dart';
import 'package:on_chain_wallet/future/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network.dart';
import 'package:on_chain_wallet/wallet/models/signing/signing.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';

mixin CosmosTransactionSignerController on DisposableMixin {
  WalletProvider get walletProvider;
  WalletCosmosNetwork get network;
  Future<CosmosSignedTransaction> signTransactionInternal(
      {required List<int> payload,
      required ICosmosAddress signer,
      bool fakeSignature = false}) async {
    if (fakeSignature) {
      return CosmosSignedTransaction(
          signature: List<int>.filled(CryptoSignerConst.ecdsaSignatureLength, 0),
          payload: payload);
    }
    final signRequest = WalletSigningRequest(
      addresses: [signer],
      network: network,
      sign: (generateSignature) async {
        final signRequest = CosmosSigningRequest(
            digest: payload, index: signer.derivationIndex.cast(), alg: signer.algorithm);
        final sss = await generateSignature(signRequest);
        return sss.signature;
      },
    );
    final signature = await walletProvider.wallet
        .signTransaction(params: WalletActionSign(request: signRequest));
    return CosmosSignedTransaction(signature: signature.unwrap(), payload: payload);
  }
}
