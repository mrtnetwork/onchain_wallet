import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/router/page_router.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/controller.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';

import 'package:on_chain_wallet/wallet/wallet.dart';

enum TokenAction { delete, transfer }

typedef TOKENTRANSFERBUILDER<T extends TokenCore> = TransactionStateController Function(
    T);

class TokenDetailsModalView<TOKEN extends TokenCore,
    CHAINACCOUNT extends APPCHAINTOKEN<TOKEN>> extends StatelessWidget {
  const TokenDetailsModalView({
    super.key,
    required this.token,
    required this.address,
    required this.account,
    required this.transferBuilder,
    required this.addressTokens,
  });
  final TOKENTRANSFERBUILDER<TOKEN> transferBuilder;
  final TOKEN token;
  final List<TOKEN> addressTokens;
  final CHAINACCOUNT address;
  final APPCHAINACCOUNT<CHAINACCOUNT> account;
  @override
  Widget build(BuildContext context) {
    return ChainStreamBuilder(
        allowNotify: [DefaultChainNotify.token],
        builder: (context, _) {
          final currentToken = addressTokens
              .whereType<TOKEN>()
              .firstWhere((e) => e.identifier == token.identifier, orElse: () => token);
          final addr = account.network.getAccountExplorer(currentToken.issuer);
          return CustomScrollView(
            shrinkWrap: true,
            slivers: [
              SliverAppBar(
                title: Text("token_info".tr),
                leading: WidgetConstant.sizedBox,
                leadingWidth: 0,
                pinned: true,
                actions: [
                  if (addr != null) LaunchBrowserIcon(url: addr, size: APPConst.double20),
                  IconButton(
                      onPressed: () {
                        context.openMaxExtendSliverBottomSheet<bool>("update_token".tr,
                            bodyBuilder: (scrollController) => UpdateTokenDetailsView(
                                token: currentToken.token,
                                accountToken: currentToken,
                                account: account,
                                address: address,
                                scrollController: scrollController),
                            centerContent: false);
                      },
                      icon: const Icon(Icons.edit)),
                  IconButton(
                      onPressed: () {
                        context.openSliverDialog(
                            widget: (ctx) => DialogTextView(
                                buttonWidget: AsyncDialogDoubleButtonView(
                                  firstButtonPressed: () => account
                                      .removeToken(token: currentToken, address: address)
                                      .then((value) {
                                    value.watch(
                                        onErr: (err) =>
                                            context.showAlert(err.localizationError),
                                        onOk: (_) => context.pop());
                                  }),
                                ),
                                text: "remove_token_from_account".tr),
                            label: "remove_token".tr);
                      },
                      icon: Icon(Icons.delete, color: context.colors.error)),
                  const CloseButton(),
                  WidgetConstant.width8,
                ],
              ),
              SliverToBoxAdapter(
                child: ConstraintsBoxView(
                  padding: WidgetConstant.padding20,
                  child: _TokenDetailsView<TOKEN>(
                    token: currentToken,
                    address: address,
                    transferBuilder: transferBuilder,
                  ),
                ),
              ),
            ],
          );
        },
        account: account);
  }
}

class _TokenDetailsView<T extends TokenCore> extends StatelessWidget {
  const _TokenDetailsView(
      {required this.token, required this.address, required this.transferBuilder});
  final T token;
  final ChainAccount address;
  final TOKENTRANSFERBUILDER<T> transferBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: AddressDetailsView(address: address, showBalance: false)),
          ],
        ),
        WidgetConstant.divider,
        CircleTokenImageView(token.token, radius: 60),
        WidgetConstant.height8,
        Text(token.token.nameView, style: context.textTheme.labelLarge),
        WidgetConstant.height8,
        CoinAndMarketLivePriceView(
            liveBalance: token.streamBalance, style: context.textTheme.titleLarge),
        WidgetConstant.height20,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FloatingActionButton(
              onPressed: () {
                final builder = transferBuilder;
                final operation = builder(token);
                context.offTo(PageRouter.transaction, argruments: operation);
              },
              child: const Icon(Icons.upload),
            ),
            WidgetConstant.width8,
            FloatingActionButton(
              onPressed: () {
                context.openDialogPage('',
                    child: (context) => BarcodeImageView(
                          data: address.address,
                          name: address.address,
                        ),
                    maxWidth: APPConst.qrCodeWidth);
              },
              child: const Icon(Icons.download),
            )
          ],
        )
      ],
    );
  }
}
