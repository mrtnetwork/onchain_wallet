import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/web3/operations/send_transaction.dart';
import 'package:on_chain_wallet/future/wallet/network/tron/web3/operations/sign_message.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/web3.dart';
import 'package:on_chain_wallet/future/wallet/web3/core/state.dart';
import 'package:on_chain_wallet/wallet/api/client/client.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/networks/tron/models/tron_account_info.dart';
import 'package:on_chain_wallet/wallet/models/others/models/receipt_address.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/networks/trc10.dart'
    show TronTRC10Token;
import 'package:on_chain_wallet/wallet/models/transaction/networks/tron.dart';
import 'package:on_chain_wallet/web3/web3/web3.dart';

abstract class Web3TronTransactionInfo {
  const Web3TronTransactionInfo();

  abstract final TransactionContractType type;
  abstract final IntegerBalance? totalTrxAmount;
  abstract final ReceiptAddress<TronAddress>? destination;
  Web3TronTransferAssetInfo? get transferAsset => null;

  SolidityERC20TransferMethodInfo? get trc20Transfer => null;

  bool get isTransferContract => type == TransactionContractType.transferContract;
  bool get isSmartContract => type == TransactionContractType.triggerSmartContract;
  bool get isCreateContract => type == TransactionContractType.createSmartContract;
}

class Web3TronTransferInfo extends Web3TronTransactionInfo {
  @override
  TransactionContractType get type => TransactionContractType.transferContract;
  final ReceiptAddress<TronAddress> receiptAddress;
  final IntegerBalance amount;
  Web3TronTransferInfo._({required this.receiptAddress, required this.amount});
  factory Web3TronTransferInfo(
      {required ReceiptAddress<TronAddress> receiptAddress,
      required BigInt amount,
      required WalletTronNetwork network}) {
    return Web3TronTransferInfo._(
      receiptAddress: receiptAddress,
      amount: IntegerBalance.token(amount, network.token),
    );
  }

  @override
  IntegerBalance get totalTrxAmount => amount;

  @override
  ReceiptAddress<TronAddress>? get destination => receiptAddress;
}

class Web3TronTransferAssetInfo extends Web3TronTransactionInfo {
  final TronTRC10Token token;
  final ReceiptAddress<TronAddress> receiptAddress;
  final IntegerBalance amount;
  const Web3TronTransferAssetInfo._(
      {required this.amount, required this.receiptAddress, required this.token});
  factory Web3TronTransferAssetInfo(
      {required TronTRC10Token token,
      required ReceiptAddress<TronAddress> receiptAddress,
      required BigInt amount}) {
    return Web3TronTransferAssetInfo._(
        token: token,
        receiptAddress: receiptAddress,
        amount: IntegerBalance.token(amount, token.token));
  }

  @override
  TransactionContractType get type => TransactionContractType.transferAssetContract;

  @override
  final IntegerBalance? totalTrxAmount = null;

  @override
  ReceiptAddress<TronAddress>? get destination => receiptAddress;
  @override
  Web3TronTransferAssetInfo? get transferAsset => this;
}

class Web3TronTriggerSmartContract extends Web3TronTransactionInfo {
  final Web3TronTransferInfo? value;
  final Web3TronTransferAssetInfo? callValue;
  final ReceiptAddress<TronAddress> contractAddress;
  final EthereumTransactionDataInfo dataInfo;

  const Web3TronTriggerSmartContract._(
      {required this.contractAddress,
      required this.value,
      required this.callValue,
      required this.dataInfo});
  factory Web3TronTriggerSmartContract(
      {required Web3TronTransferInfo? value,
      required Web3TronTransferAssetInfo? callValue,
      required ReceiptAddress<TronAddress> contractAddress,
      required EthereumTransactionDataInfo dataInfo}) {
    return Web3TronTriggerSmartContract._(
        value: value,
        contractAddress: contractAddress,
        callValue: callValue,
        dataInfo: dataInfo);
  }

  @override
  TransactionContractType get type => TransactionContractType.triggerSmartContract;

  @override
  IntegerBalance? get totalTrxAmount => value?.totalTrxAmount;

  @override
  ReceiptAddress<TronAddress>? get destination => contractAddress;
  @override
  Web3TronTransferAssetInfo? get transferAsset => callValue;
  @override
  SolidityERC20TransferMethodInfo<TronAddress>? get trc20Transfer =>
      dataInfo.type == SolidityMethodInfoTypes.erc20Transfer
          ? dataInfo as SolidityERC20TransferMethodInfo<TronAddress>
          : null;
}

