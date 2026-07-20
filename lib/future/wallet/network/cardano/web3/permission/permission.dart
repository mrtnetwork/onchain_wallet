import 'package:flutter/material.dart';
import 'package:on_chain/ada/ada.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/chain_permission.dart';
import 'package:on_chain_wallet/future/wallet/web3/pages/permission_view.dart';
import 'package:on_chain_wallet/future/widgets/widgets/text_widget.dart';
import 'package:on_chain_wallet/future/widgets/widgets/widget_constant.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/models/authenticated.dart';

class CardanoWeb3PermissionView extends StatefulWidget {
  const CardanoWeb3PermissionView({required this.application, super.key});
  final Web3ApplicationAuthentication application;

  @override
  State<CardanoWeb3PermissionView> createState() => _CardanoWeb3PermissionViewState();
}

class _CardanoWeb3PermissionViewState extends State<CardanoWeb3PermissionView>
    with
        SafeState,
        Web3PermissionState<
            CardanoWeb3PermissionView,
            ADAAddress,
            ADAChain,
            ICardanoAddress,
            Web3InternalADANetworkAccount,
            Web3InternalADANetwork,
            Web3InternalADAChain> {
  List<ICardanoAddress> rewardAddresses = [];
  List<ICardanoAddress> addresses = [];
  List<Web3InternalADANetworkAccount> rewardAccounts = [];
  @override
  Web3ApplicationAuthentication get application => widget.application;
  @override
  NetworkType get type => NetworkType.cardano;

  @override
  Web3InternalADANetworkAccount? createWeb3Account(ICardanoAddress address) {
    if (address.isRewardAddress) return null;
    assert(!address.isRewardAddress);
    return Web3InternalADANetworkAccount(
        derivationIndex: address.derivationIndex,
        identifier: address.identifier,
        type: Web3InternalADANetworkAccountType.payment);
  }

  @override
  Web3InternalADANetwork createWeb3Network(List<Web3InternalADANetworkAccount> address,
      Web3InternalADANetworkAccount? defaultAccount, int networkId) {
    final allAccounts = [...accounts, ...rewardAccounts];
    return Web3InternalADANetwork(
        accounts: allAccounts, networkId: networkId, defaultAccount: defaultAccount);
  }

  @override
  Web3InternalADAChain createWeb3Chain(
      List<Web3InternalADANetwork> networks, int defaultNetworkId) {
    return Web3InternalADAChain(networks: networks, defaultChain: defaultNetworkId);
  }

  @override
  void onChangeChain(ADAChain? updateChain, {bool notify = true}) {
    if (updateChain == null) return;
    super.onChangeChain(updateChain, notify: false);
    accounts = permission.accounts.where((e) => e.type.isPayment).toList();
    defaultAddress = accounts.firstWhereOrNull((e) => e == permission.defaultAccount) ??
        accounts.firstOrNull;
    addresses = chain.addresses.where((e) => !e.isRewardAddress).toList();
    rewardAddresses =
        chain.addresses.where((e) => e.isRewardAddress || e.isBaseAddress).toList();
    updateState();
  }

  @override
  void onAccountUpdated(ChainEvent event) {
    if (event.type == DefaultChainNotify.address &&
        event.status == ChainNotifyStatus.complete) {
      addresses = chain.addresses.where((e) => !e.isRewardAddress).toList();
      rewardAddresses =
          chain.addresses.where((e) => e.isRewardAddress || e.isBaseAddress).toList();
      updateState();
    }
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    rewardAccounts = permission.accounts.where((e) => e.type.isReward).toList();
    accounts = permission.accounts.where((e) => e.type.isPayment).toList();
    defaultAddress = accounts.firstWhereOrNull((e) => e == permission.defaultAccount) ??
        accounts.firstOrNull;
    addresses = chain.addresses.where((e) => !e.isRewardAddress).toList();
    rewardAddresses =
        chain.addresses.where((e) => e.isRewardAddress || e.isBaseAddress).toList();
  }

  bool hasRewardPermission(ICardanoAddress address) {
    final web3Account = rewardAccounts.firstWhereOrNull((e) =>
        e.identifier == address.identifier &&
        e.derivationIndex == (address.rewardKeyIndex ?? address.derivationIndex));
    return web3Account != null;
  }

  void addRewardAccount(ICardanoAddress address) {
    assert(address.isRewardAddress || address.isBaseAddress);
    if (!address.isRewardAddress && !address.isBaseAddress) {
      return;
    }
    final web3Account = rewardAccounts.firstWhereOrNull((e) =>
        e.identifier == address.identifier &&
        e.derivationIndex == (address.rewardKeyIndex ?? address.derivationIndex));
    if (!rewardAccounts.remove(web3Account)) {
      final newAccount = Web3InternalADANetworkAccount(
          derivationIndex: address.rewardKeyIndex ?? address.derivationIndex,
          identifier: address.identifier,
          type: Web3InternalADANetworkAccountType.reward);
      rewardAccounts.add(newAccount);
    }
    updateState();
  }

  @override
  Widget build(BuildContext context) {
    return UpdateChainPermissionWidget<ADAAddress, ICardanoAddress, ADAChain>(
      chain: chain,
      isDefaultAddress: isDefaultAddress,
      chains: chains,
      onUpdateState: updateState,
      hasPermission: hasPermission,
      addAccount: addAccount,
      onChangeChain: onChangeChain,
      onChangeDefaultAccount: onChangeDefaultPermission,
      activities: activities,
      addresses: addresses,
      menuItems: menuItems,
      extraPages: {
        "reward_address".tr: (context) =>
            SelectWeb3PermissionAccountView<ADAAddress, ICardanoAddress, ADAChain>(
              chain: chain,
              addresses: rewardAddresses,
              hasPermission: hasRewardPermission,
              addAccount: addRewardAccount,
              addressWidget: (p0, address) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (address.accountName != null || address.type != null)
                    address.accountName != null
                        ? RichText(
                            maxLines: 1,
                            text: TextSpan(children: [
                              TextSpan(
                                  text: address.accountName,
                                  style: context.onPrimaryTextTheme.labelLarge),
                              if (address.type != null)
                                TextSpan(
                                    text: " (${address.type!.tr})",
                                    style: context.onPrimaryTextTheme.bodySmall)
                            ]))
                        : address.type == null
                            ? WidgetConstant.sizedBox
                            : Text(address.type!.tr,
                                style: context.onPrimaryTextTheme.labelLarge),
                  OneLineTextWidget(address.rewardAddress?.address ?? address.address,
                      style: context.onPrimaryTextTheme.bodyMedium),
                ],
              ),
            )
      },
    );
  }
}
