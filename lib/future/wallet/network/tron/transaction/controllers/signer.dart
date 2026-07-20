import 'package:on_chain_wallet/app/core.dart';
import 'dart:async';
import 'package:on_chain/tron/src/models/contract/transaction/transaction.dart';
import 'package:on_chain/tron/src/models/contract/transaction/transaction_raw.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/signing.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

mixin TronTransactionSignerController on DisposableMixin {
  WalletTronNetwork get network;
  WalletProvider get walletProvider;
  Future<Transaction> signTransactionInternal({
    required TransactionRaw transaction,
    required ITronAddress address,
    bool fakeSignature = false,
  }) async {
    final transactionRaw = transaction;
    List<List<int>> signatures = [];
    if (!fakeSignature) {
      final WalletSigningRequest<List<List<int>>> request =
          WalletSigningRequest<List<List<int>>>(
        addresses: [address],
        network: network,
        sign: (generateSignature) async {
          final List<int> transactionDigest =
              List<int>.unmodifiable(transactionRaw.toBuffer());
          if (address.multiSigAccount) {
            final multiSigAddress = address as ITronMultisigAddress;
            final List<List<int>> signerSignatures = [];
            BigInt threshHold = BigInt.zero;
            for (final i in multiSigAddress.multiSignatureAccount.signers) {
              final signRequest = GlobalSignRequest.tron(
                  digest: transactionDigest, index: i.derivationIndex);
              final sss = await generateSignature(signRequest);
              signerSignatures.add(sss.signature);
              threshHold += i.weight;
              if (threshHold >= multiSigAddress.multiSignatureAccount.threshold) {
                break;
              }
            }
            if (threshHold < multiSigAddress.multiSignatureAccount.threshold) {
              throw AppCryptoExceptionConst.privateKeyIsNotAvailable;
            }
            return signerSignatures;
          }
          final signRequest = GlobalSignRequest.tron(
              digest: transactionDigest, index: address.derivationIndex.cast());
          final signature = await generateSignature(signRequest);
          return [signature.signature];
        },
      );
      final signature = await walletProvider.wallet
          .signTransaction(params: WalletActionSign(request: request));
      signatures = signature.unwrap();
    }

    return Transaction(rawData: transaction, signature: signatures);
  }
}
