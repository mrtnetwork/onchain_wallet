import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:on_chain_wallet/wallet/models/models.dart';
import 'package:stellar_dart/stellar_dart.dart';

abstract class StellarTransactionOperation {
  Operation toOperation();
  BigInt get value;
  OperationType get type;
  StellarPickedIssueAsset? get asset;

  StellarWalletTransactionOutput toWalletTransactionOutput(
      WalletStellarNetwork network);
}

class StellarChangeTrustOperation implements StellarTransactionOperation {
  @override
  final StellarPickedIssueAsset asset;
  final IntegerBalance limit;

  StellarChangeTrustOperation(
      {required this.asset, required IntegerBalance limit})
      : limit =
            IntegerBalance.token(limit.balance, limit.token, immutable: true);

  @override
  Operation<OperationBody> toOperation() {
    return Operation(
        body: ChangeTrustOperation(asset: asset.asset, limit: limit.balance));
  }

  @override
  BigInt get value => BigInt.zero;

  @override
  OperationType get type => OperationType.changeTrust;

  @override
  StellarWalletTransactionOutput toWalletTransactionOutput(
      WalletStellarNetwork network) {
    return StellarWalletTransactionOperationOutput(name: type.name);
  }
}

class StellarPaymentOperation implements StellarTransactionOperation {
  @override
  final StellarPickedIssueAsset asset;
  final StellarReceiptWithActivityStatus destination;
  final IntegerBalance amount;

  bool get isNative => asset.asset.type.isNative;

  StellarPaymentOperation({
    required this.asset,
    required this.destination,
    required IntegerBalance amount,
  }) : amount =
            IntegerBalance.token(amount.balance, amount.token, immutable: true);
  @override
  Operation<OperationBody> toOperation() {
    return Operation(
        body: PaymentOperation(
            asset: asset.asset,
            amount: amount.balance,
            destination: destination.address.networkAddress.toMuxedAccount()));
  }

  @override
  BigInt get value => amount.balance;
  @override
  OperationType get type => OperationType.payment;

  @override
  StellarWalletTransactionOutput toWalletTransactionOutput(
      WalletStellarNetwork network) {
    return StellarWalletTransactionTransferOutput(
        to: destination.address.networkAddress,
        amount: WalletTransactionIntegerAmount(
            amount: value,
            network: network,
            token: isNative ? null : asset.token,
            tokenIdentifier: isNative ? null : asset.issuer));
  }
}

class StellarPathPaymentStrictReceiveOperation
    implements StellarTransactionOperation {
  @override
  final StellarPickedIssueAsset asset;
  final IntegerBalance sendAmount;
  final StellarPickedIssueAsset destAsset;
  final IntegerBalance destAmount;
  final StellarReceiptWithActivityStatus destination;
  final List<StellarPickedIssueAsset> paths;

  bool get isNative => asset.asset.type.isNative;

  StellarPathPaymentStrictReceiveOperation({
    required this.asset,
    required this.destination,
    required IntegerBalance sendAmount,
    required this.destAsset,
    List<StellarPickedIssueAsset> paths = const [],
    required IntegerBalance destAmount,
  })  : sendAmount = IntegerBalance.token(sendAmount.balance, sendAmount.token,
            immutable: true),
        destAmount = IntegerBalance.token(destAmount.balance, destAmount.token,
            immutable: true),
        paths = paths.immutable;
  @override
  Operation<OperationBody> toOperation() {
    return Operation(
      body: PathPaymentStrictReceiveOperation(
          destAmount: destAmount.balance,
          destAsset: destAsset.asset,
          sendAsset: asset.asset,
          sendMax: sendAmount.balance,
          path: paths.map((e) => e.asset).toList(),
          destination: destination.address.networkAddress.toMuxedAccount()),
    );
  }

  @override
  BigInt get value => sendAmount.balance;
  @override
  OperationType get type => OperationType.pathPaymentStrictReceive;

  @override
  StellarWalletTransactionOutput toWalletTransactionOutput(
      WalletStellarNetwork network) {
    return StellarWalletTransactionOperationOutput(name: type.name);
  }
}

