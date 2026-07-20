import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/address_details.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/receipt_address_view.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/web3/operations/send_transaction.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/web3_request_page_builder.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/future/widgets/widgets/json/json/widgets.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/methods/methods.dart';

class Web3CardanoSignTransactionStateView extends StatelessWidget {
  final WebCardanoSignTransactionStateController controller;
  const Web3CardanoSignTransactionStateView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final transactionData = controller.transactionData;
    bool isBatchTx = transactionData.transactions.length > 1;
    return MultiSliver(children: [
      ConditionalWidget(
          enable: isBatchTx,
          onActive: (context) => AlertTextContainer(
              message: "multiple_transaction_desc".tr, enableTap: false)),
      SliverPadding(
          padding: isBatchTx ? WidgetConstant.paddingHorizontal10 : EdgeInsets.zero,
          sliver: SliverList.separated(
            itemCount: transactionData.transactions.length,
            itemBuilder: (context, index) {
              return _TxDataView(transactionData.transactions[index]);
            },
            separatorBuilder: (context, index) {
              return Divider();
            },
          )),
      Web3StateAcceptRequestView(
          controller: controller,
          title: switch (controller.params.method) {
            Web3ADARequestMethods.signTx => "sign_transaction".tr,
            Web3ADARequestMethods.signTransaction => "sign_transaction".tr,
            Web3ADARequestMethods.signAndSendTransaction => "send_transaction".tr,
            Web3ADARequestMethods.submitTx => "send_transaction".tr,
            Web3ADARequestMethods.submitUnsignedTx => "send_transaction".tr,
            Web3ADARequestMethods.submitTxs => "send_transactions".tr,
            Web3ADARequestMethods.signTxs => "sign_transactions".tr,
            _ => ""
          })
    ]);

    /// "sign_transaction".tr
  }
}

