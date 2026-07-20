import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/signer/const/constants.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/wallet/keys.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/signing.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/bitcoin/transaction/types/types.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

mixin BitcoinTransactionSignerController on DisposableMixin {
  WalletProvider get walletProvider;
  WalletBitcoinNetwork get network;

  Future<BitcoinSignedTransactionBuilder> signTransactionInternal(
      {required BasedBitcoinTransacationBuilder transaction,
      required List<IBitcoinAddress> signers,
      bool fakeSignature = false}) async {
    if (fakeSignature) {
      final fakeSchnorSignaturBytes = '01' * CryptoSignerConst.schnoorSginatureLength;
      final fakeDerSignature = '01' * 72;
      final btcTransaction =
          transaction.buildTransaction((trDigest, utxo, multiSigPublicKey, int sighash) {
        if (utxo.utxo.isP2tr) {
          if (sighash != BitcoinOpCodeConst.sighashDefault) {
            return '${fakeSchnorSignaturBytes}01';
          }
          return fakeSchnorSignaturBytes;
        } else {
          return fakeDerSignature;
        }
      });
      return BitcoinSignedTransactionBuilder(transaction: btcTransaction, signatures: []);
    } else {
      List<List<int>> signatures = [];
      final request = WalletSigningRequest(
        addresses: signers,
        network: network,
        sign: (generateSignature) async {
          return transaction
              .buildTransactionAsync((trDigest, utxo, publicKey, sighash) async {
            final account = signers
                .whereType<IBitcoinAddress>()
                .firstWhere((element) => element.signers.contains(publicKey));
            DerivationIndex keyIndex = account.derivationIndex;
            if (account.multiSigAccount) {
              final multiSignatureAddress =
                  (account as BitcoinMultiSigBase).multiSignatureAddress;
              final correctSigner = multiSignatureAddress.signers
                  .firstWhere((element) => element.publicKey == publicKey);
              keyIndex = correctSigner.derivationIndex;
            }
            final bitcoinSigning = BitcoinSigning(
                digest: trDigest,
                index: keyIndex.cast(),
                useTaproot: utxo.utxo.isP2tr,
                sighash: sighash,
                useBchSchnorr: false,
                signingMode: network.coinParam.isBCH
                    ? SigningRequestMode.bitcoinCash
                    : SigningRequestMode.bitcoin);
            final sig = await generateSignature(bitcoinSigning);
            signatures.add(sig.signature);
            return BytesUtils.toHexString(sig.signature);
          });
        },
      );
      final btcTransaction = await walletProvider.wallet
          .signTransaction(params: WalletActionSign(request: request));
      return BitcoinSignedTransactionBuilder(
          transaction: btcTransaction.unwrap(), signatures: []);
    }
  }

  Future<BitcoinSignedPsbt> signPsbtTransaction(
      {required PsbtBuilder psbt,
      required List<IBitcoinAddress> signers,
      required List<BitcoinPsbtInputWithAccount> accountInputs,
      bool fakeSignature = false}) async {
    final List<List<int>> signatures = [];
    final signingRequest = WalletSigningRequest(
      addresses: signers,
      network: network,
      sign: (generateSignature) async {
        for (int i = 0; i < accountInputs.length; i++) {
          final input = accountInputs[i];
          final inputData = psbt.psbtInput(input.index);
          int? sighash = inputData.sigHashType?.sighash;
          if (sighash == null && network.type == NetworkType.bitcoinCash) {
            sighash = BitcoinOpCodeConst.sighashForked | BitcoinOpCodeConst.sighashAll;
          } else {
            sighash = null;
          }
          await psbt.signInputAsync(
              index: input.index,
              sighashType: sighash,
              signer: (params) async {
                final account = input.ownerAddress!;
                if (account.multiSigAccount) {
                  final multsigAccount = account as BitcoinMultiSigBase;
                  final signers = multsigAccount.multiSignatureAddress.signers
                      .map((e) => BitcoonPsbtSigner(
                            publicKey: ECPublic.fromHex(e.publicKey),
                            signer: (params) async {
                              final bitcoinSigning = BitcoinSigning(
                                  digest: params.digest,
                                  index: e.derivationIndex.cast(),
                                  useBchSchnorr: false,
                                  useTaproot: account.networkAddress.type.isP2tr,
                                  sighash: params.sighash,
                                  signingMode: network.type == NetworkType.bitcoinCash
                                      ? SigningRequestMode.bitcoinCash
                                      : SigningRequestMode.bitcoin);
                              final sig = await generateSignature(bitcoinSigning);
                              signatures.add(sig.signature);
                              return sig.signature;
                            },
                          ))
                      .toList();
                  return PsbtSignerResponse(signers: signers);
                }
                final signer = BitcoonPsbtSigner(
                  publicKey: ECPublic.fromBytes(account.publicKey),
                  signer: (p) async {
                    final bitcoinSigning = BitcoinSigning(
                        digest: p.digest,
                        index: account.derivationIndex.cast(),
                        useBchSchnorr: false,
                        useTaproot: account.networkAddress.type.isP2tr,
                        sighash: p.sighash,
                        signingMode: network.type == NetworkType.bitcoinCash
                            ? SigningRequestMode.bitcoinCash
                            : SigningRequestMode.bitcoin);
                    final sig = await generateSignature(bitcoinSigning);
                    signatures.add(sig.signature);
                    return sig.signature;
                  },
                );
                return PsbtSignerResponse(signers: [signer]);
              });
          psbt.finalizeInput(i);
        }
        return psbt;
      },
    );
    final signedTransaction = await walletProvider.wallet
        .signTransaction(params: WalletActionSign(request: signingRequest));
    return BitcoinSignedPsbt(
        signatures: signatures, psbt: signedTransaction.unwrap().toBase64());
  }
}
