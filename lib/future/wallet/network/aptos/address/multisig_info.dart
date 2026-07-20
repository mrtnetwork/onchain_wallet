import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/security/pages/accsess_wallet.dart';
import 'package:on_chain_wallet/wallet/models/networks/aptos/aptos.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class AptosMultisigAccountInfoView extends StatelessWidget {
  const AptosMultisigAccountInfoView({super.key});

  @override
  Widget build(BuildContext context) {
    return AccessWalletView<WalletCredentialResponseLogin, WalletCredentialLogin>(
      request: WalletCredentialLogin.instance,
      title: "multisig_address_infos".tr,
      onAccsess: (_) {
        return NetworkAccountControllerView<AptosNetworkClient?, IAptosAddress,
            AptosChain>(
          addressRequired: true,
          clientRequired: false,
          childBulder: (wallet, chain, client, account) {
            return _AptosMultisigAccountInfoView(chain);
          },
        );
      },
    );
  }
}

class _AptosMultisigAccountInfoView extends StatefulWidget {
  final AptosChain account;
  const _AptosMultisigAccountInfoView(this.account);

  @override
  State<_AptosMultisigAccountInfoView> createState() =>
      __AptosMultisigAccountInfoViewState();
}

class __AptosMultisigAccountInfoViewState
    extends AptosAccountState<_AptosMultisigAccountInfoView> {
  @override
  AptosChain get account => widget.account;

  final StreamPageProgressController progressKey =
      StreamPageProgressController(initialStatus: StreamWidgetStatus.progress);

  List<_AptosMultisigAccountInfo> keyInfos = [];
  @override
  late final IAptosMultiSigAddress address;
  late final int threshold;

  Future<void> _init() async {
    if (!account.haveAddress || !account.addressSync.multiSigAccount) {
      progressKey.errorText("invalid_account".tr);
      return;
    }
    address = account.addressSync.cast();
    threshold = address.multiSignatureAddress.requiredSignature;
    keyInfos = address.multiSignatureAddress.publicKeys
        .map((e) => _AptosMultisigAccountInfo(
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
                  ConditionalWidgets(enable: address.keyScheme, widgets: {
                    AptosSupportKeyScheme.multiEd25519: (context) =>
                        Text("threshold".tr, style: context.textTheme.titleMedium),
                    AptosSupportKeyScheme.multiKey: (context) => Text(
                        "required_signature".tr,
                        style: context.textTheme.titleMedium)
                  }),
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

class _AptosMultisigAccountInfo {
  final IAptosAddress? address;
  final String publicKey;
  final Bip32DerivationIndex keyIndex;
  const _AptosMultisigAccountInfo(
      {required this.address, required this.publicKey, required this.keyIndex});
}

class _ShowAddressView extends StatelessWidget {
  final _AptosMultisigAccountInfo account;
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
                  OneLineTextWidget(account.publicKey,
                      style: context.primaryTextTheme.titleMedium),
                  AddressDrivationInfo(account.keyIndex, color: context.primaryContainer),
                ],
              ),
            )),
      ]),
    );
  }
}