class _TxDataView extends StatelessWidget {
  final Web3ADATransactionData transactionData;
  const _TxDataView(this.transactionData);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("transaction_inputs".tr, style: context.textTheme.titleMedium),
      WidgetConstant.height8,
      APPExpansionListTile(
        title: Text(
          "inputs".tr,
          style: context.onPrimaryTextTheme.bodyMedium,
        ),
        children: [
          ...List.generate(
            transactionData.inputs.length,
            (index) => _InputView(transactionData.inputs[index]),
          )
        ],
      ),
      ConditionalWidget(
          enable: transactionData.totalAccountsInputs.isNotEmpty,
          onActive: (context) =>
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                WidgetConstant.height20,
                Text("your_account_inputs".tr, style: context.textTheme.titleMedium),
                WidgetConstant.height8,
                APPExpansionListTile(
                  title: Text(
                    "inputs".tr,
                    style: context.onPrimaryTextTheme.bodyMedium,
                  ),
                  children: [
                    ...List.generate(
                        transactionData.totalAccountsInputs.length,
                        (index) =>
                            _AccountInputView(transactionData.totalAccountsInputs[index]))
                  ],
                ),
              ])),
      WidgetConstant.height20,
      Text("transaction_outputs".tr, style: context.textTheme.titleMedium),
      WidgetConstant.height8,
      APPExpansionListTile(
        title: Text("outputs".tr, style: context.onPrimaryTextTheme.bodyMedium),
        children: [
          ...List.generate(transactionData.outputs.length,
              (index) => _OutputView(transactionData.outputs[index]))
        ],
      ),
      WidgetConstant.height20,
      ConditionalWidget(
          enable: transactionData.certificates != null,
          onActive: (context) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("certificates".tr, style: context.textTheme.titleMedium),
                  WidgetConstant.height8,
                  APPExpansionListTile(
                    title: Text("certificates".tr,
                        style: context.onPrimaryTextTheme.bodyMedium),
                    children: [
                      ...List.generate(
                          transactionData.certificates!.length,
                          (index) =>
                              _CertificateView(transactionData.certificates![index]))
                    ],
                  ),
                  WidgetConstant.height20,
                ],
              )),
      ConditionalWidget(
          enable: transactionData.withdrawals != null,
          onActive: (context) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("withdrawals".tr, style: context.textTheme.titleMedium),
                  WidgetConstant.height8,
                  APPExpansionListTile(
                    title: Text("withdrawals".tr,
                        style: context.onPrimaryTextTheme.bodyMedium),
                    children: [
                      ...List.generate(transactionData.withdrawals!.length,
                          (index) => _WithdrawalView(transactionData.withdrawals![index]))
                    ],
                  ),
                  WidgetConstant.height20,
                ],
              )),
      ConditionalWidget(
          enable: transactionData.mintInfos != null,
          onActive: (context) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("mint".tr, style: context.textTheme.titleMedium),
                  WidgetConstant.height8,
                  APPExpansionListTile(
                    title: Text("mint".tr, style: context.onPrimaryTextTheme.bodyMedium),
                    children: [
                      ...List.generate(transactionData.mintInfos!.length,
                          (index) => _MintView(transactionData.mintInfos![index]))
                    ],
                  ),
                  WidgetConstant.height20,
                ],
              )),
      ConditionalWidget(
          enable: transactionData.votes != null,
          onActive: (context) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("votes".tr, style: context.textTheme.titleMedium),
                  WidgetConstant.height8,
                  APPExpansionListTile(
                    title: Text("votes".tr, style: context.onPrimaryTextTheme.bodyMedium),
                    children: [
                      ...List.generate(transactionData.votes!.length,
                          (index) => _VoteView(transactionData.votes![index]))
                    ],
                  ),
                  WidgetConstant.height20,
                ],
              )),
      ConditionalWidget(
          enable: transactionData.plutusScripts != null,
          onActive: (context) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("plutus".tr, style: context.textTheme.titleMedium),
                  WidgetConstant.height8,
                  ContainerWithBorder(
                    onRemove: () {
                      context.openDialogPage(
                        '',
                        child: (context) => JsonView(
                            text: transactionData.plutusScripts!, title: 'plutus'.tr),
                      );
                    },
                    onRemoveIcon: Icon(
                      Icons.open_in_full,
                      color: context.onPrimaryContainer,
                    ),
                    child:
                        Text("content".tr, style: context.onPrimaryTextTheme.bodyMedium),
                  ),
                  WidgetConstant.height20,
                ],
              )),
      ConditionalWidget(
          enable: transactionData.nativeScripts != null,
          onActive: (context) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("native_scripts".tr, style: context.textTheme.titleMedium),
                  WidgetConstant.height8,
                  ContainerWithBorder(
                    onRemove: () {
                      context.openDialogPage(
                        '',
                        child: (context) => JsonView(
                            text: transactionData.nativeScripts!,
                            title: 'native_scripts'.tr),
                      );
                    },
                    onRemoveIcon: Icon(
                      Icons.open_in_full,
                      color: context.onPrimaryContainer,
                    ),
                    child:
                        Text("content".tr, style: context.onPrimaryTextTheme.bodyMedium),
                  ),
                  WidgetConstant.height20,
                ],
              )),
      ConditionalWidget(
          enable: transactionData.metadata != null,
          onActive: (context) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("metadata".tr, style: context.textTheme.titleMedium),
                  WidgetConstant.height8,
                  ContainerWithBorder(
                    onRemove: () {
                      context.openDialogPage('',
                          child: (context) => JsonView(
                              text: transactionData.metadata!, title: 'metadata'.tr));
                    },
                    onRemoveIcon:
                        Icon(Icons.open_in_full, color: context.onPrimaryContainer),
                    child:
                        Text("content".tr, style: context.onPrimaryTextTheme.bodyMedium),
                  ),
                  WidgetConstant.height20,
                ],
              )),
      Text("transaction_content".tr, style: context.textTheme.titleMedium),
      WidgetConstant.height8,
      ContainerWithBorder(
        onRemove: () {
          context.openDialogPage('',
              child: (context) => JsonView(
                    text: transactionData.content,
                    title: "transaction_content".tr,
                  ));
        },
        onRemoveIcon: Icon(Icons.open_in_full, color: context.onPrimaryContainer),
        child: Text("content".tr, style: context.onPrimaryTextTheme.bodyMedium),
      ),
      WidgetConstant.height20,
      Text("transaction_fee".tr, style: context.textTheme.titleMedium),
      WidgetConstant.height8,
      ContainerWithBorder(
          child: CoinAndMarketPriceView(
              balance: transactionData.fee.fee,
              style: context.onPrimaryTextTheme.titleMedium,
              symbolColor: context.onPrimaryContainer,
              showTokenImage: true)),
    ]);
  }
}

