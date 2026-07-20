import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:xrpl_dart/xrpl_dart.dart';

class RippleTransactionOperations
    with Equality
    implements TransactionOperations {
  factory RippleTransactionOperations.fromTransactionType(
      SubmittableTransactionType txType) {
    return RippleTransactionOperations._(txType.value);
  }

  @override
  final String value;
  const RippleTransactionOperations._(this.value);
  @override
  List get variables => [value];
}

class RippleTransactionFee extends TransactionFee {
  RippleTransactionFee({required super.type, required super.fee, super.error});

  RippleTransactionFee copyWith(
      {TxFeeTypes? type, IntegerBalance? fee, String? error}) {
    return RippleTransactionFee(
        type: type ?? this.type, fee: fee ?? this.fee, error: error);
  }
}

class RippleTransactionFeeData
    extends TransactionDynamicFeeData<RippleTransactionFee> {
  RippleTransactionFeeData({required super.select, required super.feeToken});
  int _multiSigner = 0;
  SubmittableTransactionType _transactionType =
      SubmittableTransactionType.payment;
  int get multiSigner => _multiSigner;
  SubmittableTransactionType get transactionType => _transactionType;
  void init(
      {required int multiSigner,
      required SubmittableTransactionType transactionType}) {
    _multiSigner = multiSigner;
    _transactionType = transactionType;
  }

  @override
  RippleTransactionFee createManualFee(BigInt amount) {
    return RippleTransactionFee(
        type: TxFeeTypes.manually,
        fee: IntegerBalance.token(
          amount,
          feeToken,
          allowNegative: false,
          immutable: true,
        ));
  }
}

abstract class BaseRippleTransactionController<T extends IXRPTransactionData>
    extends TransactionStateController<
        RippleIssueToken,
        WalletXRPNetwork,
        IXRPAddress,
        XRPNetworkClient,
        XRPChain,
        T,
        IXRPTransaction<T>,
        IXRPSignedTransaction<T>,
        XRPWalletTransaction,
        SubmitTransactionSuccess<IXRPSignedTransaction<T>>,
        RippleTransactionFeeData> {
  SubmittableTransactionType get transactionType;

  BaseRippleTransactionController(
      {required super.walletProvider,
      required super.account,
      required super.address});

  @override
  late final TransactionOperations operation =
      RippleTransactionOperations.fromTransactionType(transactionType);
}

class IXRPTransactionData<T extends SubmittableTransaction>
    extends ITransactionData {
  final RippleTransactionFee fee;
  final T submittableTransaction;
  final IXRPTransactionDataTokenTransfer? payment;
  const IXRPTransactionData(
      {required this.fee, required this.submittableTransaction, this.payment});
}

class IXRPTransactionDataTokenTransfer {
  final XRPBaseAddress recipient;
  final dynamic amount;
  final RipplePickedAsset token;
  IXRPTransactionDataTokenTransfer(
      {required this.recipient, required this.amount, required this.token});
}

class IXRPTransaction<TXDATA extends IXRPTransactionData>
    extends ITransaction<TXDATA, IXRPAddress> {
  const IXRPTransaction(
      {required super.account, required super.transactionData});
}

class IXRPSignedTransaction<TXDATA extends IXRPTransactionData>
    extends ISignedTransaction<IXRPTransaction<TXDATA>,
        SubmittableTransaction> {
  final XRPLSignature? signature;
  final List<XRPLSigners>? multiSignature;
  IXRPSignedTransaction(
      {required super.transaction,
      required super.signatures,
      required super.finalTransactionData,
      this.signature,
      this.multiSignature});
}

enum RipplePickedAssetType {
  issue,
  createIssue,
  xrp;

  bool get isNative => this == xrp;
  bool get isAccountToken => this == issue;
  bool get isCreateAsset => this == createIssue;
}

class RipplePickedAsset {
  final RipplePickedAssetType type;
  final RippleIssueToken? issueToken;
  String? get issuer => issueToken?.issuer;
  RipplePickedAsset._({required this.type, this.issueToken});
  factory RipplePickedAsset.xrp() {
    return RipplePickedAsset._(type: RipplePickedAssetType.xrp);
  }
  factory RipplePickedAsset.account(RippleIssueToken token) {
    return RipplePickedAsset._(
        type: RipplePickedAssetType.issue, issueToken: token);
  }
  factory RipplePickedAsset.create(RippleIssueToken token) {
    return RipplePickedAsset._(
        type: RipplePickedAssetType.createIssue, issueToken: token);
  }
}

class XRPSignerEntries {
  const XRPSignerEntries(
      {required this.address, required this.weight, this.walletLocator});
  final ReceiptAddress<XRPBaseAddress> address;
  final BigRational weight;
  final String? walletLocator;
}

class XRPSignedTransaction {
  final SubmittableTransaction transaction;
  final List<List<int>> signatures;
  final XRPLSignature? signature;
  final List<XRPLSigners>? multiSignature;

  XRPSignedTransaction(
      {required this.transaction,
      this.signature,
      required List<List<int>> signatures,
      List<XRPLSigners>? multiSignature})
      : signatures = signatures.map((e) => e.asImmutableBytes).toImutableList,
        multiSignature = multiSignature?.immutable;
}

class XRPAccountInfo {
  final ReceiptAddress<XRPBaseAddress> owner;
  final bool enableMasterKey;
  final XRPBaseAddress? regularKey;
  final XRPAccountObjectEntry? accountSigners;
  const XRPAccountInfo(
      {required this.enableMasterKey,
      required this.regularKey,
      required this.accountSigners,
      required this.owner});
}
