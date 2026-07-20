import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain/ada/ada.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/web3/operations/get_account_pub.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/web3/operations/get_collateral.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/web3/operations/send_transaction.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/web3/operations/sign_data.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/web3/operations/sign_message.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/web3.dart';
import 'package:on_chain_wallet/future/wallet/web3/core/state.dart';
import 'package:on_chain_wallet/wallet/api/client/client.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network/network.dart';
import 'package:on_chain_wallet/wallet/models/networks/cardano/models/address_details.dart';
import 'package:on_chain_wallet/wallet/models/others/models/receipt_address.dart';
import 'package:on_chain_wallet/wallet/models/transaction/networks/ada.dart';
import 'package:on_chain_wallet/web3/web3/web3.dart';

abstract class Web3CardanoStateController<RESPONSE, CLIENT extends ADANetworkClient?,
        T extends Web3ADARequestParam<RESPONSE>>
    extends Web3StateController<
        RESPONSE,
        ADAAddress,
        WalletCardanoNetwork,
        ADANetworkClient,
        CLIENT,
        ICardanoAddress,
        ADAChain,
        Web3ADAChainAccount,
        T,
        Web3ADARequest<RESPONSE, T>,
        Web3RequestResponseData<RESPONSE>,
        ADAWalletTransaction> {
  Web3CardanoStateController({required super.walletProvider, required super.request});

  static BaseWeb3StateController findController(
      {required Web3ADARequest request, required WalletProvider walletProvider}) {
    switch (request.params.method) {
      case Web3ADARequestMethods.signMessage:
        return Web3ADASignMessageStateController(
            walletProvider: walletProvider, request: request.cast());
      case Web3ADARequestMethods.signData:
        return Web3ADASignDataStateController(
            walletProvider: walletProvider, request: request.cast());
      case Web3ADARequestMethods.getAccountPub:
        return Web3ADAGetAccountPubKeyStateController(
            walletProvider: walletProvider, request: request.cast());
      case Web3ADARequestMethods.signTx:
      case Web3ADARequestMethods.signTransaction:
      case Web3ADARequestMethods.signAndSendTransaction:
      case Web3ADARequestMethods.submitTx:
      case Web3ADARequestMethods.submitUnsignedTx:
      case Web3ADARequestMethods.signTxs:
      case Web3ADARequestMethods.submitTxs:
        return WebCardanoSignTransactionStateController(
            walletProvider: walletProvider, request: request.cast());
      case Web3ADARequestMethods.getCollateral:
        return Web3ADGetCollateralStateController(
            walletProvider: walletProvider, request: request.cast());
      default:
        throw Web3RequestExceptionConst.methodDoesNotExist;
    }
  }
}

abstract class BaseWeb3CardanoTransactionStateController<RESPONSE,
        T extends Web3ADARequestParam<RESPONSE>>
    extends Web3TransactionStateController<
        RESPONSE,
        ADAAddress,
        WalletCardanoNetwork,
        ICardanoAddress,
        ADANetworkClient,
        ADANetworkClient,
        ADAChain,
        Web3ADAChainAccount,
        T,
        Web3ADARequest<RESPONSE, T>,
        IWeb3ADATransactionData,
        IWeb3ADATransaction,
        IWeb3ADASignedTransaction,
        ADAWalletTransaction,
        SubmitTransactionSuccess<IWeb3ADASignedTransaction>> {
  BaseWeb3CardanoTransactionStateController(
      {required super.walletProvider, required super.request});
}

class Web3ADAAssetInputDetails {
  final IntegerBalance amount;
  final ADAAssetToken token;
  const Web3ADAAssetInputDetails({required this.amount, required this.token});
  factory Web3ADAAssetInputDetails.zero(ADAAssetToken token) {
    return Web3ADAAssetInputDetails(
        token: token, amount: IntegerBalance.zero(token.token));
  }
}

enum Web3ADAInputType { input, collateral, reference }

class Web3ADAInputDetails {
  final TransactionInput input;
  final List<Web3ADAAssetInputDetails> assets;
  final CardanoAccountUtxo? utxo;
  final Web3ADAInputType inputType;
  final bool bulkPrevInput;
  Web3ADAInputDetails({
    required this.utxo,
    required List<Web3ADAAssetInputDetails> assets,
    required this.input,
    required this.inputType,
    required this.bulkPrevInput,
  }) : assets = assets.immutable;
}

