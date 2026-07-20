import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:on_chain/aptos/src/address/address/address.dart';
import 'package:on_chain/aptos/src/helper/helper.dart';
import 'package:on_chain/aptos/src/provider/models/fullnode/types.dart';
import 'package:on_chain/aptos/src/transaction/constants/const.dart';
import 'package:on_chain/aptos/src/transaction/types/types.dart';
import 'package:on_chain/serialization/bcs/move/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

typedef TRANSACTIONSTATECONTROLLERBUILDER = void Function();

enum AptosTransactionOperations implements TransactionOperations {
  transfer("transfer"),
  tokenTransfer("transfer_token");

  @override
  final String value;
  const AptosTransactionOperations(this.value);
}

class AptosTransactionFee extends DefaultTransactionFee {
  final BigInt maxGasAmount;
  final BigInt gasUnitPrice;
  final BigInt requiredFee;
  final IAptosTransactionSimulateInfo? simulateInfo;

  AptosTransactionFee._(
      {required this.simulateInfo,
      required this.maxGasAmount,
      required this.gasUnitPrice,
      required this.requiredFee,
      required super.fee,
      super.error});

  factory AptosTransactionFee(
      {BigInt? gasUsed,
      required BigInt gasUnitPrice,
      required WalletAptosNetwork network,
      String? error,
      IAptosTransactionSimulateInfo? simulateInfo}) {
    final hasFee = gasUnitPrice != BigInt.zero;
    BigInt gasAmount = AptosConstants.defaultMaxGasAmount;
    if (gasUsed != null) {
      gasAmount = (BigRational(gasUsed) * BigRational.parseDecimal("1.5")).toBigInt();
    }
    final totalFee = IntegerBalance.token(
        hasFee ? gasAmount * gasUnitPrice : gasAmount, network.token,
        immutable: true, allowNegative: false);
    return AptosTransactionFee._(
        gasUnitPrice: gasUnitPrice,
        maxGasAmount: gasAmount,
        fee: totalFee,
        simulateInfo: simulateInfo,
        requiredFee: totalFee.balance,
        error: error);
  }

  @override
  List get variables => [...super.variables, maxGasAmount, gasUnitPrice, requiredFee];
}

class AptosTransactionFeeData extends TransactionDefaultFeeData<AptosTransactionFee> {
  AptosTransactionFeeData({required super.select, required super.feeToken});
}

abstract class BaseAptosTransactionController<T extends IAptosTransactionData>
    extends TransactionStateController<
        AptosFATokens,
        WalletAptosNetwork,
        IAptosAddress,
        AptosNetworkClient,
        AptosChain,
        T,
        IAptosTransaction<T>,
        IAptosSignedTransaction<T>,
        AptosWalletTransaction,
        SubmitTransactionSuccess<IAptosSignedTransaction<T>>,
        AptosTransactionFeeData> {
  BaseAptosTransactionController(
      {required super.walletProvider, required super.account, required super.address});
}

abstract class IAptosTransactionData extends ITransactionData {
  AptosTransactionPayloadEntryFunction toTransactionPayload();
  AptosTransactionFee get fee;
}

class IAptosTransactionDataTransfer extends IAptosTransactionData {
  @override
  final AptosTransactionFee fee;

  final List<ITransactionDataTransferRecipient<AptosAddress>> recipients;
  IAptosTransactionDataTransfer({
    required List<ITransactionDataTransferRecipient<AptosAddress>> recipients,
    required this.fee,
  }) : recipients = recipients.immutable;

  @override
  AptosTransactionPayloadEntryFunction toTransactionPayload() {
    final transfers = recipients
        .map((e) => AptosTransferParams.apt(apt: e.amount, destination: e.recipient))
        .toList();
    final entryFunction = AptosHelper.createBatchTransferTransferEntry(transfers);
    return AptosTransactionPayloadEntryFunction(entryFunction: entryFunction);
  }
}

class IAptosTransactionDataTokenTransfer extends IAptosTransactionData {
  @override
  final AptosTransactionFee fee;

  final ITransactionDataTransferTokenRecipient<AptosAddress, AptosFATokens> recipient;
  IAptosTransactionDataTokenTransfer({required this.recipient, required this.fee});

  @override
  AptosTransactionPayloadEntryFunction toTransactionPayload() {
    return AptosTransactionPayloadEntryFunction(
        entryFunction: AptosTransactionEntryFunction(
            moduleId: AptosConstants.primaryFungibleStoreModule,
            functionName: AptosConstants.transferFunctionName,
            typeArgs: [
          AptosConstants.fungibleAssetMetadataTypeTag
        ],
            args: [
          AptosAddress(recipient.token.assetType),
          recipient.recipient,
          MoveU64(recipient.amount)
        ]));
  }
}

class IAptosTransaction<TXDATA extends IAptosTransactionData>
    extends ITransaction<TXDATA, IAptosAddress> {
  final AptosRawTransaction rawTransaction;
  const IAptosTransaction(
      {required super.account,
      required super.transactionData,
      required this.rawTransaction});
}

class IAptosSignedTransaction<TXDATA extends IAptosTransactionData>
    extends ISignedTransaction<IAptosTransaction<TXDATA>, AptosSignedTransaction> {
  IAptosSignedTransaction(
      {required super.transaction,
      required super.signatures,
      required super.finalTransactionData});
}

class IAptosTransactionSimulateInfo {
  final AptosApiUserTransaction simulateTx;
  bool get isSuccess => simulateTx.success;
  final String vmStatus;
  late final String simulateContent =
      StringUtils.fromJson(simulateTx.toJson(), indent: ' ', toStringEncodable: true);

  IAptosTransactionSimulateInfo({required this.vmStatus, required this.simulateTx});
}