class Web3TronFreezeBalanceInfo extends Web3TronTransactionInfo {
  final ResourceCode resource;
  final IntegerBalance amount;
  const Web3TronFreezeBalanceInfo._({required this.amount, required this.resource});
  factory Web3TronFreezeBalanceInfo(
      {required ResourceCode resource,
      required BigInt amount,
      required WalletTronNetwork network}) {
    return Web3TronFreezeBalanceInfo._(
        resource: resource, amount: IntegerBalance.token(amount, network.token));
  }

  @override
  TransactionContractType get type => TransactionContractType.freezeBalanceV2Contract;
  @override
  IntegerBalance get totalTrxAmount => amount;
  @override
  final ReceiptAddress<TronAddress>? destination = null;
}

class Web3TronCreateContractInfo extends Web3TronTransactionInfo {
  final Web3TronTransferInfo? value;
  final Web3TronTransferAssetInfo? callValue;
  final TronAddress contractAddress;
  const Web3TronCreateContractInfo(
      {required this.value, required this.callValue, required this.contractAddress});
  @override
  TransactionContractType get type => TransactionContractType.createSmartContract;
  @override
  IntegerBalance? get totalTrxAmount => value?.amount;
  @override
  final ReceiptAddress<TronAddress>? destination = null;
  @override
  Web3TronTransferAssetInfo? get transferAsset => callValue;
}

class Web3TronUnknowContractInfo extends Web3TronTransactionInfo {
  final Map<String, dynamic> contractFields;
  const Web3TronUnknowContractInfo(
      {required this.contractFields, required this.totalTrxAmount, required this.type});

  @override
  final TransactionContractType type;
  @override
  final IntegerBalance? totalTrxAmount;
  @override
  final ReceiptAddress<TronAddress>? destination = null;
}

abstract class Web3TronStateController<RESPONSE, CLIENT extends TronClient?,
        T extends Web3TronRequestParam<RESPONSE>>
    extends Web3StateController<
        RESPONSE,
        TronAddress,
        WalletTronNetwork,
        TronClient,
        CLIENT,
        ITronAddress,
        TronChain,
        Web3TronChainAccount,
        T,
        Web3TronRequest<RESPONSE, T>,
        Web3RequestResponseData<RESPONSE>,
        TronWalletTransaction> {
  Web3TronStateController({required super.walletProvider, required super.request});

  static BaseWeb3StateController findController(
      {required Web3TronRequest request, required WalletProvider walletProvider}) {
    switch (request.params.method) {
      case Web3TronRequestMethods.signMessageV2:
        return Web3TronSignMessageStateController(
            walletProvider: walletProvider, request: request.cast());
      case Web3TronRequestMethods.signTransaction:
        return WebTronSendTransactionStateController(
            walletProvider: walletProvider, request: request.cast());
      default:
        throw Web3RequestExceptionConst.methodDoesNotExist;
    }
  }
}

abstract class BaseWeb3TronTransactionStateController<RESPONSE,
        T extends Web3TronRequestParam<RESPONSE>, E extends IWeb3TronTransactionData>
    extends Web3TransactionStateController<
        RESPONSE,
        TronAddress,
        WalletTronNetwork,
        ITronAddress,
        TronClient,
        TronClient,
        TronChain,
        Web3TronChainAccount,
        T,
        Web3TronRequest<RESPONSE, T>,
        E,
        IWeb3TronTransaction<E>,
        IWeb3TronSignedTransaction<E>,
        TronWalletTransaction,
        SubmitTransactionSuccess<IWeb3TronSignedTransaction<E>>> {
  BaseWeb3TronTransactionStateController(
      {required super.walletProvider, required super.request});
}

abstract class IWeb3TronTransactionData extends ITransactionData {
  const IWeb3TronTransactionData();
}

class IWeb3TronTransactionRawData extends IWeb3TronTransactionData {
  final Web3TronTransactionInfo transactionInfo;
  final TronAccountResourceInfo accountResource;
  final int totalSigners;
  final Transaction transaction;
  final ReceiptAddress<TronAddress> owner;
  final IntegerBalance? feeLimit;
  final String? memo;
  final String txId;
  final TronAccountInfo accountData;
  IWeb3TronTransactionRawData(
      {required this.transaction,
      required this.transactionInfo,
      required this.owner,
      required this.feeLimit,
      required this.accountResource,
      required this.totalSigners,
      required this.txId,
      required this.accountData,
      this.memo});
}

class IWeb3TronTransaction<TXDATA extends IWeb3TronTransactionData>
    extends ITransaction<TXDATA, ITronAddress> {
  const IWeb3TronTransaction({required super.account, required super.transactionData});
}

class IWeb3TronSignedTransaction<TXDATA extends IWeb3TronTransactionData>
    extends ISignedTransaction<IWeb3TronTransaction<TXDATA>, Transaction> {
  IWeb3TronSignedTransaction({
    required super.transaction,
    required super.signatures,
    required super.finalTransactionData,
  });
}
