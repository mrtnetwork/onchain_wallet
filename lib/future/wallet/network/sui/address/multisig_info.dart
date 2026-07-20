import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/security/pages/accsess_wallet.dart';
import 'package:on_chain_wallet/wallet/api/client/client.dart';
import 'package:on_chain_wallet/wallet/models/access/wallet_access.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';

class SuiMultisigAccountInfoView extends StatelessWidget {
  const SuiMultisigAccountInfoView({super.key});

  @override
  Widget build(BuildContext context) {
    return AccessWalletView<WalletCredentialResponseLogin, WalletCredentialLogin>(
      request: WalletCredentialLogin.instance,
      title: "multisig_address_infos".tr,
      onAccsess: (_) {
        return NetworkAccountControllerView<SuiNetworkClient?, ISuiAddress?, SuiChain>(
          addressRequired: true,
          clientRequired: false,
          childBulder: (wallet, account, client, address) {
            return _SuiMultisigAccountInfoView(account);
          },
        );
      },
    );
  }
}

class _SuiMultisigAccountInfoView extends StatefulWidget {
  final SuiChain account;
  const _SuiMultisigAccountInfoView(this.account);

  @override
  State<_SuiMultisigAccountInfoView> createState() => __SuiMultisigAccountInfoViewState();
}

class __SuiMultisigAccountInfoViewState
    extends SuiAccountState<_SuiMultisigAccountInfoView> {
  final StreamPageProgressController progressKey =
      StreamPageProgressController(initialStatus: StreamWidgetStatus.progress);
  @override
  SuiChain get account => widget.account;
  List<_SuiMultisigAccountInfo> keyInfos = [];
  @override
  late final ISuiMultiSigAddress address;
  late final int threshold;

  Future<void> _init() async {
    if (!account.haveAddress || !account.addressSync.multiSigAccount) {
      progressKey.errorText("invalid_account".tr);
      return;
    }
    address = account.addressSync.cast();
    threshold = address.multiSignatureAddress.threshold;
    keyInfos = address.multiSignatureAddress.publicKeys
        .map((e) => _SuiMultisigAccountInfo(
            weight: e.weight,
            address:
                addresses.firstWhereOrNull((i) => i.derivationIndex == e.derivationIndex),
            publicKey: e.toHex(),
            keyIndex: e.derivationIndex))
        .toList();
    progressKey.backToIdle();
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    MethodUtils.executeAfterDelay(() => _init());
  }

  @override
  void safeDispose() {
    super.safeDispose();
    progressKey.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamPageProgress(
      controller: progressKey,
      initialWidget: ProgressWithTextView(text: "retrieve_account_informations".tr),
      builder: (context) {
        return CustomScrollView(slivers: [
          SliverConstraintsBoxView(
              padding: WidgetConstant.paddingHorizontal20,
              sliver: SliverToBoxAdapter(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("address".tr, style: context.textTheme.titleMedium),
                  WidgetConstant.height8,
                  ContainerWithBorder(child: AddressDetailsView(address: address)),
                  WidgetConstant.height20,
                  Text("threshold".tr, style: context.textTheme.titleMedium),
                  WidgetConstant.height8,
                  ContainerWithBorder(
                      onRemoveIcon: Icon(Icons.edit, color: context.onPrimaryContainer),
                      child: Text(threshold.toString(),
                          style: context.onPrimaryTextTheme.titleMedium)),
                  WidgetConstant.height20,
                  Text("list_of_public_keys".tr, style: context.textTheme.titleMedium),
                  WidgetConstant.height8,
                  ListView.separated(
                      shrinkWrap: true,
                      physics: WidgetConstant.noScrollPhysics,
                      itemBuilder: (context, index) {
                        return _ShowAddressView(account: keyInfos[index]);
                      },
                      separatorBuilder: (context, index) => WidgetConstant.divider,
                      itemCount: keyInfos.length)
                ],
              )))
        ]);
      },
    );
  }
}

class _SuiMultisigAccountInfo {
  final ISuiAddress? address;
  final String publicKey;
  final Bip32DerivationIndex keyIndex;
  final int weight;
  const _SuiMultisigAccountInfo(
      {required this.address,
      required this.publicKey,
      required this.keyIndex,
      required this.weight});
}

class _ShowAddressView extends StatelessWidget {
  final _SuiMultisigAccountInfo account;
  const _ShowAddressView({required this.account});
  @override
  Widget build(BuildContext context) {
    return ContainerWithBorder(
      iconAlginment: CrossAxisAlignment.start,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (account.address != null) ...[
          Text("account".tr, style: context.onPrimaryTextTheme.labelLarge),
          WidgetConstant.height8,
          ContainerWithBorder(
            backgroundColor: context.onPrimaryContainer,
            child: AddressDetailsView(
                address: account.address!, color: context.colors.primaryContainer),
          ),
          WidgetConstant.height20,
        ],
        Text("public_key".tr, style: context.onPrimaryTextTheme.labelLarge),
        WidgetConstant.height8,
        ContainerWithBorder(
            backgroundColor: context.onPrimaryContainer,
            child: CopyableTextWidget(
              text: account.publicKey,
              color: context.primaryContainer,
              widget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AddressDrivationInfo(account.keyIndex, color: context.primaryContainer),
                  OneLineTextWidget(account.publicKey,
                      style: context.primaryTextTheme.titleMedium)
                ],
              ),
            )),
        WidgetConstant.height20,
        Text("weight".tr, style: context.onPrimaryTextTheme.labelLarge),
        WidgetConstant.height8,
        ContainerWithBorder(
            backgroundColor: context.onPrimaryContainer,
            child: Text(account.weight.toString(),
                style: context.primaryTextTheme.titleMedium))
      ]),
    );
  }
}
