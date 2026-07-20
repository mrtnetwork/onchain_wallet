import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/future/router/page_router.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/extension.dart';
import 'package:on_chain_wallet/future/wallet/network/network.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';

class AccountPageSliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final WalletProvider wallet;
  final Chain account;
  AccountPageSliverHeaderDelegate({required this.account, required this.wallet});
  bool get bottom => wallet.wallet.isOpen && account.haveAddress;
  PreferredSizeWidget get bottomWidget =>
      TabBar(tabs: account.services.map((e) => Tab(text: e.tr)).toList());
  final double accountSize = 150;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final enabled = shrinkOffset + minExtent > accountSize;
    return AppBar(
      bottom: bottomWidget,
      surfaceTintColor: context.colors.transparent,
      backgroundColor: context.colors.surface,
      foregroundColor: context.colors.onSurface,
      automaticallyImplyLeading: false,
      flexibleSpace: Stack(
        children: [
          APPAnimatedSwitcher(enable: enabled, widgets: {
            true: (c) => APPAnimatedContainer(
                alignment: Alignment.topCenter,
                isActive: bottom,
                onActive: (c) => _AccountMenuButtonView(wallet: wallet, account: account),
                onDeactive: (p0) => WidgetConstant.sizedBox),
            false: (c) => Align(
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                    physics: WidgetConstant.noScrollPhysics,
                    child: Padding(
                      padding: WidgetConstant.padding20,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleTokenImageView(account.network.coinParam.token,
                              radius: 40),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      CoinAndMarketLivePriceView(
                                          liveBalance:
                                              account.addressSync.addressData.balance,
                                          style: context.textTheme.titleLarge),
                                      WidgetConstant.height15,
                                      _AccountButtons(account)
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _AccountPopupMenu(wallet: wallet, account: account)
                        ],
                      ),
                    ),
                  ),
                )
          }),
        ],
      ),
    );
  }

  @override
  double get maxExtent => (accountSize + bottomWidget.preferredSize.height);

  @override
  double get minExtent => (90 + bottomWidget.preferredSize.height);

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

class _AccountButtons extends StatelessWidget {
  const _AccountButtons(this.account);
  final Chain account;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filled(
            onPressed: () {
              context.openDialogPage('',
                  child: (context) => BarcodeImageView(
                        data: account.addressSync.address,
                        name: account.addressSync.address,
                      ),
                  maxWidth: APPConst.qrCodeWidth);
            },
            icon: const Icon(Icons.download)),
        WidgetConstant.width8,
        IconButton.filled(
            onPressed: () {
              final wallet = context.wallet;
              final operation = switch (account.network.type) {
                NetworkType.aptos => AptosTransactionTransferOperation(
                    walletProvider: wallet,
                    account: account.cast<AptosChain>(),
                    address: account.cast<AptosChain>().addressSync),
                NetworkType.bitcoinCash ||
                NetworkType.bitcoinAndForked =>
                  BitcoinTransactionTransferOperation(
                      walletProvider: wallet,
                      account: account.cast<BitcoinChain>(),
                      address: account.cast<BitcoinChain>().addressSync),
                NetworkType.ethereum => EthereumTransactionTransferOperation(
                    walletProvider: wallet,
                    account: account.cast<EthereumChain>(),
                    address: account.cast<EthereumChain>().addressSync),
                NetworkType.xrpl => RippleTransactionPaymentOperation(
                    walletProvider: wallet,
                    account: account.cast<XRPChain>(),
                    address: account.cast<XRPChain>().addressSync),
                NetworkType.cardano => ADATransactionTransferOperation(
                    walletProvider: wallet,
                    account: account.cast<ADAChain>(),
                    address: account.cast<ADAChain>().addressSync),
                NetworkType.cosmos => CosmosTransactionTransferOperation(
                    walletProvider: wallet,
                    account: account.cast<CosmosChain>(),
                    address: account.cast<CosmosChain>().addressSync),
                NetworkType.monero => MoneroTransactionTransferOperation(
                    walletProvider: wallet,
                    account: account.cast<MoneroChain>(),
                    address: account.cast<MoneroChain>().addressSync),
                NetworkType.solana => SolanaTransactionTransferOperation(
                    walletProvider: wallet,
                    account: account.cast<SolanaChain>(),
                    address: account.cast<SolanaChain>().addressSync),
                NetworkType.stellar => StellarTransactionStateController(
                    walletProvider: wallet,
                    account: account.cast<StellarChain>(),
                    address: account.cast<StellarChain>().addressSync),
                NetworkType.substrate => SubstrateTransactionTransferOperation(
                    walletProvider: wallet,
                    account: account.cast<SubstrateChain>(),
                    address: account.cast<SubstrateChain>().addressSync),
                NetworkType.ton => TonTransactionTransferOperation(
                    walletProvider: wallet,
                    account: account.cast<TonChain>(),
                    address: account.cast<TonChain>().addressSync),
                NetworkType.tron => TronTransactionTransferOperation(
                    walletProvider: wallet,
                    account: account.cast<TronChain>(),
                    address: account.cast<TronChain>().addressSync),
                NetworkType.sui => SuiTransactionTransferOperation(
                    walletProvider: wallet,
                    account: account.cast<SuiChain>(),
                    address: account.cast<SuiChain>().addressSync),
                NetworkType.zcash => ZcashTransactionTransferOperation(
                    walletProvider: wallet,
                    account: account.cast<ZcashChain>(),
                    address: account.cast<ZcashChain>().addressSync),
              };
              context.to(PageRouter.transaction, argruments: operation);
            },
            icon: const Icon(Icons.upload)),
        WidgetConstant.width8,
        IconButton.filled(
            onPressed: () {
              context
                  .selectOrSwitchAccount<ChainAccount>(
                      account: account, showMultiSig: true, isSwitch: true)
                  .then((e) {
                if (e == null) return;
                account.switchAccount(e).then((e) {
                  e.watch(onErr: (e) {
                    context.showAlert(e.localizationError);
                  });
                });
              });
            },
            icon: const Icon(Icons.switch_account)),
      ],
    );
  }
}

