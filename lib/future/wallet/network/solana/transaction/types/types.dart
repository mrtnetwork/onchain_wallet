import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/atomic/atomic.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:on_chain/solana/solana.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

enum SolanaTransactionOperations implements TransactionOperations {
  transfer("transfer"),
  tokenTransfer("transfer_token"),
  createAssociatedTokenAccount("create_associated_token_account"),
  createAccount("create_account"),
  initializeMint("initialize_mint"),
  mintTo("mint_to");

  @override
  final String value;
  const SolanaTransactionOperations(this.value);
}

class SolanaTransactionFee extends DefaultTransactionFee {
  SolanaTransactionFee({required super.fee, super.error});
  factory SolanaTransactionFee.defaultFee({required Token feeToken, String? error}) {
    return SolanaTransactionFee(
        error: error,
        fee: IntegerBalance.token(SolanaConst.solanaDefaultTxFeePerSignature, feeToken));
  }
}

class SolanaTransactionFeeData extends TransactionDefaultFeeData<SolanaTransactionFee> {
  SolanaTransactionFeeData({required super.select, required super.feeToken});
}

abstract class BaseSolanaTransactionController extends TransactionStateController<
    SolanaSPLToken,
    WalletSolanaNetwork,
    ISolanaAddress,
    SolanaNetworkClient,
    SolanaChain,
    ISolanaTransactionData,
    ISolanaTransaction,
    ISolanaSignedTransaction,
    SolanaWalletTransaction,
    SubmitTransactionSuccess<ISolanaSignedTransaction>,
    SolanaTransactionFeeData> {
  BaseSolanaTransactionController(
      {required super.walletProvider, required super.account, required super.address});
}

class ISolanaTransactionData extends ITransactionData {
  final String? memo;
  final List<TransactionInstruction> instructions;
  final SolanaTransactionFee fee;
  final List<ISolanaTransactionDataTokenTransfer>? payment;
  final SolAddress blockHash;
  ISolanaTransactionData(
      {required this.fee,
      required this.memo,
      required List<TransactionInstruction> instructions,
      required this.blockHash,
      List<ISolanaTransactionDataTokenTransfer>? payment})
      : instructions = instructions.immutable,
        payment = payment?.immutable;
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

class ISolanaTransactionDataTokenTransfer {
  final SolAddress recipient;
  final BigInt amount;
  final SolanaSPLToken? token;
  ISolanaTransactionDataTokenTransfer(
      {required this.recipient, required this.amount, required this.token});
}

class ISolanaTransaction extends ITransaction<ISolanaTransactionData, ISolanaAddress> {
  final SolanaTransaction transaction;
  const ISolanaTransaction(
      {required super.account,
      required this.transaction,
      required super.transactionData});
}

class ISolanaSignedTransaction
    extends ISignedTransaction<ISolanaTransaction, SolanaTransaction> {
  ISolanaSignedTransaction(
      {required super.transaction,
      required super.signatures,
      required super.finalTransactionData});
}

class TransactionResourceRequirementSolanaRentData
    extends TransactionResourceRequirement<IntegerBalance> {
  bool get hasAmount => status.isManual || status.isSuccess;
  const TransactionResourceRequirementSolanaRentData(
      {required super.value, required super.status, super.error});
}

class TransactionResourceRequirementMintAccount
    extends TransactionResourceRequirement<ReceiptAddress<SolAddress>> {
  final Token? token;
  const TransactionResourceRequirementMintAccount(
      {required super.value, required super.status, this.token, super.error});
}

class SolanaSignedTransaction {
  final SolanaTransaction transaction;
  final List<List<int>> signatures;
  SolanaSignedTransaction(
      {required this.transaction, required List<List<int>> signatures})
      : signatures = signatures.map((e) => e.asImmutableBytes).toImutableList;
}

enum SolanaAccountOwnerTypes {
  system("system_program"),
  spltoken("spl_token"),
  spltoken2022("spl_token2022"),
  unknow('unknown');

  final String value;
  const SolanaAccountOwnerTypes(this.value);
  static SolanaAccountOwnerTypes fromAddress(SolAddress address) {
    switch (address) {
      case SystemProgramConst.programId:
        return SolanaAccountOwnerTypes.system;
      case SPLTokenProgramConst.tokenProgramId:
        return SolanaAccountOwnerTypes.spltoken;
      case SPLTokenProgramConst.token2022ProgramId:
        return SolanaAccountOwnerTypes.spltoken2022;
      default:
        return SolanaAccountOwnerTypes.unknow;
    }
  }

  bool get isUnknown => this == SolanaAccountOwnerTypes.unknow;
}

enum SolanaAccountStatus {
  unknown,
  initialized,
  uninitialized,
  error;

  bool get isInitialized => this == initialized;
  bool get isUnknown => this == unknown;
}

class SolanaTransferDetails extends TransferOutputDetails<SolAddress> {
  final _lock = SafeAtomicLock();
  final bool isPubKey;
  SolAddress getPdaAddress(SolAddress mint) {
    return isPubKey
        ? AssociatedTokenAccountProgramUtils.associatedTokenAccount(
                mint: mint, owner: recipient.networkAddress)
            .address
        : recipient.networkAddress;
  }

  SolanaAccountStatus _status = SolanaAccountStatus.unknown;
  void _setStatus(SolanaAccountStatus status) {
    _status = status;
    notify();
  }

  SolanaAccountStatus get status => _status;
  bool get hasError => _status == SolanaAccountStatus.error;
  SolanaTransferDetails({
    required super.recipient,
    required Token token,
  })  : isPubKey = recipient.networkAddress.isOnCurve,
        super(amount: IntegerBalance.zero(token, allowNegative: false));

  Future<List<TransactionInstruction>> instruction(
      {required SolAddress owner,
      required SolanaNetworkClient client,
      SolanaSPLToken? token}) async {
    final instructions = await _lock.run(() async {
      SolAddress? pda;
      SolanaAccountStatus status = SolanaAccountStatus.initialized;
      if (_status.isUnknown) {
        try {
          if (token != null) {
            pda = getPdaAddress(token.mint);
            final exist = await client.getTokenAccount(pda);
            if (exist == null) {
              status = SolanaAccountStatus.uninitialized;
              if (!isPubKey) {
                status = SolanaAccountStatus.error;
                throw AppException("solana_spl_token_required_public_key");
              }
            } else if (exist.mint != token.mint) {
              status = SolanaAccountStatus.error;
              throw AppException("spl_token_invalid_associated_account_address");
            }
          } else {
            final account = await client.getAccountInfo(recipient.networkAddress);
            if (account == null) {
              status = SolanaAccountStatus.uninitialized;
            }
          }
        } finally {
          _setStatus(status);
        }
      }
      if (token != null) {
        pda ??= getPdaAddress(token.mint);
        TransactionInstruction? ascAccout;
        if (!_status.isInitialized) {
          ascAccout = AssociatedTokenAccountProgram.associatedTokenAccount(
              payer: owner,
              associatedToken: pda,
              owner: recipient.networkAddress,
              mint: token.mint);
        }
        return [
          if (ascAccout != null) ascAccout,
          SPLTokenProgram.transferChecked(
              layout: SPLTokenTransferCheckedLayout(
                  amount: amount.balance, decimals: token.token.decimal),
              owner: owner,
              source: token.tokenAccount,
              mint: token.mint,
              destination: pda)
        ];
      }
      return [
        SystemProgram.transfer(
            layout: SystemTransferLayout(lamports: amount.balance),
            from: owner,
            to: recipient.networkAddress)
      ];
    });
    return instructions;
  }

  @override
  List get variables => [recipient];
}
