import 'package:blockchain_utils/utils/string/string.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/transaction/types/operations.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/web3/types/types.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:stellar_dart/stellar_dart.dart';

mixin StellarWeb3TransactionApiController on DisposableMixin {
  StellarClient get client;
  WalletStellarNetwork get network;

  ReceiptAddress<StellarAddress> _getOrCreateReceiptAddress(
      {required StellarAddress address, required StellarChain chain}) {
    return chain.getOrCreateReceiptFromNetworkAddressSync(address: address);
  }

  IntegerBalance? _getAssetBalance(
      {required StellarAsset asset, required StellarAccountResponse signerAccountInfo}) {
    if (asset.type == AssetType.poolShare) return null;
    if (asset.type == AssetType.native) {
      return IntegerBalance.token(signerAccountInfo.nativeBalance, network.token);
    }
    final assetBalances = signerAccountInfo.getAsset(asset);
    if (assetBalances != null) {
      return IntegerBalance.token(assetBalances.unlockedBalance, network.token);
    }
    return null;
  }

  Future<StellarWeb3TransactionDetails> getWeb3TransactionInfo(
      {required Envelope envlope,
      required StellarChain chain,
      required IStellarAddress signer,
      required StellarAccountResponse signerAccountInfo}) async {
    final tx = envlope.tx;
    final IntegerBalance fee = IntegerBalance.zero(network.token);
    final StellarTransactionV1 transaction;
    final StellarAddress source;
    StellarWeb3TransactionType type = StellarWeb3TransactionType.v1;
    if (tx.type == EnvelopeType.txFeeBump) {
      final feebumpTx = tx.cast<StellarFeeBumpTransaction>();
      transaction = feebumpTx.innerTx.tx;
      fee.updateBalance(feebumpTx.fee);
      type = StellarWeb3TransactionType.feeBump;
      source = feebumpTx.feeSource.address;
    } else {
      transaction = tx.cast<StellarTransactionV1>();
      fee.updateBalance(BigInt.from(transaction.fee));
      source = transaction.sourceAccount.address;
    }
    StellarSorobanTransactionDetais? soroban;
    if (transaction.sorobanData.sorobanTransactionData != null) {
      soroban = StellarSorobanTransactionDetais(
          sorobanData: transaction.sorobanData.sorobanTransactionData!, network: network);
    }
    final memo = StellarMemoDetils(transaction.memo);
    final List<StellarTransactionOperationDetails> baseOperation = [];
    for (final i in tx.operations) {
      final sourceAccount = i.sourceAccount?.address == null
          ? null
          : _getOrCreateReceiptAddress(address: i.sourceAccount!.address, chain: chain);
      final OperationBody body = i.body;
      final bool isSigner = signer.networkAddress.baseAddress ==
          (sourceAccount?.networkAddress.baseAddress ?? source.baseAddress);
      switch (body.operationType) {
        case OperationType.changeTrust:
          final operation = body.cast<ChangeTrustOperation>();
          final info = StellarChangeTrustOperation(
              asset: StellarPickedIssueAsset(
                asset: operation.asset,
                network: network,
                issueToken: null,
              ),
              limit: IntegerBalance.token(operation.limit, network.token));
          baseOperation.add(StellarTransactionOperationDetails(
              operation: i, operationInfo: info, sourceAccount: sourceAccount));
          break;
        case OperationType.payment:
          final operation = body.cast<PaymentOperation>();
          final info = StellarPaymentOperation(
            destination: _getOrCreateReceiptAddress(
                address: operation.destination.address, chain: chain),
            asset: StellarPickedIssueAsset(
                asset: operation.asset,
                network: network,
                issueToken: null,
                tokenBalance: isSigner
                    ? _getAssetBalance(
                        asset: operation.asset, signerAccountInfo: signerAccountInfo)
                    : null),
            amount: IntegerBalance.token(operation.amount, network.token),
          );
          baseOperation.add(StellarTransactionOperationDetails(
              operation: i, operationInfo: info, sourceAccount: sourceAccount));
          break;
        case OperationType.createAccount:
          final operation = body.cast<CreateAccountOperation>();
          final info = StellarCreateAccountOperation(
            destination: _getOrCreateReceiptAddress(
                address: operation.destination.toAddress(), chain: chain),
            asset: StellarPickedIssueAsset(
                asset: StellarAssetNative(),
                network: network,
                issueToken: null,
                tokenBalance: isSigner
                    ? _getAssetBalance(
                        asset: StellarAssetNative(), signerAccountInfo: signerAccountInfo)
                    : null),
            startingBalance:
                IntegerBalance.token(operation.startingBalance, network.token),
          );
          baseOperation
              .add(StellarTransactionOperationDetails(operation: i, operationInfo: info));
          break;
        case OperationType.pathPaymentStrictReceive:
          final operation = body.cast<PathPaymentStrictReceiveOperation>();
          final info = StellarPathPaymentStrictReceiveOperation(
              destination: _getOrCreateReceiptAddress(
                  address: operation.destination.address, chain: chain),
              asset: StellarPickedIssueAsset(
                  asset: operation.sendAsset,
                  network: network,
                  issueToken: null,
                  tokenBalance: isSigner
                      ? _getAssetBalance(
                          asset: operation.sendAsset,
                          signerAccountInfo: signerAccountInfo)
                      : null),
              destAsset: StellarPickedIssueAsset(
                  asset: operation.destAsset, network: network, issueToken: null),
              destAmount: IntegerBalance.token(operation.destAmount, network.token),
              sendAmount: IntegerBalance.token(operation.sendMax, network.token),
              paths: operation.path
                  .map((e) => StellarPickedIssueAsset(
                      asset: e, network: network, issueToken: null))
                  .toList());
          baseOperation.add(StellarTransactionOperationDetails(
              operation: i, operationInfo: info, sourceAccount: sourceAccount));
          break;
        case OperationType.pathPaymentStrictSend:
          final operation = body.cast<PathPaymentStrictSendOperation>();
          final info = StellarPathPaymentStrictSendOperation(
              destination: _getOrCreateReceiptAddress(
                  address: operation.destination.address, chain: chain),
              asset: StellarPickedIssueAsset(
                  asset: operation.sendAsset,
                  network: network,
                  issueToken: null,
                  tokenBalance: isSigner
                      ? _getAssetBalance(
                          asset: operation.sendAsset,
                          signerAccountInfo: signerAccountInfo)
                      : null),
              destAsset: StellarPickedIssueAsset(
                  asset: operation.destAsset, network: network, issueToken: null),
              destMin: IntegerBalance.token(operation.destMin, network.token),
              sendAmount: IntegerBalance.token(operation.sendAmount, network.token),
              paths: operation.path
                  .map((e) => StellarPickedIssueAsset(
                      asset: e, network: network, issueToken: null))
                  .toList());
          baseOperation.add(StellarTransactionOperationDetails(
              operation: i, operationInfo: info, sourceAccount: sourceAccount));
          break;
        case OperationType.manageBuyOffer:
          final operation = body.cast<ManageBuyOfferOperation>();
          final info = StellarManageBuyOfferOperation(
              asset: StellarPickedIssueAsset(
                  asset: operation.selling, network: network, issueToken: null),
              buying: StellarPickedIssueAsset(
                  asset: operation.buying, network: network, issueToken: null),
              price: operation.price,
              amount: IntegerBalance.token(operation.buyAmount, network.token),
              offerId: operation.offerId,
              value: BigInt.zero);
          baseOperation.add(StellarTransactionOperationDetails(
              operation: i, operationInfo: info, sourceAccount: sourceAccount));
          break;
        case OperationType.manageSellOffer:
          final operation = body.cast<ManageSellOfferOperation>();
          final info = StellarManageSellOfferOperation(
              asset: StellarPickedIssueAsset(
                  asset: operation.selling, network: network, issueToken: null),
              buying: StellarPickedIssueAsset(
                  asset: operation.buying, network: network, issueToken: null),
              price: operation.price,
              amount: IntegerBalance.token(operation.amount, network.token),
              offerId: operation.offerId);
          baseOperation.add(StellarTransactionOperationDetails(
              operation: i, operationInfo: info, sourceAccount: sourceAccount));
          break;
        default:
          baseOperation.add(StellarTransactionOperationDetails(
              operation: i, sourceAccount: sourceAccount));
          break;
      }
    }
    return StellarWeb3TransactionDetails(
        memo: memo,
        fee: fee,
        source: _getOrCreateReceiptAddress(address: source, chain: chain),
        contentStr:
            StringUtils.fromJson(envlope.toJson(), indent: '  ', toStringEncodable: true),
        type: type,
        operations: baseOperation,
        envelope: envlope,
        soroban: soroban);
  }
}
