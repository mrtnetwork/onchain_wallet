import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/transaction/types/xcm_types.dart';
import 'package:on_chain_wallet/future/widgets/widgets/json/json/widgets.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/transaction/core/transaction.dart';
import 'package:polkadot_dart/polkadot_dart.dart'
    show SubstrateXCMTransctionTrackerStatus;

class SuccessXCMTransactionTextView extends StatelessWidget {
  const SuccessXCMTransactionTextView(
      {super.key,
      required this.txId,
      required this.account,
      required this.destinationTracker,
      this.address,
      this.transaction,
      this.warning});
  final String txId;
  final ChainTransaction? transaction;
  final String? warning;
  final Chain account;
  final SubmitedXCMTransferDestinationTracker destinationTracker;
  final ChainAccount? address;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleTokenImageView(account.network.coinParam.token, radius: APPConst.double80),
        Text(account.network.coinParam.token.name, style: context.textTheme.labelLarge),
        ConditionalWidget(
          onActive: (context) =>
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            WidgetConstant.height20,
            ContainerWithBorder(
              onRemoveIcon: Icon(Icons.edit, color: context.onPrimaryContainer),
              child: AddressDetailsView(
                address: address!,
                color: context.onPrimaryContainer,
                chain: account,
              ),
            ),
          ]),
          enable: address != null,
        ),
        WidgetConstant.height20,
        TrackTransactionStatusView(
          account: account,
          txId: txId,
          transaction: transaction,
          onTxSuccess: (context) {
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              WidgetConstant.height20,
              APPStreamBuilder(
                value: destinationTracker.notifier,
                builder: (context, value) {
                  return Shimmer(
                      onActive: (enable, context) {
                        return ContainerWithBorder(
                          onRemoveIcon:
                              Icon(Icons.open_in_full, color: context.onPrimaryContainer),
                          onRemove: destinationTracker.hasContent
                              ? () {
                                  context.openDialogPage('',
                                      child: (context) => JsonView(
                                          text: destinationTracker.content ?? {},
                                          title: 'content'.tr));
                                }
                              : null,
                          child: Row(children: [
                            CircleTokenImageView(
                              destinationTracker.destination.network.token,
                              radius: APPConst.circleRadius25,
                              backgroundColor: context.onPrimaryContainer,
                              reverseColor: context.primaryContainer,
                            ),
                            WidgetConstant.width8,
                            Expanded(
                                child: ConditionalWidgets<
                                        SubstrateXCMTransctionTrackerStatus>(
                                    enable: destinationTracker.status,
                                    widgets: {
                                  null: (context) => Text(
                                      "tracking_transaction_on_destination_network_please_wait"
                                          .tr),
                                  SubstrateXCMTransctionTrackerStatus.error: (context) =>
                                      Text(
                                          "transaction_tracking_failed_on_destination_network"
                                              .tr),
                                  SubstrateXCMTransctionTrackerStatus.success:
                                      (context) => Text(
                                          "transaction_execution_successfully_on_destination_network"
                                              .tr),
                                  SubstrateXCMTransctionTrackerStatus.failed: (context) =>
                                      Text(
                                          "transaction_execution_failed_on_destination_network"
                                              .tr),
                                  SubstrateXCMTransctionTrackerStatus.notFound:
                                      (context) => Text(
                                          "transaction_not_detected_on_the_destination_blockchain_desc"
                                              .tr),
                                })),
                          ]),
                        );
                      },
                      enable: !destinationTracker.inProgress);
                },
              ),
            ]);
          },
        ),
        WidgetConstant.height20,
        AlertTextContainer(message: warning),
      ],
    );
  }
}