class StellarPathPaymentStrictSendOperation
    implements StellarTransactionOperation {
  @override
  final StellarPickedIssueAsset asset;
  final IntegerBalance sendAmount;
  final StellarPickedIssueAsset destAsset;
  final IntegerBalance destMin;
  final StellarReceiptWithActivityStatus destination;
  final List<StellarPickedIssueAsset> paths;
  bool get isNative => asset.asset.type.isNative;

  StellarPathPaymentStrictSendOperation({
    required this.asset,
    required this.destination,
    required IntegerBalance sendAmount,
    required this.destAsset,
    List<StellarPickedIssueAsset> paths = const [],
    required IntegerBalance destMin,
  })  : sendAmount = IntegerBalance.token(sendAmount.balance, sendAmount.token,
            immutable: true),
        destMin = IntegerBalance.token(destMin.balance, destMin.token,
            immutable: true),
        paths = paths.immutable;
  @override
  Operation<OperationBody> toOperation() {
    return Operation(
      body: PathPaymentStrictSendOperation(
          destMin: destMin.balance,
          destAsset: destAsset.asset,
          sendAsset: asset.asset,
          sendAmount: sendAmount.balance,
          path: paths.map((e) => e.asset).toList(),
          destination: destination.address.networkAddress.toMuxedAccount()),
    );
  }

  @override
  BigInt get value => sendAmount.balance;
  @override
  OperationType get type => OperationType.pathPaymentStrictSend;
  @override
  StellarWalletTransactionOutput toWalletTransactionOutput(
      WalletStellarNetwork network) {
    return StellarWalletTransactionOperationOutput(name: type.name);
  }
}

class StellarCreateAccountOperation implements StellarTransactionOperation {
  @override
  final StellarPickedIssueAsset asset;
  final StellarReceiptWithActivityStatus destination;
  final IntegerBalance startingBalance;

  bool get isNative => asset.asset.type.isNative;

  StellarCreateAccountOperation({
    required this.asset,
    required this.destination,
    required IntegerBalance startingBalance,
  }) : startingBalance = IntegerBalance.token(
            startingBalance.balance, startingBalance.token,
            immutable: true);
  @override
  Operation<OperationBody> toOperation() {
    return Operation(
        body: CreateAccountOperation(
            startingBalance: startingBalance.balance,
            destination: destination.address.networkAddress.toPublicKey()));
  }

  @override
  BigInt get value => startingBalance.balance;
  @override
  OperationType get type => OperationType.createAccount;

  @override
  StellarWalletTransactionOutput toWalletTransactionOutput(
      WalletStellarNetwork network) {
    return StellarWalletTransactionTransferOutput(
        to: destination.address.networkAddress,
        amount:
            WalletTransactionIntegerAmount(amount: value, network: network));
  }
}

class StellarManageSellOfferOperation implements StellarTransactionOperation {
  @override
  final StellarPickedIssueAsset asset;
  final IntegerBalance amount;
  final StellarPickedIssueAsset buying;
  final StellarPrice price;
  late final String priceView = price.toPrice();
  final BigInt offerId;

  bool get isNative => asset.asset.type.isNative;

  StellarManageSellOfferOperation({
    required this.asset,
    required this.buying,
    required IntegerBalance amount,
    required this.offerId,
    required this.price,
  }) : amount =
            IntegerBalance.token(amount.balance, amount.token, immutable: true);
  @override
  Operation<OperationBody> toOperation() {
    return Operation(
      body: ManageSellOfferOperation(
          amount: amount.balance,
          buying: buying.asset,
          selling: asset.asset,
          offerId: offerId,
          price: price),
    );
  }

  @override
  BigInt get value => amount.balance;
  @override
  OperationType get type => OperationType.manageSellOffer;

  bool get isByOffer => type == OperationType.manageBuyOffer;
  @override
  StellarWalletTransactionOutput toWalletTransactionOutput(
      WalletStellarNetwork network) {
    return StellarWalletTransactionOperationOutput(name: type.name);
  }
}

class StellarManageBuyOfferOperation extends StellarManageSellOfferOperation {
  StellarManageBuyOfferOperation({
    required super.asset,
    required super.buying,
    required super.amount,
    required super.offerId,
    required super.price,
    required this.value,
  });

  @override
  Operation<OperationBody> toOperation() {
    return Operation(
      body: ManageBuyOfferOperation(
          buyAmount: amount.balance,
          buying: buying.asset,
          selling: asset.asset,
          offerId: offerId,
          price: price),
    );
  }

  @override
  final BigInt value;
  @override
  OperationType get type => OperationType.manageBuyOffer;
}

class StellarTransactionOperationDetails {
  final StellarTransactionOperation? operationInfo;
  final Map<String, dynamic> operationContent;
  final String operationContentStr;
  final Operation<OperationBody> operation;
  final StellarReceiptWithActivityStatus? sourceAccount;

  OperationLevel get level => operation.body.level;
  const StellarTransactionOperationDetails._(
      {required this.operationInfo,
      required this.operationContent,
      required this.operationContentStr,
      required this.operation,
      this.sourceAccount});
  factory StellarTransactionOperationDetails(
      {required Operation<OperationBody> operation,
      StellarTransactionOperation? operationInfo,
      StellarReceiptWithActivityStatus? sourceAccount}) {
    final content = operation.body.toJson().immutable;
    return StellarTransactionOperationDetails._(
        operation: operation,
        operationContent: content,
        operationContentStr: StringUtils.fromJson(content,
            indent: '  ', toStringEncodable: true),
        operationInfo: operationInfo,
        sourceAccount: sourceAccount);
  }
}
