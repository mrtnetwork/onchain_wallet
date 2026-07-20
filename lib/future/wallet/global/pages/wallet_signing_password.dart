import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/address_details.dart';
import 'package:on_chain_wallet/future/wallet/security/pages/login.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/crypto/crypto.dart' show DerivableIndex;
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

typedef ONSIGNINGCREDENTIAL = Future<WalletCredentialResponseVerify> Function(
    WalletCredentialRequest<WalletCredentialResponseVerify> request);

class WalletSigningPassword extends StatefulWidget {
  const WalletSigningPassword(
      {super.key, required this.keys, required this.addresses, required this.controller});
  final Set<DerivableIndex> keys;
  final Set<ChainAccount> addresses;
  final ScrollController controller;

  @override
  State<WalletSigningPassword> createState() => _WalletSigningPasswordState();
}

class _WalletSigningPasswordState extends State<WalletSigningPassword> with SafeState {
  @override
  Widget build(BuildContext context) {
    return WalletLoginView<WalletCredentialResponseVerify, WalletCredentialVerify>(
        controller: widget.controller,
        onWalletAccess: (credential) => context.pop(credential),
        request: WalletCredentialVerify(),
        appBar: AppBar(title: Text("signing_request".tr)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          PageTitleSubtitle(
              title: "signing_request".tr,
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("signing_tx_desc1".tr),
                  WidgetConstant.height8,
                  Text("signing_tx_desc".tr)
                ],
              )),
          WidgetConstant.height20,
          ConditionalWidget(
              enable: widget.addresses.isNotEmpty,
              onActive: (context) =>
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("accounts".tr, style: context.textTheme.titleMedium),
                    WidgetConstant.height8,
                    ConditionalWidget(
                      enable: widget.addresses.length > 1,
                      onActive: (context) => APPExpansionListTile(
                          title: Text(
                              "transaction_generated_with_number_accounts"
                                  .tr
                                  .replaceOne(widget.addresses.length.toString()),
                              style: context.onPrimaryTextTheme.bodyMedium),
                          children: [
                            ListView.separated(
                              separatorBuilder: (context, index) =>
                                  Divider(color: context.onPrimaryContainer),
                              itemCount: widget.addresses.length,
                              shrinkWrap: true,
                              physics: WidgetConstant.noScrollPhysics,
                              itemBuilder: (context, index) {
                                final address = widget.addresses.elementAt(index);
                                return ContainerWithBorder(
                                  backgroundColor: context.onPrimaryContainer,
                                  child: AddressDetailsView(
                                      address: address, color: context.primaryContainer),
                                );
                              },
                            )
                          ]),
                      onDeactive: (context) => ContainerWithBorder(
                        child: AddressDetailsView(
                            address: widget.addresses.first,
                            color: context.onPrimaryContainer),
                      ),
                    ),
                    WidgetConstant.height20,
                  ])),
          ConditionalWidget(
            enable: widget.keys.isNotEmpty,
            onActive: (context) =>
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("private_keys".tr, style: context.textTheme.titleMedium),
              Text("private_keys__signing_access_desc".tr),
              WidgetConstant.height8,
              ConditionalWidget(
                  enable: widget.keys.length > 1,
                  onDeactive: (context) => ContainerWithBorder(
                        child: _HDWalletDerivationDetails(
                            keyIndex: widget.keys.first,
                            color: context.onPrimaryContainer),
                      ),
                  onActive: (context) => APPExpansionListTile(
                        title: Text(
                            "transaction_need_number_private_key_to_complete"
                                .tr
                                .replaceOne(widget.keys.length.toString()),
                            style: context.onPrimaryTextTheme.bodyMedium),
                        children: [
                          ListView.separated(
                            separatorBuilder: (context, index) => Divider(
                              color: context.onPrimaryContainer,
                            ),
                            itemCount: widget.keys.length,
                            shrinkWrap: true,
                            physics: WidgetConstant.noScrollPhysics,
                            itemBuilder: (context, index) {
                              final keyIndex = widget.keys.elementAt(index);
                              return ContainerWithBorder(
                                  backgroundColor: context.onPrimaryContainer,
                                  child: _HDWalletDerivationDetails(
                                      keyIndex: keyIndex,
                                      color: context.primaryContainer));
                            },
                          )
                        ],
                      )),
            ]),
          ),
          WidgetConstant.height40
        ]));
  }
}

class _HDWalletDerivationDetails extends StatelessWidget {
  const _HDWalletDerivationDetails({required this.keyIndex, this.color});
  final DerivableIndex keyIndex;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(keyIndex.currencyCoin.conf.type.name.camelCase,
            style: context.textTheme.labelLarge?.copyWith(color: color)),
        AddressDrivationInfo(keyIndex, color: color),
      ],
    );
  }
}

//