class Web3ADAAccountInputDetails {
  final List<Web3ADAInputDetails> inputs;
  final ICardanoAddress address;
  final IntegerBalance totalLovelace;
  final List<Web3ADAAssetInputDetails> totalAssets;
  final bool isSigner;
  Web3ADAAccountInputDetails({
    required List<Web3ADAInputDetails> inputs,
    required this.address,
    required this.totalLovelace,
    required List<Web3ADAAssetInputDetails> totalAssets,
  })  : inputs = inputs.immutable,
        totalAssets = totalAssets.immutable,
        isSigner = inputs.any((e) => e.inputType != Web3ADAInputType.reference);
}

enum Web3ADAOutputType { output, collateral }

class Web3ADAOutputDetails {
  final ReceiptAddress<ADAAddress> address;
  final IntegerBalance lovelace;
  final List<Web3ADAAssetInputDetails> assets;
  final Web3ADAOutputType outputType;
  final TransactionOutput output;
  final ICardanoAddress? account;
  final Map<String, dynamic>? plutusData;
  final Map<String, dynamic>? scriptRef;
  bool get isChange => account != null;
  final int index;
  Web3ADAOutputDetails({
    required this.address,
    required this.lovelace,
    required this.outputType,
    required this.account,
    required List<Web3ADAAssetInputDetails> assets,
    required this.index,
    required this.output,
    this.plutusData,
    this.scriptRef,
  }) : assets = assets.immutable;

  CardanoAccountUtxo? utxo(
          {required List<int> txId, required WalletCardanoNetwork network}) =>
      address.account == null
          ? null
          : CardanoAccountUtxo(
              utxo: ADAAddressUtxo(
                  lovelace: lovelace.balance,
                  output: output,
                  input: TransactionInput(
                      transactionId: TransactionHash(txId), index: index)),
              network: network,
              address: address.account!.cast(),
            );
}

class Web3ADACeriticateDatails {
  final bool allowSign;
  final List<Web3ADATransactionSigner> signers;

  final CertificateType type;
  final Map<String, dynamic> content;
  const Web3ADACeriticateDatails(
      {required this.type,
      required this.content,
      required this.signers,
      required this.allowSign});
}

class IWeb3ADATransactionData extends ITransactionData {
  final List<Web3ADATransactionData> transactions;
  IWeb3ADATransactionData({required List<Web3ADATransactionData> transactions})
      : transactions = transactions.immutable;
}

class Web3ADATransactionData {
  final String txId;
  final bool partialSign;
  final ADATransactionFee fee;
  final ADATransaction transaction;
  final List<Web3ADAOutputDetails> outputs;
  final List<Web3ADAAccountInputDetails> totalAccountsInputs;
  final List<Web3ADAInputDetails> inputs;
  final List<Web3ADAAssetInputMintDetails>? mintInfos;
  final Map<dynamic, dynamic>? metadata;
  final List<Map<String, dynamic>>? nativeScripts;
  final List<Map<String, dynamic>>? plutusScripts;
  final Map<String, dynamic> content;
  final List<Web3ADACeriticateDatails>? certificates;
  final List<Web3ADAWithdrawalDetails>? withdrawals;
  final List<Web3ADAVoteDetails>? votes;
  final List<Web3ADATransactionSigner?>? requiredSignatures;
  late final List<Web3ADATransactionSigner> signers = <Web3ADATransactionSigner>[
    ...totalAccountsInputs.where((e) => e.isSigner).map((e) => Web3ADATransactionSigner(
        address: e.address,
        signer: ReceiptAddress(
            view: e.address.networkAddress.address,
            networkAddress: e.address.networkAddress,
            account: e.address),
        signMode: Web3ADATransactionSigningMode.payment)),
    ...mintInfos?.map((e) => e.signer).whereType<Web3ADATransactionSigner>() ?? [],
    ...withdrawals?.map((e) => e.signer).whereType<Web3ADATransactionSigner>() ?? [],
    ...certificates?.expand((e) => e.signers) ?? [],
    ...votes?.map((e) => e.signer).whereType<Web3ADATransactionSigner>() ?? [],
    ...requiredSignatures?.whereType<Web3ADATransactionSigner>() ?? []
  ].immutable;
  bool get canFullySign {
    final canSignInputs = inputs
        .where((e) => e.inputType != Web3ADAInputType.reference)
        .every((e) => e.utxo != null);
    final canSignMint = mintInfos?.every((e) => e.signer != null) ?? true;
    final canSignCertificate = certificates?.every((e) => e.allowSign) ?? true;
    final canSignWithdrawals = withdrawals?.every((e) => e.signer != null) ?? true;
    final canSignVotes = votes?.every((e) => e.signer != null) ?? true;
    final requiredSignatures = this.requiredSignatures?.every((e) => e != null) ?? true;
    return canSignInputs &&
        canSignMint &&
        canSignCertificate &&
        canSignWithdrawals &&
        canSignVotes &&
        requiredSignatures;
  }

