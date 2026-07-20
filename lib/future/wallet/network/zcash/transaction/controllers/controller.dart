import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';
import 'package:on_chain_wallet/future/wallet/network/zcash/transaction/controllers/utxos.dart';
import 'package:on_chain_wallet/future/wallet/network/zcash/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/zcash/transaction/widgets/parameters.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/controller.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/zcash/clients/client.dart';
import 'package:zcash_dart/zcash.dart';
import 'fee.dart';
import 'memo.dart';
import 'provider.dart';

abstract class ZcashTransactionStateController<T extends IZcashTransactionData>
    extends BaseZcashTransactionController<T>
    with
        ZcashTransactionUtxosController,
        ZcashTransactionFeeController,
        ZcashTransactionMemoController<T>,
        ZcashTransactionApiController {
  ZcashTransactionStateController(
      {required super.walletProvider, required super.account, required super.address});

  @override
  Future<IResult<IZcashTransaction<T>>> onTranactionCreatedInternal(
      {required IZcashTransaction<T> transaction, required BuildContext context}) async {
    if (transaction.hasSapling) {
      LivePercentProgressBar? spend;
      LivePercentProgressBar? output;
      try {
        setPageProgress("checking_sapling_configruration_parameters".tr);
        final result = await getOrDownloadSaplingParams(
          hasOutput: transaction.hasSaplingOutput,
          hasSpend: transaction.hasSaplingSpend,
          context: walletProvider.context,
          onDownloadRequired: (type, lengthInMb, links) async {
            final result = await context.openDialog<SaplingPickParamOptions>(
                sliver: (context) => SaplingDownloadParametersView(
                      type: type,
                      lengthInMb: lengthInMb,
                      downloadLinks: links,
                    ),
                label: "sapling_parameters".tr);
            return result.andThenAsync((option) async {
              if (option == null) {
                return ResultErr.fromException(
                    WalletExceptionConst.saplingParamVerificationFailed);
              }
              switch (option) {
                case SaplingPickParamsDownload():
                  if (type == ZcashSaplingParameter.spend) {
                    final progressBar = spend = LivePercentProgressBar();
                    setPageProgress("download_sapling_parameters_please_wait".tr,
                        progressBar: progressBar);
                    return ResultOk((progress: progressBar, option: option));
                  }
                  final progressBar = output = LivePercentProgressBar();
                  setPageProgress("download_sapling_parameters_please_wait".tr,
                      progressBar: progressBar);
                  return ResultOk((progress: progressBar, option: option));
                case SaplingPickParamsFile():
                  setPageProgress("verify_sapling_parameters_please_wait".tr);
                  return ResultOk((progress: null, option: option));
              }
            });
          },
        );
        return result.map((e) {
          setPageProgress("creating_transaction".tr);
          return transaction;
        });
      } finally {
        spend?.dispose();
        output?.dispose();
      }
    }
    return super.onTranactionCreatedInternal(transaction: transaction, context: context);
  }

  @override
  Future<TransactionStateController> initForm({
    required BuildContext context,
    required ZcashNetworkClient client,
    bool updateAccount = true,
    bool updateTokens = false,
  }) async {
    await super.initForm(context: context, client: client, updateAccount: false);
    final syncing = await account.getSyncing();
    return syncing.foldAsync(
      onErr: (error) => throw error.exception,
      onOk: (value) async {
        final height = await client.getLatestBlockHeight();
        await initAccountUtxos(
          addresses: account.addresses,
          syncing: value,
          latestHeight: height,
          client: client,
        );
        return this;
      },
    );
  }
}
