import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/transaction/controllers/signer.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/web3/controllers/provider.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/web3/types/types.dart';

import 'package:on_chain_wallet/web3/web3/networks/stellar/params/core/request.dart';
import 'dart:async';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';

abstract class Web3StellarTransactionStateController<
        RESPONSE,
        T extends Web3StellarRequestParam<RESPONSE>,
        E extends IWeb3StellarTransactionData>
    extends BaseWeb3StellarTransactionStateController<RESPONSE, T, E>
    with StellarWeb3TransactionApiController, StellarTransactionSignerController {
  Web3StellarTransactionStateController(
      {required super.walletProvider, required super.request});

  @override
  Future<SubmitTransactionResult> submitTransaction(
      {required IWeb3StellarSignedTransaction<E> signedTransaction}) async {
    final envelopeXdr = signedTransaction.finalTransactionData.toVariantXDRBase64();
    final submissionResult =
        await IResult.call(() async => await client.submitTx(envelopeXdr));

    if (submissionResult.isErr) {
      return SubmitTransactionFailed(submissionResult.unwrapErr().localizationError);
    }
    final submissionResultData = submissionResult.unwrap();
    final success = submissionResultData?.successful ?? true;
    if (!success) {
      final result = MethodUtils.fallbackOnException(
        () => submissionResultData?.getResult().toJson(),
        mode: LoggerMode.danger,
        onError: (exception, trace) => AppLogData(
            runtime: runtimeType,
            function: "submitTransaction",
            err: exception,
            trace: trace.toString(),
            msg: "Failed to decode submission result"),
      );
      if (result == null) {
        return SubmitTransactionFailed("submit_transaction_error".tr.replaceOne(''));
      }
      return SubmitTransactionFailed(
          "submit_transaction_error".tr.replaceOne("\n${StringUtils.fromJson(result)}"));
    }
    final String txId = submissionResultData?.id ??
        signedTransaction.finalTransactionData
            .txId(network.coinParam.stellarChainType.passphraseHash);
    return SubmitTransactionSuccess(
        txId: txId,
        warning:
            submissionResultData == null ? "tx_submit_response_failed_desc".tr : null,
        signedTransaction: signedTransaction);
  }
}