class _AccountMenuButtonView extends StatelessWidget {
  const _AccountMenuButtonView({required this.account, required this.wallet});
  final WalletProvider wallet;
  final Chain account;
  ChainAccount get address => account.addressSync;

  @override
  Widget build(BuildContext context) {
    final bool hasAccountNameOrType = address.accountName != null || address.type != null;
    final bool showMultiSig = address.multiSigAccount && !hasAccountNameOrType;
    return InkWell(
      onTap: () {
        context
            .selectOrSwitchAccount<ChainAccount>(
                account: account, showMultiSig: true, isSwitch: true)
            .then((e) {
          if (e == null) return;
          account.switchAccount(e).then((e) {
            e.watch(onErr: (e) {
              context.showAlert(e.localizationError);
            });
          });
        });
      },
      child: SizedBox(
        height: 90,
        child: Padding(
          padding: WidgetConstant.paddingHorizontal10,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleTokenImageView(account.network.token,
                  radius: APPConst.circleRadius25),
              WidgetConstant.width8,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasAccountNameOrType)
                      address.accountName != null
                          ? RichText(
                              maxLines: 1,
                              text: TextSpan(children: [
                                TextSpan(
                                    text: address.accountName,
                                    style: context.textTheme.labelLarge),
                                if (address.type != null)
                                  TextSpan(
                                      text: " (${address.type!.tr})",
                                      style: context.textTheme.bodySmall)
                              ]))
                          : Text(
                              address.accountName ?? address.type!.tr,
                              style: context.textTheme.labelLarge,
                            ),
                    if (showMultiSig)
                      Text("multi_signature".tr, style: context.textTheme.bodyMedium),
                    OneLineTextWidget(
                      address.address,
                      style: context.textTheme.bodyMedium,
                    ),
                    CoinAndMarketLivePriceView(
                      liveBalance: account.addressSync.addressData.balance,
                      style: context.textTheme.titleMedium,
                      enableMarketPrice: true,
                    ),
                  ],
                ),
              ),
              _AccountPopupMenu(wallet: wallet, account: account)
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountPopupMenu extends StatelessWidget {
  const _AccountPopupMenu({required this.wallet, required this.account});
  final WalletProvider wallet;
  final Chain account;
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
        tooltip: "account_options".tr,
        iconColor: context.colors.onSurface,
        constraints: WidgetConstant.constraintsMinWidth200,
        onSelected: (v) {
          switch (v) {
            case 0:
              context.to(PageRouter.exportPrivateKey, argruments: account.addressSync);
              break;
            case 1:
              context.to(PageRouter.showPublicKey, argruments: account.addressSync);
              break;
            case 2:
              final address = account.addressSync;
              context
                  .openSliverBottomSheet<String>(
                    "account_name".tr,
                    child: StringWriterView(
                      defaultValue: address.accountName,
                      regExp: APPConst.accountNameRegExp,
                      title: PageTitleSubtitle(
                          title: "setup_or_update_account_name".tr,
                          body: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("setup_or_update_account_name".tr),
                              WidgetConstant.height8,
                              Text("remove_account_name_desc".tr),
                            ],
                          )),
                      buttonText: "setup_input".tr,
                      label: "account_name".tr,
                    ),
                  )
                  .then((value) => account
                      .setupAccountName(name: value, address: address)
                      .then((e) => e.watch(
                          onErr: (err) => context.showAlert(err.localizationError))));
              break;
            case 3:
              context.to(PageRouter.removeAccount, argruments: account);
              break;
            case 8:
              context.to(PageRouter.multisigAccountInfo(account.network.type),
                  argruments: account);
              break;
            case 4:
              final accountUrl =
                  account.network.getAccountExplorer(account.addressSync.address);
              context.appContext.platformUtls.lunchUri(accountUrl);
              break;
            case 5:
              context.appContext.platformUtls
                  .lunchUri(account.network.coinParam.marketUri);
              break;
            case 7:
              context
                  .openSliverDialog<bool>(
                      widget: (context) {
                        return DialogTextView(
                            widget: const _RemoveChainDialog(),
                            buttonWidget: DialogDoubleButtonView());
                      },
                      label: 'remove_network'.tr)
                  .then((v) {
                if (v != true) return;
                wallet.wallet
                    .doAction(WalletActionRemoveAccount(account: account))
                    .then((e) {
                  if (e.isErr) context.showAlert(e.unwrapErr().localizationError);
                });
              });
              break;
            case 6:
              context.to(PageRouter.updateNetwork);
              break;
            case 9:
              context.to(PageRouter.setupGenericAddress, argruments: account);
              break;
            default:
          }
        },
        itemBuilder: (context) {
          final address = account.addressSync;
          final accountUrl = account.network.getAccountExplorer(address.address);
          bool isMultisig = address.multiSigAccount;
          bool isSubsctrate = account.network.type == NetworkType.substrate;
          return [
            ..._chainCustomButton(account: account, context: context, value: 20),
            PopupMenuItem<int>(
              value: 9,
              child: AppListTile(
                trailing: const Icon(Icons.add_box),
                title: Text("setup_new_address".tr, style: context.textTheme.labelMedium),
              ),
            ),
            if (!isMultisig)
              PopupMenuItem<int>(
                value: 0,
                child: AppListTile(
                  trailing: const Icon(Icons.north_east_sharp),
                  title:
                      Text("export_private_key".tr, style: context.textTheme.labelMedium),
                ),
              ),
            if (!(isMultisig && isSubsctrate))
              PopupMenuItem<int>(
                value: 1,
                child: AppListTile(
                  trailing: const Icon(Icons.north_east_sharp),
                  title: Text("address_info".tr, style: context.textTheme.labelMedium),
                ),
              ),
            if (address.iAddressType.isMultisigByPublicKey)
              PopupMenuItem<int>(
                value: 8,
                child: AppListTile(
                  trailing: const Icon(Icons.north_east_sharp),
                  title: Text("multisig_address_infos".tr,
                      style: context.textTheme.labelMedium),
                ),
              ),
            PopupMenuItem<int>(
              value: 2,
              child: AppListTile(
                trailing: const Icon(Icons.edit),
                title: Text("account_name".tr, style: context.textTheme.labelMedium),
              ),
            ),
            PopupMenuItem<int>(
              value: 3,
              child: AppListTile(
                  trailing: const Icon(Icons.remove),
                  title: Text("remove_account".tr, style: context.textTheme.labelMedium)),
            ),
            if (accountUrl != null)
              PopupMenuItem<int>(
                value: 4,
                child: AppListTile(
                  trailing: const Icon(Icons.open_in_new),
                  title:
                      Text("view_on_explorer".tr, style: context.textTheme.labelMedium),
                ),
              ),
            if (account.network.coinParam.hasMarketUrl)
              PopupMenuItem<int>(
                value: 5,
                child: AppListTile(
                  trailing: CircleAssetsImageView(CoinGeckoUtils.logo, radius: 12),
                  title: Text("CoinGecko".tr, style: context.textTheme.labelMedium),
                ),
              ),
            PopupMenuItem<int>(
              value: 6,
              child: AppListTile(
                  trailing: const Icon(Icons.edit),
                  title: Text("update_network".tr, style: context.textTheme.labelMedium)),
            ),
            if (account.network.isImportedNetwork) ...[
              PopupMenuItem<int>(
                value: 7,
                child: AppListTile(
                  trailing: const Icon(Icons.remove),
                  title: Text("remove_network".tr, style: context.textTheme.labelMedium),
                ),
              ),
            ],
          ];
        });
  }
}

List<PopupMenuItem<int>> _chainCustomButton(
    {required Chain account, required BuildContext context, required int value}) {
  return switch (account.network.type) {
    NetworkType.cardano =>
      cardanoAccountMenuButton(account: account.cast(), context: context, value: value),
    NetworkType.zcash =>
      zcashAccountMenuButton(account: account.cast(), context: context, value: value),
    NetworkType.cosmos =>
      cosmosAccountMenuButton(account: account.cast(), context: context, value: value),
    _ => []
  };
}

class _RemoveChainDialog extends StatelessWidget {
  const _RemoveChainDialog();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("remove_network_desc2".tr, style: context.textTheme.titleMedium),
        Text("remove_network_desc".tr),
      ],
    );
  }
}