class _InputView extends StatelessWidget {
  final Web3ADAInputDetails input;
  const _InputView(this.input);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ContainerWithBorder(
            backgroundColor: context.onPrimaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(input.input.txIdHex,
                          style: context.primaryTextTheme.bodyMedium),
                    ),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      ConditionalWidget(
                          enable: input.utxo != null,
                          onActive: (context) => TappedTooltipView(
                              tooltipWidget: ToolTipView(
                                  message: "account_input".tr,
                                  child: Icon(Icons.account_circle,
                                      color: context.primaryContainer)))),
                      ConditionalWidget(
                          enable: input.inputType == Web3ADAInputType.reference,
                          onActive: (context) => TappedTooltipView(
                              tooltipWidget: ToolTipView(
                                  message: "reference_input".tr,
                                  child: Icon(Icons.link,
                                      color: context.primaryContainer)))),
                      ConditionalWidget(
                          enable: input.inputType == Web3ADAInputType.collateral,
                          onActive: (context) => TappedTooltipView(
                              tooltipWidget: ToolTipView(
                                  message: "collateral_input".tr,
                                  child: Icon(Icons.shield_outlined,
                                      color: context.primaryContainer)))),
                    ]),
                  ],
                ),
              ],
            )),
      ],
    );
  }
}

class _AccountInputView extends StatelessWidget {
  final Web3ADAAccountInputDetails input;
  const _AccountInputView(this.input);

  @override
  Widget build(BuildContext context) {
    return ContainerWithBorder(
      backgroundColor: context.onPrimaryContainer,
      child: Column(
        children: [
          ContainerWithBorder(
              child: AddressDetailsView(
                  address: input.address, color: context.onPrimaryContainer)),
          ContainerWithBorder(
              child: CoinAndMarketPriceView(
            balance: input.totalLovelace,
            style: context.onPrimaryTextTheme.titleMedium,
            symbolColor: context.onPrimaryContainer,
            showTokenImage: true,
          )),
          ConditionalWidget(
              enable: input.totalAssets.isNotEmpty,
              onActive: (context) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      WidgetConstant.height20,
                      Text("assets".tr, style: context.primaryTextTheme.titleMedium),
                      WidgetConstant.height8,
                      ListView.builder(
                        shrinkWrap: true,
                        physics: WidgetConstant.noScrollPhysics,
                        itemCount: input.totalAssets.length,
                        itemBuilder: (context, index) {
                          final token = input.totalAssets[index];
                          return ContainerWithBorder(
                            child: CoinAndMarketPriceView(
                              balance: token.amount,
                              showTokenImage: true,
                              style: context.onPrimaryTextTheme.titleMedium,
                              symbolColor: context.onPrimaryContainer,
                            ),
                          );
                        },
                      ),
                    ],
                  ))
        ],
      ),
    );
  }
}

class _OutputView extends StatelessWidget {
  final Web3ADAOutputDetails output;
  const _OutputView(this.output);

  @override
  Widget build(BuildContext context) {
    return CustomizedContainer(
      enableTap: false,
      iconAlginment: CrossAxisAlignment.start,
      onTapStackIcon: output.isChange ? () {} : null,
      reverseColor: context.primaryContainer,
      onStackWidget: TappedTooltipView(
        triggerOnHover: true,
        tooltipWidget: ToolTipView(
          message: "amount_will_be_returned_back_to_account".tr,
          child: IgnorePointer(
            child: IconButton(
                onPressed: () {},
                icon: Icon(Icons.change_circle, color: context.onPrimaryContainer)),
          ),
        ),
      ),
      backgroundColor: context.onPrimaryContainer,
      child: Column(
        children: [
          ContainerWithBorder(
              child: ReceiptAddressDetailsView(
                  address: output.address, color: context.onPrimaryContainer)),
          ContainerWithBorder(
              child: CoinAndMarketPriceView(
            balance: output.lovelace,
            style: context.onPrimaryTextTheme.titleMedium,
            symbolColor: context.onPrimaryContainer,
            showTokenImage: true,
          )),
          ConditionalWidget(
              enable: output.assets.isNotEmpty,
              onActive: (context) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      WidgetConstant.height20,
                      Text("assets".tr, style: context.primaryTextTheme.titleMedium),
                      WidgetConstant.height8,
                      ListView.builder(
                        shrinkWrap: true,
                        physics: WidgetConstant.noScrollPhysics,
                        itemCount: output.assets.length,
                        itemBuilder: (context, index) {
                          final token = output.assets[index];
                          return ContainerWithBorder(
                            child: CoinAndMarketPriceView(
                                balance: token.amount,
                                showTokenImage: true,
                                style: context.onPrimaryTextTheme.titleMedium,
                                symbolColor: context.onPrimaryContainer),
                          );
                        },
                      ),
                    ],
                  ))
        ],
      ),
    );
  }
}

class _CertificateView extends StatelessWidget {
  final Web3ADACeriticateDatails certificate;

  const _CertificateView(this.certificate);

