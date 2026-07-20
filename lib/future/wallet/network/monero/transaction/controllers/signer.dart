import 'package:on_chain_wallet/app/core.dart';
import 'dart:async';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/signing.dart';
import 'package:on_chain_wallet/future/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

mixin MoneroTransactionSignerController on DisposableMixin {
  WalletProvider get walletProvider;
  WalletMoneroNetwork get network;

  Future<IMoneroSignedTransaction> signTransactionInternal(IMoneroTransaction transaction,
      {bool fakeSignature = false, bool withProof = false}) async {
    assert(!fakeSignature, "fakeSignature not suported");
    final signedTx = await walletProvider.wallet.signTransaction(
      params: WalletActionSign(
          request: WalletSigningRequest(
        addresses: transaction.transactionData.payments.map((e) => e.account).toList(),
        network: network,
        sign: (generateSignature) async {
          final s = MoneroSigningRequest(
              destinations: transaction.transactionData.destinations
                  .map((e) => MoneroTxDestination(
                      amount: e.amount.balance, address: e.recipient.networkAddress))
                  .toList(),
              fee: transaction.fee,
              utxos: transaction.spendablePayment,
              change: transaction.transactionData.change,
              index: transaction.account.derivationIndex.cast<DerivableIndex>(),
              withProof: withProof);
          final r = await generateSignature(s);
          return MoneroSigningTxResponse.deserialize(bytes: r.signature);
        },
      )),
    );
    return IMoneroSignedTransaction(
        transaction: transaction,
        signatures: [],
        finalTransactionData: signedTx.unwrap());
  }
}
