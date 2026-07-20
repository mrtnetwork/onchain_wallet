import 'dart:async';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain/ada/ada.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/signing.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/web3/web3.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/web3.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/cardano/client/cardano.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/others/models/receipt_address.dart';
import 'package:on_chain_wallet/wallet/models/signing/signing.dart';
import 'package:on_chain_wallet/wallet/models/transaction/core/transaction.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/ada.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/cardano.dart';

class WebCardanoSignTransactionStateController
    extends Web3CardanoTransactionStateController<Web3ADASignTransactionsResponse,
        Web3ADASignTransaction> {
  @override
  bool get showRequestAccount => false;
  IWeb3ADATransactionData? _transactionData;
  IWeb3ADATransactionData get transactionData => _transactionData!;
  WebCardanoSignTransactionStateController(
      {required super.walletProvider, required super.request});

  @override
  Future<IWeb3ADATransaction> buildTransaction({bool simulate = false}) async {
    return IWeb3ADATransaction(
        account: defaultAccount,
        transactionData: transactionData,
        transactions: transactionData.transactions.map((e) => e.transaction).toList());
  }

  Set<NativeScript> buildNativeScripts({required List<ADAAddress> addresses}) {
    Set<NativeScript> scripts = {};
    for (final i in addresses) {
      final address = accounts.firstWhere(
          (e) => e.networkAddress == i || e.rewardAddress == i,
          orElse: () => throw WalletExceptionConst.signerAccountNotFound);
      bool isRewardOfBaseAddress = address.rewardAddress == i;
      if (!address.multiSigAccount) continue;
      final mAccount = address as ICardanoMultiSigAddress;
      final BaseCardanoMultiSignatureCredential? cred = switch (isRewardOfBaseAddress) {
        true => mAccount.addressInfo.stakeCredential,
        false => mAccount.addressInfo.credential
      };
      if (cred == null) {
        throw WalletExceptionConst.invalidAccountData("buildNativeScripts");
      }
      if (cred.type == CardanoCredentialType.script) {
        final script = cred as CardanoMultiSignatureScript;
        scripts.add(script.script);
      }
    }
    return scripts;
  }

  Web3ADATransactionSigner? findSignerFromCredential(Credential credential) {
    for (int i = 0; i < params.requiredAccounts.length; i++) {
      final account = accounts[i];
      if (account.networkAddress.isByron) continue;
      final address = account.networkAddress.cast<ADAShellyAddress>();
      final web3Account = params.requiredAccounts[i];
      if (web3Account.isRewardAddress) {
        if (account.isBaseAddress) {
          if (account.rewardAddress!.paymentCredential == credential) {
            return Web3ADATransactionSigner(
                address: account,
                signMode: Web3ADATransactionSigningMode.reward,
                signer: ReceiptAddress(
                    view: account.rewardAddress!.address,
                    networkAddress: account.rewardAddress!,
                    account: account));
          }
        } else if (account.isRewardAddress) {
          if (address.paymentCredential == credential) {
            return Web3ADATransactionSigner(
                address: account,
                signMode: Web3ADATransactionSigningMode.payment,
                signer: ReceiptAddress(
                    view: address.address, networkAddress: address, account: account));
          }
        }
      } else {
        if (!account.isRewardAddress && address.paymentCredential == credential) {
          return Web3ADATransactionSigner(
              address: account,
              signMode: Web3ADATransactionSigningMode.payment,
              signer: ReceiptAddress(
                  view: address.address, networkAddress: address, account: account));
        }
      }
    }
    return null;
  }

  Web3ADATransactionSigner? findSignerRewardAddress(ADARewardAddress address) {
    for (int i = 0; i < params.requiredAccounts.length; i++) {
      final account = accounts[i];
      if (account.networkAddress.isByron) continue;
      final web3Account = params.requiredAccounts[i];
      if (!web3Account.isRewardAddress) continue;
      if (account.isBaseAddress) {
        if (account.rewardAddress == address) {
          return Web3ADATransactionSigner(
              address: account,
              signMode: Web3ADATransactionSigningMode.reward,
              signer: ReceiptAddress(
                  view: account.rewardAddress!.address,
                  networkAddress: account.rewardAddress!,
                  account: account));
        }
      } else if (account.isRewardAddress) {
        if (account.networkAddress == address) {
          return Web3ADATransactionSigner(
              address: account,
              signMode: Web3ADATransactionSigningMode.payment,
              signer: ReceiptAddress(
                  view: account.rewardAddress!.address,
                  networkAddress: account.rewardAddress!,
                  account: account));
        }
      }
    }
    return null;
  }

  Web3ADATransactionSigner? findSignerFromPolicyId(PolicyID policyId) {
    // Web3ADATransactionSigner? signer;
    for (int i = 0; i < params.requiredAccounts.length; i++) {
      final account = accounts[i];
      if (account.networkAddress.isByron) continue;
      final web3Account = params.requiredAccounts[i];
      if (web3Account.isRewardAddress) {
        if (account.isBaseAddress) {
          if (account.addressInfo.stakePolicyId == policyId) {
            return Web3ADATransactionSigner(
                address: account,
                signMode: Web3ADATransactionSigningMode.reward,
                signer: ReceiptAddress(
                    view: account.rewardAddress!.address,
                    networkAddress: account.rewardAddress!,
                    account: account));
          }
        } else if (account.isRewardAddress) {
          if (account.addressInfo.policyId == policyId) {
            return Web3ADATransactionSigner(
                address: account,
                signMode: Web3ADATransactionSigningMode.payment,
                signer: ReceiptAddress(
                    view: account.networkAddress.address,
                    networkAddress: account.networkAddress,
                    account: account));
          }
        }
      } else {
        if (!account.isRewardAddress && account.addressInfo.policyId == policyId) {
          return Web3ADATransactionSigner(
              address: account,
              signMode: Web3ADATransactionSigningMode.payment,
              signer: ReceiptAddress(
                  view: account.networkAddress.address,
                  networkAddress: account.networkAddress,
                  account: account));
        }
      }
    }
    return null;
  }

  List<Web3ADATransactionSigner?> findCertificateSigners(Certificate certificate) {
    List<Web3ADATransactionSigner?> signers = [];
    final credential = certificate.signersCredential;
    for (final i in credential) {
      signers.add(findSignerFromCredential(i));
    }
    return signers;
  }

  Future<Web3ADATransactionData> parseTx({
    required ADATransaction transaction,
    required bool partialSign,
    List<CardanoAccountUtxo> prevUtxos = const [],
  }) async {
    final utxos = [
      ...(await Future.wait(accounts.map((e) => getAccountUtxos(account, e))))
          .expand((e) => e),
      ...prevUtxos
    ];
    final txInputs = transaction.body.inputs?.inputs ?? [];
    final collateral = transaction.body.collateral?.inputs ?? [];
    final reference = transaction.body.referenceInputs?.inputs ?? [];
    final returnCollateral = transaction.body.collateralReturn;
    final withdrawals = transaction.body.withdrawals;
    final mint = transaction.body.mint;
    final votes = transaction.body.votingProcedures;
    final requiredSignatures = transaction.body.requiredSigners?.outputs
        .map((e) => findSignerFromCredential(CredentialKey(e.data)))
        .toList()
        .emptyAsNull;
    final txOutputs = [
      ...transaction.body.outputs?.outputs ?? [],
      if (returnCollateral != null) returnCollateral
    ];

    List<Web3ADAOutputDetails> outputs = txOutputs.indexed
        .map(
          (e) => Web3ADAOutputDetails(
              outputType: Web3ADAOutputType.output,
              plutusData: e.$2.plutusData?.toJson(),
              scriptRef: e.$2.scriptRef?.toJson(),
              output: e.$2,
              index: e.$1,
              address: getOrCreateAddressInfo(e.$2.address),
              lovelace: IntegerBalance.token(e.$2.amount.coin, network.token),
              assets: extractMultiAssetAssets(e.$2.amount.multiAsset),
              account:
                  accounts.firstWhereNullable((i) => i.networkAddress == e.$2.address)),
        )
        .toList();

    final metadata = transaction.data?.metadata?.metadata.map((k, v) => MapEntry(
        k,
        v.toJsonSchema(
            config: const MetadataSchemaConfig(
                jsonSchema: MetadataJsonSchema.basicConversions))));
    final nativeScripts =
        transaction.data?.nativeScripts?.map((e) => e.toJson()).toList();
    final plutusScripts =
        transaction.data?.plutusScripts?.map((e) => e.toJson()).toList();
    final certificates = transaction.body.certificates?.certificates
        .map((e) {
          final requiredSigners = findCertificateSigners(e);
          final signers = requiredSigners.whereType<Web3ADATransactionSigner>().toList();
          return Web3ADACeriticateDatails(
              type: e.type,
              content: e.toJson(),
              signers: signers,
              allowSign: requiredSigners.length == signers.length);
        })
        .toList()
        .emptyAsNull;

    List<Web3ADAInputDetails> inputs =
        [...txInputs, ...reference, ...collateral].map((i) {
      final utxo = utxos.firstWhereNullable((e) =>
          StringUtils.hexEqual(e.utxo.input.txIdHex, i.txIdHex) &&
          e.utxo.input.index == i.index);
      return Web3ADAInputDetails(
          utxo: utxo,
          assets: extractMultiAssetAssets(utxo?.multiAsset),
          input: i,
          inputType: Web3ADAInputType.input,
          bulkPrevInput: prevUtxos.contains(utxo));
    }).toList();
    final relatedInputs = inputs.where((e) => e.utxo != null).toList();
    final Map<ICardanoAddress, List<Web3ADAInputDetails>> accountInputs = {};
    for (final i in relatedInputs) {
      accountInputs[i.utxo!.address] ??= [];
      accountInputs[i.utxo!.address]!.add(i);
    }
    final totalAccountsInputs = accountInputs.entries.map((v) {
      Map<ADAAssetToken, IntegerBalance> assets = {};
      for (final i in v.value) {
        for (final a in i.assets) {
          assets[a.token] ??= IntegerBalance.zero(a.token.token);
          assets[a.token]!.addAmount(a.amount.balance);
        }
      }
      return Web3ADAAccountInputDetails(
          inputs: inputs,
          address: v.key,
          totalLovelace: IntegerBalance.token(
              v.value
                  .fold<BigInt>(BigInt.zero, (p, c) => p + c.utxo!.utxoBalance.balance),
              network.token),
          totalAssets: assets.entries
              .map((e) => Web3ADAAssetInputDetails(amount: e.value, token: e.key))
              .toList());
    }).toList();

    List<Web3ADAAssetInputMintDetails>? mintInfos = mint?.mints
        .map((e) => Web3ADAAssetInputMintDetails(
            assets: extractMultiAssetAssets(e.multiAsset),
            signer: findSignerFromPolicyId(e.policyID),
            policyId: e.policyID.toHex()))
        .toList()
        .emptyAsNull;
    final withdrawalsEntries = withdrawals?.withdrawals.entries ?? [];
    List<Web3ADAWithdrawalDetails> withdrawalsInfos = withdrawalsEntries
        .map((e) => Web3ADAWithdrawalDetails(
            amount: IntegerBalance.token(e.value, network.token),
            signer: findSignerRewardAddress(e.key),
            address: getOrCreateAddressInfo(e.key)))
        .toList();
    final List<Web3ADAVoteDetails>? votesInfo = votes?.votes.entries
        .map((e) => Web3ADAVoteDetails(
            type: e.key.type,
            signer: findSignerFromCredential(e.key.signersCredential),
            content: e.value.entries
                .map((e) => {...e.key.toJson(), ...e.value.toJson()})
                .toList()))
        .toList()
        .emptyAsNull;

    return Web3ADATransactionData(
        fee: ADATransactionFee(
            type: TxFeeTypes.manually,
            fee: IntegerBalance.token(transaction.body.fee, network.token)),
        inputs: inputs,
        outputs: outputs,
        certificates: certificates,
        mintInfos: mintInfos,
        metadata: metadata,
        nativeScripts: nativeScripts,
        plutusScripts: plutusScripts,
        totalAccountsInputs: totalAccountsInputs,
        transaction: transaction,
        withdrawals: withdrawalsInfos.nullOnEmoty,
        content: transaction.toJson(),
        votes: votesInfo,
        partialSign: partialSign,
        requiredSignatures: requiredSignatures,
        txId: transaction.body.toHash().toHex());
  }

  @override
  Future<IWeb3ADATransactionData> buildTransactionData({bool simulate = false}) async {
    return _transactionData ??= await () async {
      List<CardanoAccountUtxo> prevUtxos = [];
      List<Web3ADATransactionData> txsData = [];

      for (final i in params.transactions) {
        final txId = i.transaction.body.toHash().data;
        final txData = await parseTx(
            transaction: i.transaction, partialSign: i.partialSign, prevUtxos: prevUtxos);
        final relatedOutputs = txData.outputs
            .map((e) => e.utxo(txId: txId, network: network))
            .whereType<CardanoAccountUtxo>();
        prevUtxos
            .removeWhere((p) => relatedOutputs.any((e) => e.utxo.input == p.utxo.input));
        prevUtxos.addAll(relatedOutputs);
        txsData.add(txData);
      }
      return IWeb3ADATransactionData(transactions: txsData);
    }();
  }

  @override
  Future<List<IWalletTransaction<ADAWalletTransaction, ICardanoAddress>>>
      buildWalletTransaction(
          {required IWeb3ADASignedTransaction signedTx,
          required SubmitTransactionSuccess<IWeb3ADASignedTransaction>? txId}) async {
    final tx = signedTx.transaction.transactionData.transactions
        .firstWhereOrNull((e) => e.txId == txId?.txId);

    if (tx == null) return [];
    final related = tx.totalAccountsInputs;

    if (related.isEmpty) return [];
    List<IWalletTransaction<ADAWalletTransaction, ICardanoAddress>> txes = [];
    for (final i in related) {
      final adaTx = ADAWalletTransaction(
          txId: tx.txId,
          web3Client: web3ClientInfo(),
          type: WalletTransactionType.web3,
          totalOutput: WalletTransactionIntegerAmount(
              amount: i.totalLovelace.balance, network: network),
          network: network);
      txes.add(IWalletTransaction(transaction: adaTx, account: i.address));
    }
    return txes;
  }

  Future<SubmitTransactionResult> submitTransactionInternal(
      {required IWeb3ADASignedTransaction signedTransaction,
      required ADATransaction transaction}) async {
    final txId = await IResult.call(() async {
      final ser = transaction.serialize();
      final txId = await client.broadcastTransaction(ser);
      return txId;
    });

    if (txId.isErr) {
      if (params.method != Web3ADARequestMethods.submitTxs) {
        txId.unwrap();
      }
      return SubmitTransactionFailed(txId.unwrapErr().localizationError);
    }
    return SubmitTransactionSuccess(
        txId: txId.unwrap(), signedTransaction: signedTransaction);
  }

  @override
  Future<
      Web3RequestTransactionResponseData<Web3ADASignTransactionsResponse,
          SubmitTransactionSuccess<IWeb3ADASignedTransaction>>> getResponse() async {
    switch (params.method) {
      case Web3ADARequestMethods.submitTx:
      case Web3ADARequestMethods.submitTxs:
      case Web3ADARequestMethods.signAndSendTransaction:
      case Web3ADARequestMethods.submitUnsignedTx:
        List<Web3ADASignTransactionResponse> txResponse = [];
        List<SubmitTransactionResult> txIds = [];
        final transaction = await buildTransaction();
        final signTransactions = await signTransaction(transaction);
        for (final i in signTransactions.finalTransactionData) {
          final result = await submitTransactionInternal(
              signedTransaction: signTransactions, transaction: i);
          txIds.add(result);
          final response = Web3ADASignTransactionResponse(
              txId: i.body.toHash().toHex(),
              witness: i.witnessSet,
              error: result.status.isFailed
                  ? result.cast<SubmitTransactionFailed>().error
                  : null);
          txResponse.add(response);
        }
        return Web3RequestTransactionResponseData.submitTx(
            response: Web3ADASignTransactionsResponse(witnesses: txResponse),
            txIds: txIds);
      default:
        final transaction = await buildTransaction();
        final signTx = await signTransaction(transaction);
        return Web3RequestTransactionResponseData(
          response: Web3ADASignTransactionsResponse(
              // txId: signTx.finalTransactionData.body.toHash().toHex(),
              witnesses: signTx.finalTransactionData
                  .map((e) => Web3ADASignTransactionResponse(
                      txId: e.body.toHash().toHex(), witness: e.witnessSet, error: null))
                  .toList()),
        );
    }
  }

  Future<ADATransaction> _signTransactionInternal<T>(
      {required Web3ADATransactionData transaction,
      required OnSignRequest generateSignature}) async {
    final witnessSet = transaction.transaction.witnessSet;
    final body = transaction.transaction.body;
    final digest = body.toHash().data.asImmutableBytes;
    List<List<int>> signatures = [];
    final signersAddresses =
        transaction.signers.map((e) => e.signer.networkAddress).toList();
    final signers = transaction.signers.map((e) => e.address).toList();
    final witness = await () async {
      final witnesses = <ADABaseTransactionWitness>[];
      for (final address in signersAddresses) {
        Future<List<ADABaseTransactionWitness>> createWitnessasync() async {
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
              throw WalletExceptionConst.invalidAccountData("_signTransactionInternal");
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
        }

        final wintess = await createWitnessasync();
        witnesses.addAll(wintess);
      }
      final vkeys = witnesses.whereType<Vkeywitness>().toSet().toList();
      final bootstraps = witnesses.whereType<BootstrapWitness>().toSet().toList();
      return TransactionWitnessSet(
          vKeys: vkeys.isEmpty ? null : VkeyWitnesses(vkeys),
          bootstraps: bootstraps.isEmpty ? null : BootstrapWitnesses(bootstraps));
    }();

    final scripts = <NativeScript>{
      ...buildNativeScripts(addresses: signersAddresses),
      ...witnessSet.nativeScripts?.scripts ?? []
    };
    final bootstraps = {
      ...witness.bootstraps?.witnesses ?? [],
      ...witnessSet.bootstraps?.witnesses ?? [],
    };
    final vkey = {
      ...witness.vKeys?.witnesses ?? [],
      ...witnessSet.vKeys?.witnesses ?? []
    };
    final newWitness = TransactionWitnessSet(
        nativeScripts: scripts.isEmpty ? null : NativeScripts(scripts.toList()),
        bootstraps: bootstraps.isEmpty ? null : BootstrapWitnesses(bootstraps.toList()),
        vKeys: vkey.isEmpty ? null : VkeyWitnesses(vkey.toList()),
        plutusData: witnessSet.plutusData,
        plutusScriptsV1: witnessSet.plutusScriptsV1,
        plutusScriptsV2: witnessSet.plutusScriptsV2,
        plutusScriptsV3: witnessSet.plutusScriptsV3,
        redeemers: witnessSet.redeemers);
    return transaction.transaction.copyWith(witnessSet: newWitness);
  }

  @override
  Future<IWeb3ADASignedTransaction> signTransaction(IWeb3ADATransaction transaction,
      {bool fakeSignature = false}) async {
    switch (params.method) {
      case Web3ADARequestMethods.submitTx:
      case Web3ADARequestMethods.submitTxs:
        return IWeb3ADASignedTransaction(
            transaction: transaction,
            signatures: [],
            finalTransactionData: transaction.transactions);
      default:
        break;
    }

    final signedTransaction = await walletProvider.wallet.signTransaction(
        params: WalletActionSign(
            request: WalletSigningRequest(
                addresses: transaction.transactionData.transactions
                    .expand((e) => e.signers)
                    .map((e) => e.address)
                    .toSet()
                    .toList(),
                network: network,
                sign: (generateSignature) async {
                  List<ADATransaction> signedTransaction = [];
                  for (final i in transaction.transactionData.transactions) {
                    final signedTx = await _signTransactionInternal(
                        transaction: i, generateSignature: generateSignature);
                    signedTransaction.add(signedTx);
                  }
                  return signedTransaction;
                })));
    return IWeb3ADASignedTransaction(
        transaction: transaction,
        signatures: [],
        finalTransactionData: signedTransaction.unwrap());
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return Web3CardanoSignTransactionStateView(this);
  }

  @override
  Future<void> initForm(ADANetworkClient client) async {
    await super.initForm(client);
    _transactionData = await buildTransactionData();
    if (params.method == Web3ADARequestMethods.submitTx ||
        params.method == Web3ADARequestMethods.submitTxs) {
      return;
    }
    for (final i in transactionData.transactions) {
      if (!i.partialSign && !i.canFullySign) {
        throw Web3ADAExceptionConstant.unableToSignTransactionAsNonPartial;
      }
    }
  }

  @override
  Future<SubmitTransactionResult> submitTransaction(
      {required IWeb3ADASignedTransaction signedTransaction}) {
    throw UnimplementedError();
  }
}
