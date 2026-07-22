import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/networks/ripple/ripple.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/ripple/client/ripple.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:xrpl_dart/xrpl_dart.dart';

mixin XRPTransactionApiController on DisposableMixin {
  XRPNetworkClient get client;
  final CachedObject<int> _accountSequence =
      CachedObject(interval: const Duration(minutes: 2));
  final CachedObject<int> _ledgerOffset =
      CachedObject(interval: const Duration(minutes: 2));

  Future<int> getAccountSequence(XRPBaseAddress address) async {
    return _accountSequence.get(onFetch: () async {
      final sequence = await client.getAccountSequence(address);
      return sequence.toInt();
    });
  }

  Future<int> getTransactionLastLedgerIndex() async {
    return _ledgerOffset.get(onFetch: () async {
      final index = await client.getLedgerIndex();
      return index + 100;
    });
  }

  Future<FeeResult> getFeeData() {
    return client.getFeeData();
  }

  Future<void> checkAccountPermission(IXRPAddress address) async {
    final info = await client.getAccountInfo(address.networkAddress.toString());
    if (info == null) {
      throw AppException("account_not_found");
    }
    final String? regularKey = info.accountData.regularKey;
    final disableMasterKey = info.accountFlags?.disableMasterKey ?? false;
    if (!address.multiSigAccount) {
      if (disableMasterKey) throw AppException("disable_master_key_addr");
      return;
    }
    final multiSignatureAccount = (address as IXRPMultisigAddress).multiSignatureAccount;
    if (multiSignatureAccount.isRegular) {
      final multisigRegularAddress = RippleUtils.strPublicKeyToRippleAddress(
          multiSignatureAccount.signers.first.publicKey);
      if (multisigRegularAddress.classicAddress == regularKey) return;
      throw AppException("ripple_account_signature_updated_desc");
    }
    final accountSigners =
        await client.getAccountSignerList(address.networkAddress.classicAddress);
    if (accountSigners != null && accountSigners.signerEntries.isNotEmpty) {
      int threshHold = 0;
      final List<String> addressSigners = multiSignatureAccount.signers
          .map((e) => RippleUtils.strPublicKeyToRippleAddress(e.publicKey).classicAddress)
          .toList();
      for (final i in addressSigners) {
        final inSignerList = accountSigners.signerEntries
            .firstWhereOrNull((element) => element.account == i);
        if (inSignerList == null) continue;
        threshHold += inSignerList.signerWeight;
      }
      if (threshHold >= accountSigners.signerQuorum) return;
    }
    throw AppException("ripple_account_signature_updated_desc");
  }

  Future<int?> getNetworkId() async {
    return await client.provider.inner.getTransactionNetworkId();
  }

  Future<SubmittableTransaction> filledTransactionRequirment(
      SubmittableTransaction transaction,
      {bool force = true}) async {
    if (transaction.networkId == null || force) {
      final networkId = await getNetworkId();
      transaction.setNetworkId(networkId);
    }
    if (transaction.ticketSequance == null || force) {
      final accountSequence =
          await getAccountSequence(XRPBaseAddress(transaction.account));
      transaction.setSequence(accountSequence);
    }
    final ledgerOffset = await getTransactionLastLedgerIndex();
    transaction.setLastLedgerSequence(ledgerOffset);
    return transaction;
  }

  Future<SubmitResult> broadcastTransaction(SubmittableTransaction transaction) async {
    final txResult = await client.provider
        .request(XRPRequestSubmit(txBlob: transaction.toTransactionBlob()));
    return txResult;
  }
}
