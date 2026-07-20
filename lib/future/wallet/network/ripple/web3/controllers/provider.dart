import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/networks/ripple/ripple.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/web3/types/types.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant.dart';
import 'package:on_chain_wallet/web3/web3/networks/ripple/methods/methods.dart';
import 'package:xrpl_dart/xrpl_dart.dart';

mixin XRPWeb3TransactionApiController on DisposableMixin {
  XRPNetworkClient get client;

  Future<XRPAccountInfo> getWeb3TransactionAccountInfo(
      ReceiptAddress<XRPBaseAddress> address) async {
    final info = await client.getAccountInfo(address.networkAddress.classicAddress);
    if (info == null) {
      throw Web3RequestExceptionConst.inactiveAccount;
    }

    final accountSigners =
        await client.getAccountSignerList(address.networkAddress.classicAddress);
    final String? regularKey = info.accountData.regularKey;
    return XRPAccountInfo(
        enableMasterKey: !(info.accountFlags?.disableMasterKey ?? false),
        regularKey: regularKey == null ? null : XRPBaseAddress(regularKey),
        accountSigners: accountSigners,
        owner: address);
  }

  XRPWeb3SigningMode? canSignTransaction({
    required XRPAccountInfo owner,
    required IXRPAddress address,
    required Web3XRPRequestMethods method,
  }) {
    if (owner.owner.networkAddress.classicAddress ==
        address.networkAddress.classicAddress) {
      if (owner.enableMasterKey) return XRPWeb3SigningMode.full;
      if (!address.multiSigAccount) return null;
      final msig = (address as IXRPMultisigAddress).multiSignatureAccount;
      final List<XRPBaseAddress> addressSigners = msig.signers
          .map((e) => RippleUtils.strPublicKeyToRippleAddress(e.publicKey))
          .toList();
      if (msig.isRegular) {
        if (owner.regularKey == addressSigners.firstOrNull) {
          return XRPWeb3SigningMode.full;
        }
        return null;
      }
      final accountSigners = owner.accountSigners;
      if (accountSigners == null) return null;
      int threshHold = 0;
      for (final i in addressSigners) {
        final inSignerList = accountSigners.signerEntries
            .firstWhereOrNull((element) => element.account == i.classicAddress);
        if (inSignerList == null) continue;
        threshHold += inSignerList.signerWeight;
      }
      if (threshHold >= accountSigners.signerQuorum) {
        return XRPWeb3SigningMode.full;
      }

      return null;
    }

    if (method == Web3XRPRequestMethods.sendTransaction) {
      return null;
    }
    if (address.multiSigAccount) return null;
    return XRPWeb3SigningMode.part;
  }

  Future<XRPWeb3TransactionInfoPayment?> _getWeb3TransactionPaymentInfo({
    required Payment paymet,
    required XRPChain account,
    required IXRPAddress address,
  }) async {
    final tokens = (await address.getAccountTokens()).unwrap();
    final nAddress = XRPBaseAddress(paymet.destination);
    final recipient = account.getOrCreateReceiptFromNetworkAddressSync(address: nAddress);
    switch (paymet.amount.type) {
      case AmountType.native:
        return XRPWeb3TransactionInfoPayment(
            recipient: recipient,
            amount: IntegerBalance.token(
                (paymet.amount as XRPAmount).value, account.network.token));
      case AmountType.issue:
        final amount = paymet.amount as IssuedCurrencyAmount;
        NonDecimalToken? token = tokens
            .firstWhereOrNull(
              (e) => e.assetCode == amount.currency && e.issuer == amount.issuer,
            )
            ?.token;
        token ??= NonDecimalToken(name: amount.currency, symbol: amount.currency);
        return XRPWeb3TransactionInfoPayment(
            recipient: recipient,
            amount: DecimalBalance.fromRational(token, amount.rational));
      default:
    }
    return null;
  }

  Future<XRPWeb3TransactionInfo?> getWeb3TransactionInfo({
    required SubmittableTransaction transaction,
    required XRPChain account,
    required IXRPAddress address,
  }) async {
    switch (transaction.transactionType) {
      case SubmittableTransactionType.payment:
        return _getWeb3TransactionPaymentInfo(
            paymet: transaction as Payment, account: account, address: address);
      default:
        return null;
    }
  }
}
