import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:cosmos_sdk/cosmos_sdk.dart';
import 'package:cosmos_sdk/proto_messages/cosmos/auth/v1beta1/src/auth.dart';
import 'package:cosmos_sdk/proto_messages/cosmos/tx/v1beta1/models.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class CosmosTransactionRequirment {
  final BigInt? fixedNativeGas;
  final BaseAccount? account;
  final List<CW20Token> feeTokens;
  final BigRational? ethermintTxFee;
  late final bool hasMultipleFeeToken = feeTokens.length > 1;
  CosmosTransactionRequirment(
      {this.ethermintTxFee,
      this.fixedNativeGas,
      this.account,
      this.feeTokens = const []});
  CosmosTransactionRequirment copyWith(
      {BigInt? fixedNativeGas,
      BaseAccount? account,
      List<CW20Token>? feeTokens,
      BigRational? ethermintTxFee}) {
    return CosmosTransactionRequirment(
        account: account ?? this.account,
        ethermintTxFee: ethermintTxFee ?? this.ethermintTxFee,
        feeTokens: feeTokens ?? this.feeTokens,
        fixedNativeGas: fixedNativeGas ?? this.fixedNativeGas);
  }
}

enum CosmosTransactionOperations implements TransactionOperations {
  transfer("transfer"),
  ibcTransfer("ibc_transfer");

  @override
  final String value;
  const CosmosTransactionOperations(this.value);
}

class CosmosTransactionFee extends TransactionFee {
  final Token token;
  final BigInt gasLimit;
  final String denom;

  CosmosTransactionFee._({
    required this.token,
    required super.fee,
    required this.gasLimit,
    required super.type,
    required this.denom,
    super.error,
  });
  factory CosmosTransactionFee(
      {required Token token,
      required String denom,
      BigInt? gasLimit,
      BigInt? fee,
      TxFeeTypes type = TxFeeTypes.normal,
      String? error}) {
    return CosmosTransactionFee._(
        token: token,
        fee: IntegerBalance.token(fee ?? BigInt.zero, token),
        gasLimit: gasLimit ?? BigInt.zero,
        type: type,
        error: error,
        denom: denom);
  }
}

class CosmosTransactionFeeData extends TransactionDynamicFeeData<CosmosTransactionFee> {
  String _denom;
  String get denom => _denom;
  BigInt _gasLimit;
  BigInt get gasLimit => _gasLimit;
  int _messages;
  int get messages => _messages;

  CosmosTransactionFeeData(
      {required super.select,
      required super.feeToken,
      required String denom,
      required BigInt gasLimit,
      required int messages})
      : _denom = denom,
        _gasLimit = gasLimit,
        _messages = messages;

  // Fee toFee() {
  //   return Fee(
  //       amount: [Coin(denom: _denom, amount: fee.fee.balance)],
  //       gasLimit: fee.gasLimit);
  // }

  @override
  CosmosTransactionFee createManualFee(BigInt amount) {
    throw UnimplementedError();
  }

  @override
  void updateTokenFee(Token token, List<CosmosTransactionFee> fees, {String? denom}) {
    throw UnimplementedError();
  }

  void updateCosmosFeeToken(
      {required Token token,
      required List<CosmosTransactionFee> fees,
      required String denom,
      required BigInt gasLimit,
      required int messages}) {
    _gasLimit = gasLimit;
    _messages = messages;
    assert(fees.every((e) => e.denom == denom));
    if (denom == this.denom) {
      setDefaultFees(fees);
      return;
    }
    super.updateTokenFee(token, fees);
    _denom = denom;
  }
}

abstract class BaseCosmosTransactionController extends TransactionStateController<
    CW20Token,
    WalletCosmosNetwork,
    ICosmosAddress,
    CosmosNetworkClient,
    CosmosChain,
    ICosmosTransactionData,
    ICosmosTransaction,
    ICosmosSignedTransaction,
    CosmosWalletTransaction,
    SubmitTransactionSuccess<ICosmosSignedTransaction>,
    CosmosTransactionFeeData> {
  bool get isThorChain =>
      network.coinParam.networkType == CosmosNetworkTypes.thorAndForked;
  BaseCosmosTransactionController(
      {required super.walletProvider, required super.account, required super.address});
}

class ICosmosTransactionData extends ITransactionData {
  final List<CosmosTransactionMessage> messages;
  final CosmosTransactionFee fee;
  final String? memo;
  final List<ICosmosTransactionDataTokenTransfer>? payments;
  final BigInt accountNumber;
  final BigInt sequence;
  final String feeDenom;
  ICosmosTransactionData(
      {required this.fee,
      required this.memo,
      required this.accountNumber,
      required this.sequence,
      required this.feeDenom,
      required List<CosmosTransactionMessage> messages,
      List<ICosmosTransactionDataTokenTransfer>? payments})
      : messages = messages.immutable,
        payments = payments?.immutable;

  WalletTransactionMemo? getWalletTxMemo() {
    final memo = this.memo;
    if (memo == null) return null;
    return WalletTransactionMemo.from(
        memo,
        switch (StringUtils.isHexBytes(memo)) {
          true => WalletTransactionMemoType.binary,
          false => WalletTransactionMemoType.string,
        });
  }
}

class ICosmosTransactionDataTokenTransfer {
  final CosmosBaseAddress recipient;
  final BigInt amount;
  final CW20Token token;

  ICosmosTransactionDataTokenTransfer(
      {required this.recipient, required this.amount, required this.token});
}

class ICosmosTransaction extends ITransaction<ICosmosTransactionData, ICosmosAddress> {
  final TxBody transaction;
  const ICosmosTransaction(
      {required super.account,
      required this.transaction,
      required super.transactionData});
}

class ICosmosSignedTransaction<TXDATA extends ICosmosTransactionData>
    extends ISignedTransaction<ICosmosTransaction, TxRaw> {
  final AuthInfo auth;
  ICosmosSignedTransaction(
      {required super.transaction,
      required super.signatures,
      required super.finalTransactionData,
      required this.auth});
}

class CosmosTransactionMessage {
  final ICosmosProtoServiceMessage message;
  final ICosmosAddress signer;
  const CosmosTransactionMessage({required this.message, required this.signer});
}

class CosmosSignedTransaction {
  final List<int> signature;
  final List<int> payload;
  CosmosSignedTransaction({required List<int> signature, required List<int> payload})
      : signature = signature.asImmutableBytes,
        payload = payload.asImmutableBytes;
}