  Web3ADATransactionData({
    required this.fee,
    required this.partialSign,
    required List<Web3ADAOutputDetails> outputs,
    required List<Web3ADAAccountInputDetails> totalAccountsInputs,
    required List<Web3ADAInputDetails> inputs,
    required List<Web3ADAAssetInputMintDetails>? mintInfos,
    required List<Web3ADAWithdrawalDetails>? withdrawals,
    required List<Web3ADAVoteDetails>? votes,
    required List<Web3ADATransactionSigner?>? requiredSignatures,
    required this.transaction,
    required this.txId,
    Map<dynamic, dynamic>? metadata,
    List<Map<String, dynamic>>? nativeScripts,
    List<Map<String, dynamic>>? plutusScripts,
    required Map<String, dynamic> content,
    List<Web3ADACeriticateDatails>? certificates,
  })  : outputs = outputs.immutable,
        inputs = inputs.immutable,
        metadata = metadata?.immutable,
        requiredSignatures = requiredSignatures?.immutable,
        totalAccountsInputs = totalAccountsInputs.immutable,
        nativeScripts = nativeScripts?.map((e) => e.immutable).toImutableList,
        plutusScripts = plutusScripts?.map((e) => e.immutable).toImutableList,
        certificates = certificates?.toImutableList,
        mintInfos = mintInfos?.toImutableList,
        withdrawals = withdrawals?.toImutableList,
        content = content.immutable,
        votes = votes?.immutable;
}

class IWeb3ADATransaction extends ITransaction<IWeb3ADATransactionData, ICardanoAddress> {
  final List<ADATransaction> transactions;
  IWeb3ADATransaction(
      {required super.account,
      required super.transactionData,
      required List<ADATransaction> transactions})
      : transactions = transactions.immutable;
}

class IWeb3ADASignedTransaction
    extends ISignedTransaction<IWeb3ADATransaction, List<ADATransaction>> {
  IWeb3ADASignedTransaction(
      {required super.transaction,
      required super.signatures,
      required super.finalTransactionData});
}

enum Web3ADATransactionSigningMode { payment, reward }

class Web3ADATransactionSigner {
  final ICardanoAddress address;
  final Web3ADATransactionSigningMode signMode;
  final ReceiptAddress<ADAAddress> signer;
  const Web3ADATransactionSigner(
      {required this.address, required this.signMode, required this.signer});
}

class Web3ADAAssetInputMintDetails {
  final List<Web3ADAAssetInputDetails> assets;
  final Web3ADATransactionSigner? signer;
  final String policyId;
  const Web3ADAAssetInputMintDetails(
      {required this.assets, required this.signer, required this.policyId});
}

class Web3ADAWithdrawalDetails {
  final IntegerBalance amount;
  final ReceiptAddress<ADAAddress> address;
  final Web3ADATransactionSigner? signer;
  const Web3ADAWithdrawalDetails(
      {required this.amount, required this.address, required this.signer});
}

class Web3ADAVoteDetails {
  final VoterType type;
  final Web3ADATransactionSigner? signer;
  final List<Map<String, dynamic>> content;
  const Web3ADAVoteDetails(
      {required this.type, required this.signer, required this.content});
}
