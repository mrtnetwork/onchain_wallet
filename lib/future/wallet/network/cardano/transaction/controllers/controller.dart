import 'dart:async';

import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/signing.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/transaction/controllers/memo.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

import 'certificate.dart';
import 'fee.dart';
import 'provider.dart';
import 'utxos.dart';

abstract class ADATransactionStateController extends BaseADATransactionController
    with
        ADATransactionApiController,
        ADATransactionFeeController,
        ADATransactionUtxosController,
        ADATransactionMemoController,
        ADATransactionCertificateController {
  Token get transferToken;
  late final ADAEpochParametersResponse _latestEpochParams;
  @override
  ADAEpochParametersResponse get latestEpochParams => _latestEpochParams;

  ADATransactionStateController(
      {required super.walletProvider, required super.account, required super.address});

  @override
  Future<IADASignedTransaction> signTransaction(IADATransaction transaction,
      {bool fakeSignature = false}) async {
    final signersAddresses = transaction.transaction.signers.immutable;
    final signers = List.generate(signersAddresses.length, (i) {
      final signer = signersAddresses[i];
      return account.addresses.firstWhere((e) {
        return e.networkAddress == signer || e.rewardAddress == signer;
      }, orElse: () => throw WalletExceptionConst.signerAccountNotFound);
    });
    List<List<int>> signatures = [];
    if (fakeSignature) {
      final fakeWitness = ADATransactionBuilderUtils.fakeVkeyWitnessWitness();
      BootstrapWitness? fakebootstrap;
      final adaTransaction = transaction.transaction.buildEstimateTx(
        ({required address, required digest}) {
          final signer = signers.firstWhere(
              (e) => e.networkAddress == address || e.rewardAddress == address,
              orElse: () => throw WalletExceptionConst.signerAccountNotFound);
          if (signer.multiSigAccount) {
            final mAccount = signer as ICardanoMultiSigAddress;
            bool isRewardOfBaseAddress = mAccount.rewardAddress == address;
            final BaseCardanoMultiSignatureCredential? cred = switch (
                isRewardOfBaseAddress) {
              true => mAccount.addressInfo.stakeCredential,
              false => mAccount.addressInfo.credential
            };
            if (cred == null) {
              throw WalletExceptionConst.invalidAccountData("signTransaction");
            }
            List<Vkeywitness> witnesses = [];
            for (int i = 0; i <= cred.threshold; i++) {
              signatures.add(fakeWitness.signature.data);
              witnesses.add(fakeWitness);
              if (witnesses.length >= cred.threshold) break;
            }
            return witnesses;
          }
          if (address.isByron) {
            fakebootstrap ??=
                ADATransactionBuilderUtils.fakeBootStrapWitness(address.cast());
            return [fakebootstrap!];
          }
          return [fakeWitness];
        },
      );
      return IADASignedTransaction(
          transaction: transaction,
          signatures: signatures,
          finalTransactionData: adaTransaction);
    }

    final adaTransaction = await walletProvider.wallet.signTransaction(
        params: WalletActionSign(
            request: WalletSigningRequest(
      addresses: signers,
      network: network,
      sign: (generateSignature) {
        return transaction.transaction.signAndBuildTransactionAsync(
          ({required address, required digest}) async {
            final signer = signers.firstWhere(
                (e) => e.networkAddress == address || e.rewardAddress == address,
                orElse: () => throw WalletExceptionConst.signerAccountNotFound);
            bool isRewardOfBaseAddress = signer.rewardAddress == address;

            if (signer.multiSigAccount) {
              final mAccount = signer as ICardanoMultiSigAddress;

              final BaseCardanoMultiSignatureCredential? cred = switch (
                  isRewardOfBaseAddress) {
                true => mAccount.addressInfo.stakeCredential,
                false => mAccount.addressInfo.credential
              };
              if (cred == null) {
                throw WalletExceptionConst.invalidAccountData("signTransaction");
              }
              final indexes = cred.keyIndexes;
              List<Vkeywitness> witnesses = [];
              for (final i in indexes) {
                final signRequest =
                    GlobalSignRequest.cardano(digest: digest, index: i.cast());
                final sig = await generateSignature(signRequest);
                final pubkey = AdaPublicKey.fromBytes(sig.signerPubKey.keyBytes());
                final ed25519Signature = Ed25519Signature(sig.signature);
                signatures.add(sig.signature);
                witnesses.add(Vkeywitness(
                    vKey: pubkey.toVerificationKey(), signature: ed25519Signature));
                if (witnesses.length >= cred.threshold) break;
              }
              return witnesses;
            }
            final keyIndex =
                isRewardOfBaseAddress ? signer.rewardKeyIndex! : signer.derivationIndex;
            final signRequest =
                GlobalSignRequest.cardano(digest: digest, index: keyIndex.cast());
            final sig = await generateSignature(signRequest);
            signatures.add(sig.signature);
            final pubkey = AdaPublicKey.fromBytes(sig.signerPubKey.keyBytes());
            final ed25519Signature = Ed25519Signature(sig.signature);
            if (address.isByron) {
              return [
                BootstrapWitness(
                    vkey: Vkey(pubkey.toBytes(false)),
                    signature: ed25519Signature,
                    chainCode: sig.signerPubKey.chainCodeBytes()!,
                    attributes: address.cast<ADAByronAddress>().attributeSerialize())
              ];
            }
            return [
              Vkeywitness(vKey: pubkey.toVerificationKey(), signature: ed25519Signature)
            ];
          },
        );
      },
    )));
    return IADASignedTransaction(
        transaction: transaction,
        signatures: signatures,
        finalTransactionData: adaTransaction.unwrap());
  }

  @override
  Future<SubmitTransactionResult> submitTransaction(
      {required IADASignedTransaction signedTransaction}) async {
    final ser = signedTransaction.finalTransactionData.serialize();
    final txId = await client.broadcastTransaction(ser);
    return SubmitTransactionSuccess(txId: txId, signedTransaction: signedTransaction);
  }

  @override
  Future<TransactionStateController> initForm({
    required BuildContext context,
    required ADANetworkClient client,
    bool updateAccount = true,
    bool updateTokens = false,
  }) async {
    await super.initForm(context: context, client: client, updateAccount: updateAccount);
    _latestEpochParams = await latestEpochProtocolParameters();
    await initUtxos();
    return this;
  }
}