  @override
  Widget build(BuildContext context) {
    return ContainerWithBorder(
      backgroundColor: context.onPrimaryContainer,
      child: Column(
        children: [
          ContainerWithBorder(
              child: Text(certificate.type.name,
                  style: context.onPrimaryTextTheme.bodyMedium)),
          ContainerWithBorder(
            onRemove: () {
              context.openDialogPage(
                '',
                child: (context) =>
                    JsonView(text: certificate.content, title: 'certificate'.tr),
              );
            },
            onRemoveIcon: Icon(
              Icons.open_in_full,
              color: context.onPrimaryContainer,
            ),
            child: Text("content".tr, style: context.onPrimaryTextTheme.bodyMedium),
          ),
          ConditionalWidget(
              enable: certificate.signers.isNotEmpty,
              onActive: (context) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      WidgetConstant.height20,
                      Text("signers".tr, style: context.primaryTextTheme.titleMedium),
                      WidgetConstant.height8,
                      ListView.builder(
                        shrinkWrap: true,
                        physics: WidgetConstant.noScrollPhysics,
                        itemCount: certificate.signers.length,
                        itemBuilder: (context, index) {
                          final signer = certificate.signers[index];
                          return ContainerWithBorder(
                            child: ReceiptAddressDetailsView(
                                address: signer.signer,
                                color: context.onPrimaryContainer),
                          );
                        },
                      ),
                    ],
                  ))
        ],
      ),
    );
  }
}

class _MintView extends StatelessWidget {
  final Web3ADAAssetInputMintDetails mint;
  const _MintView(this.mint);

  @override
  Widget build(BuildContext context) {
    return ContainerWithBorder(
      backgroundColor: context.onPrimaryContainer,
      child: Column(
        children: [
          ConditionalWidget(
            enable: mint.signer != null,
            onActive: (context) => ContainerWithBorder(
                child: ReceiptAddressDetailsView(
                    address: mint.signer!.signer, color: context.onPrimaryContainer)),
          ),
          ContainerWithBorder(
              child: Text(mint.policyId, style: context.onPrimaryTextTheme.bodyMedium)),
          ConditionalWidget(
              enable: mint.assets.isNotEmpty,
              onActive: (context) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      WidgetConstant.height20,
                      Text("assets".tr, style: context.primaryTextTheme.titleMedium),
                      WidgetConstant.height8,
                      ListView.builder(
                        shrinkWrap: true,
                        physics: WidgetConstant.noScrollPhysics,
                        itemCount: mint.assets.length,
                        itemBuilder: (context, index) {
                          final token = mint.assets[index];

                          return ContainerWithBorder(
                            child: CoinAndMarketPriceView(
                              balance: token.amount,
                              showTokenImage: true,
                              style: context.onPrimaryTextTheme.titleMedium,
                              symbolColor: context.onPrimaryContainer,
                            ),
                          );
                        },
                      ),
                    ],
                  ))
        ],
      ),
    );
  }
}

class _WithdrawalView extends StatelessWidget {
  final Web3ADAWithdrawalDetails withdrawal;
  const _WithdrawalView(this.withdrawal);

  @override
  Widget build(BuildContext context) {
    return ContainerWithBorder(
      backgroundColor: context.onPrimaryContainer,
      child: Column(
        children: [
          ContainerWithBorder(
              child: ReceiptAddressDetailsView(
                  address: withdrawal.address, color: context.onPrimaryContainer)),
          ContainerWithBorder(
            child: CoinAndMarketPriceView(
                balance: withdrawal.amount,
                showTokenImage: true,
                style: context.onPrimaryTextTheme.titleMedium,
                symbolColor: context.onPrimaryContainer),
          )
        ],
      ),
    );
  }
}

class _VoteView extends StatelessWidget {
  final Web3ADAVoteDetails vote;
  const _VoteView(this.vote);

  @override
  Widget build(BuildContext context) {
    return ContainerWithBorder(
      backgroundColor: context.onPrimaryContainer,
      child: Column(
        children: [
          ContainerWithBorder(
              child: Text(vote.type.name, style: context.onPrimaryTextTheme.bodyMedium)),
          ConditionalWidget(
              enable: vote.signer != null,
              onActive: (context) => ReceiptAddressDetailsView(
                  address: vote.signer!.signer, color: context.onPrimaryContainer)),
          ContainerWithBorder(
            onRemoveIcon: Icon(Icons.open_in_full, color: context.onPrimaryContainer),
            onRemove: () {
              context.openDialogPage(
                '',
                child: (context) => JsonView(text: vote.content, title: 'vote'.tr),
              );
            },
            child: Text("content".tr, style: context.onPrimaryTextTheme.bodyMedium),
          )
        ],
      ),
    );
  }
}
