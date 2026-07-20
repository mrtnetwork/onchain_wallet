import 'package:flutter/material.dart';

import 'package:on_chain_wallet/app/core.dart' show APPConst;
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/read_account_public_keys_response.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/helper/ton_workchain.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/address_details.dart';
import 'package:on_chain_wallet/future/wallet/security/pages/accsess_wallet.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/models/account/account.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/crypto/wallet/keys.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';

class AccountPublicKeyView extends StatelessWidget {
  const AccountPublicKeyView({super.key});

  @override
  Widget build(BuildContext context) {
    final ChainAccount account = context.getArgruments();
    return AccessWalletView<WalletCredentialResponseLogin, WalletCredentialLogin>(
        request: WalletCredentialLogin.instance,
        onAccsess: (credential) => _BipAccountPublicKey(account: account),
        title: "account_keys".tr,
        subtitle: PageTitleSubtitle(
            title: "unlock_wallet".tr, body: Text("unlock_access_desc".tr)));
  }
}

class _BipAccountPublicKey extends StatefulWidget {
  const _BipAccountPublicKey({required this.account});
  final ChainAccount account;
  @override
  State<_BipAccountPublicKey> createState() => __BipAccountPublicKeyState();
}

class __BipAccountPublicKeyState extends State<_BipAccountPublicKey>
    with SafeState<_BipAccountPublicKey> {
  List<_ViweAccountKey> keys = [];
  late _ViweAccountKey selectedKey;
  late ReadAccountPublicKeysResponse accoutInfo;
  ChainAccount get account => widget.account;
  bool get hasMultipleKey => keys.length > 1;
  String? keyInNetwork;
  final StreamPageProgressController progressKey =
      StreamPageProgressController(initialStatus: StreamWidgetStatus.progress);
  ICardanoAddress? adaLegacyAddress;
  late WalletNetwork network;

  Future<void> initPubKey() async {
    adaLegacyAddress = isAdaLegacy();
    final wallet = context.wallet.wallet;
    network =
        wallet.getChains().firstWhere((e) => e.network == widget.account.network).network;
    final result = await wallet.doAction(WalletActionAccountPublicKeys(account: account));
    if (result.isOk) {
      accoutInfo = result.unwrap();
      switch (result.unwrap()) {
        case ReadAccountPublicKeysResponseDefault keys:
          final List<CryptoPublicKeyDataWithInfo> cKeys = keys.keys.map((e) {
            final viewKey = e.viewKey;
            return e.copyWith(viewKey: viewKey.withNetworkKeyStyle(network.type));
          }).toList();
          if (account.multiSigAccount) {
            this
                .keys
                .add(_ViweAccountKey(key: _ViewAccountKeyInfo(key: cKeys), name: ''));
          } else {
            this.keys.addAll(cKeys.map((e) =>
                _ViweAccountKey(key: _ViewAccountKeyInfo(key: [e]), name: e.index.name)));
          }

          break;
        case ReadAccountPublicKeysResponseZcash keys:
          for (final i in keys.keys) {
            this.keys.add(_ViweAccountKey(
                  key: _ViewAccountKeyInfo(
                      key: i.keys, change: i.change?.name, index: i.index?.toString()),
                  name: switch (i.type) {
                    ZcashAccountInfoType.orchard => "orchard".tr,
                    ZcashAccountInfoType.sapling => "sapling".tr,
                    _ => () {
                        final receiver = account
                            .cast<IZcashAddress>()
                            .account
                            .receivers
                            .firstWhere((e) => e.type == i.type)
                            .cast<ZcashAccountInfoTransparent>()
                            .transparentType
                            .name;
                        return "transparent_type_n".tr.replaceOne(receiver);
                      }()
                  },
                ));
          }
          break;
      }

      progressKey.success();
      selectedKey = keys.first;
    } else {
      if (widget.account.multiSigAccount) {
        progressKey.errorText("unavailable_multi_sig_public_key".tr, backToIdle: false);
      } else {
        progressKey.errorText(result.unwrapErr().localizationError, backToIdle: false);
      }
    }
  }

  ICardanoAddress? isAdaLegacy() {
    if (widget.account is ICardanoAddress) {
      final account = widget.account.cast<ICardanoAddress>();
      if (account.addressInfo.isLegacy) {
        return account;
      }
    }
    return null;
  }

  void onChangeKey(_ViweAccountKey? changeKey) {
    if (selectedKey == changeKey || changeKey == null) return;
    selectedKey = changeKey;
    updateState();
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    initPubKey();
  }

  @override
  void safeDispose() {
    super.safeDispose();
    progressKey.dispose();
    keys = [];
  }

  @override
  Widget build(BuildContext context) {
    return StreamPageProgress(
      controller: progressKey,
      initialWidget: ProgressWithTextView(text: "retrieve_account_informations".tr),
      builder: (c) => CustomScrollView(
        shrinkWrap: true,
        slivers: [
          WidgetConstant.sliverPaddingVertial20,
          SliverToBoxAdapter(
            child: ConstraintsBoxView(
              padding: WidgetConstant.paddingHorizontal20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WidgetConstant.height20,
                  _AddressInfo(widget.account),
                  switch (accoutInfo) {
                    ReadAccountPublicKeysResponseZcash zcash when zcash.ufvk != null =>
                      _ZcashAccountInfo(zcash.ufvk!),
                    _ when adaLegacyAddress != null => _HDPathDetails(adaLegacyAddress!),
                    _ => WidgetConstant.sizedBox,
                  },
                  if (hasMultipleKey) ...[
                    Text("keys".tr, style: context.textTheme.titleMedium),
                    Text("switch_between_keys".tr),
                    WidgetConstant.height8,
                    AppDropDownBottom(
                        onChanged: onChangeKey,
                        items: {for (final i in keys) i: Text(i.name.tr)},
                        hint: "key_name".tr,
                        value: selectedKey),
                    WidgetConstant.height20
                  ],
                  AnimatedSwitcher(
                    duration: APPConst.animationDuraion,
                    child: switch (selectedKey.key.key.length) {
                      1 => _ViweAccountKeyView(
                          key: ValueKey(selectedKey),
                          publicKey: selectedKey.key.key[0],
                          keyInfo: selectedKey.key,
                          networkType: network.type,
                        ),
                      _ => _MultisigKeysView(
                          key: ValueKey(selectedKey),
                          keys: selectedKey.key,
                          networkType: network.type,
                        )
                    },
                  ),
                ],
              ),
            ),
          ),
          WidgetConstant.sliverPaddingVertial40,
        ],
      ),
    );
  }
}

class _HDPathDetails extends StatelessWidget {
  const _HDPathDetails(this.byronLegacy);
  final ICardanoAddress byronLegacy;

  @override
  Widget build(BuildContext context) {
    final addressInfo = byronLegacy.addressInfo as CardanoAddrDetails?;
    if (addressInfo == null) return WidgetConstant.sizedBox;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WidgetConstant.height20,
        Text("hd_path_key".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
          onRemove: () {},
          onRemoveIcon:
              CopyTextIcon(isSensitive: false, dataToCopy: addressInfo.hdPathKeyHex!),
          child: Text(
            addressInfo.hdPathKeyHex!,
            style: context.onPrimaryTextTheme.bodyMedium,
          ),
        ),
        WidgetConstant.height20
      ],
    );
  }
}

class PublicKeysDataView extends StatelessWidget {
  final CryptoPublicKeyDataWithInfo publicKey;
  final Color? color;
  final Color? reverse;

  const PublicKeysDataView(
      {super.key, required this.publicKey, this.color, this.reverse});
  PublicKeysView get viewKey => publicKey.viewKey;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("derivation_path".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ConditionalWidget(
            enable: publicKey.walletName != null,
            onActive: (context) => Text(publicKey.walletName!),
          ),
          AddressDrivationInfo(publicKey.index,
              color: context.onPrimaryContainer,
              style: context.onPrimaryTextTheme.bodySmall)
        ])),
        WidgetConstant.height20,
        ConditionalWidgetWithValue(
          value: viewKey.extendKey,
          onValue: (context, value) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("extended_public_key".tr, style: context.textTheme.titleMedium),
              WidgetConstant.height8,
              SecureContentView(content: value, isSensitive: false),
              WidgetConstant.height20,
            ],
          ),
        ),
        Text("comperessed_public_key".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        SecureContentView(
          content: viewKey.comprossed,
          isSensitive: false,
        ),
        ConditionalWidgetWithValue(
          value: viewKey.uncomprossed,
          onValue: (context, value) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WidgetConstant.height20,
              Text("uncomperessed_public_key".tr, style: context.textTheme.titleMedium),
              WidgetConstant.height8,
              SecureContentView(content: value, isSensitive: false),
            ],
          ),
        ),
        ConditionalWidget(
            onActive: (context) => _MoneroKeysView(pubKey: viewKey.cast()),
            enable: viewKey.keyType == CryptoPublicKeyDataType.monero)
      ],
    );
  }
}

class _MoneroKeysView extends StatelessWidget {
  final MoneroPublicKeysView pubKey;
  const _MoneroKeysView({required this.pubKey});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WidgetConstant.height20,
        Text("spend_public_key".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        SecureContentView(
          content: pubKey.spendPublicKey,
          isSensitive: false,
        ),
        WidgetConstant.height20,
        Text("view_public_key".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        SecureContentView(
          content: pubKey.viewPublicKey,
          isSensitive: false,
        ),
      ],
    );
  }
}

class _AddressInfo extends StatelessWidget {
  final ChainAccount account;
  const _AddressInfo(this.account);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("address_details".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
          child: CopyableTextWidget(
              text: account.address,
              widget: AddressDetailsView(
                  address: account, color: context.onPrimaryContainer)),
        ),
        switch (account.runtimeType) {
          const (IMoneroAddress) => _MoneroAccountInfo(account.cast()),
          const (IXRPAddress) => _XRPAddressInfo(account.cast()),
          const (IStellarAddress) => _StellarAddressInfo(account.cast()),
          const (ITonAddress) => _TonAddressInfo(account.cast()),
          _ => WidgetConstant.sizedBox,
        },
        WidgetConstant.height20,
      ],
    );
  }
}

class _MoneroAccountInfo extends StatelessWidget {
  final IMoneroAddress address;
  const _MoneroAccountInfo(this.address);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("account_index".tr, style: context.textTheme.titleMedium),
      WidgetConstant.height8,
      ContainerWithBorder(
          child: Text(address.index.index.major.toString(),
              style: context.onPrimaryTextTheme.bodyMedium)),
      WidgetConstant.height20,
      Text("address_index".tr, style: context.textTheme.titleMedium),
      WidgetConstant.height8,
      ContainerWithBorder(
          child: Text(address.index.index.minor.toString(),
              style: context.onPrimaryTextTheme.bodyMedium))
    ]);
  }
}

class _XRPAddressInfo extends StatelessWidget {
  final IXRPAddress address;
  const _XRPAddressInfo(this.address);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ConditionalWidget(
          onActive: (context) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WidgetConstant.height20,
                Text("base_address".tr, style: context.textTheme.titleMedium),
                WidgetConstant.height8,
                ContainerWithBorder(
                    child: CopyableTextWidget(
                        text: address.networkAddress.classicAddress,
                        color: context.onPrimaryContainer,
                        maxLines: 2)),
                WidgetConstant.height20,
                Text("tag".tr, style: context.textTheme.titleMedium),
                WidgetConstant.height8,
                ContainerWithBorder(
                    child: Text(address.tag?.toString() ?? "",
                        style: context.onPrimaryTextTheme.bodyMedium)),
              ],
            );
          },
          onDeactive: (context) => WidgetConstant.sizedBox,
          enable: address.tag != null)
    ]);
  }
}

class _StellarAddressInfo extends StatelessWidget {
  final IStellarAddress address;
  const _StellarAddressInfo(this.address);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ConditionalWidget(
          onActive: (context) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WidgetConstant.height20,
                Text("base_address".tr, style: context.textTheme.titleMedium),
                WidgetConstant.height8,
                ContainerWithBorder(
                    child: CopyableTextWidget(
                        text: address.networkAddress.baseAddress,
                        color: context.onPrimaryContainer,
                        maxLines: 2)),
                WidgetConstant.height20,
                Text("muxed_id".tr, style: context.textTheme.titleMedium),
                WidgetConstant.height8,
                ContainerWithBorder(
                    child: Text(address.id?.toString() ?? "",
                        style: context.onPrimaryTextTheme.bodyMedium)),
              ],
            );
          },
          onDeactive: (context) => WidgetConstant.sizedBox,
          enable: address.id != null)
    ]);
  }
}

class _TonAddressInfo extends StatelessWidget {
  final ITonAddress address;
  const _TonAddressInfo(this.address);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      WidgetConstant.height20,
      Text("wallet_version".tr, style: context.textTheme.titleMedium),
      WidgetConstant.height8,
      ContainerWithBorder(
          child: Text(address.context.version.name,
              style: context.onPrimaryTextTheme.bodyMedium)),
      WidgetConstant.height20,
      Text("workchain".tr, style: context.textTheme.titleMedium),
      WidgetConstant.height8,
      ContainerWithBorder(
          child: Text(address.context.workchain.name(),
              style: context.onPrimaryTextTheme.bodyMedium)),
      WidgetConstant.height20,
      Text("type".tr, style: context.textTheme.titleMedium),
      WidgetConstant.height8,
      ContainerWithBorder(
          child: ConditionalWidget(
              onDeactive: (context) {
                return Text("non_bouncable".tr,
                    style: context.onPrimaryTextTheme.bodyMedium);
              },
              onActive: (context) {
                return Text("bouncable".tr, style: context.onPrimaryTextTheme.bodyMedium);
              },
              enable: address.context.bouncable)),
      ConditionalWidget(
          onActive: (context) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WidgetConstant.height20,
                Text("sub_or_wallet_id".tr, style: context.textTheme.titleMedium),
                WidgetConstant.height8,
                ContainerWithBorder(
                  child: Text(address.context.subOrWalletId?.toString() ?? ''),
                ),
              ],
            );
          },
          onDeactive: (context) => WidgetConstant.sizedBox,
          enable: address.context.subOrWalletId != null)
    ]);
  }
}

class _ViewAccountKeyInfo {
  final List<CryptoPublicKeyDataWithInfo> key;
  final String? index;
  final String? change;
  const _ViewAccountKeyInfo({required this.key, this.index, this.change});
}

class _ViweAccountKey {
  final _ViewAccountKeyInfo key;
  final String name;
  const _ViweAccountKey({
    required this.key,
    required this.name,
  });
}

class _ViweAccountKeyView extends StatelessWidget {
  final CryptoPublicKeyDataWithInfo publicKey;
  final _ViewAccountKeyInfo keyInfo;
  final NetworkType networkType;
  const _ViweAccountKeyView(
      {super.key,
      required this.publicKey,
      required this.keyInfo,
      required this.networkType});
  PublicKeysView get viewKey => publicKey.viewKey;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("derivation_path".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ConditionalWidget(
            enable: publicKey.walletName != null,
            onActive: (context) => Text(publicKey.walletName ?? ''),
          ),
          AddressDrivationInfo(publicKey.index,
              color: context.onPrimaryContainer,
              style: context.onPrimaryTextTheme.bodySmall)
        ])),
        WidgetConstant.height20,
        switch (publicKey.key) {
          Zip32PublicKeyData key => _ZipPublicKeyView(
              viewKey: viewKey,
              protocol: key.protocol,
              change: keyInfo.change,
              index: keyInfo.index,
            ),
          _ => _BipPublicKeyView(
              viewKey: viewKey,
              networkType: networkType,
            )
        },
      ],
    );
  }
}

class _BipPublicKeyView extends StatelessWidget {
  final PublicKeysView viewKey;
  final NetworkType networkType;
  const _BipPublicKeyView({required this.viewKey, required this.networkType});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConditionalWidgetWithValue(
          value: viewKey.extendKey,
          onValue: (context, value) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("extended_public_key".tr, style: context.textTheme.titleMedium),
              WidgetConstant.height8,
              SecureContentView(content: value, isSensitive: false),
              WidgetConstant.height20,
            ],
          ),
        ),
        Text("comperessed_public_key".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        SecureContentView(
          content: viewKey.comprossed,
          isSensitive: false,
        ),
        ConditionalWidgetWithValue(
          value: viewKey.uncomprossed,
          onValue: (context, value) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WidgetConstant.height20,
              Text("uncomperessed_public_key".tr, style: context.textTheme.titleMedium),
              WidgetConstant.height8,
              SecureContentView(content: value, isSensitive: false),
            ],
          ),
        ),
        ConditionalWidgetWithValue(
          value: viewKey.inNetworkStyle,
          onValue: (context, value) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WidgetConstant.height20,
              Text("n_style".tr.replaceOne(networkType.name),
                  style: context.textTheme.titleMedium),
              WidgetConstant.height8,
              SecureContentView(content: value, isSensitive: false),
            ],
          ),
        ),
        ConditionalWidget(
            onActive: (context) => _MoneroKeysView(pubKey: viewKey.cast()),
            enable: viewKey.keyType == CryptoPublicKeyDataType.monero)
      ],
    );
  }
}

class _ZipPublicKeyView extends StatelessWidget {
  final PublicKeysView viewKey;
  final Zip32Porotcol protocol;
  final String? index;
  final String? change;
  const _ZipPublicKeyView({
    required this.viewKey,
    required this.protocol,
    this.index,
    this.change,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (viewKey.extendKey != null) ...[
          Text("extended_full_view_key".tr, style: context.textTheme.titleMedium),
          WidgetConstant.height8,
          SecureContentView(
            content: viewKey.extendKey!,
            isSensitive: false,
          ),
          WidgetConstant.height20,
        ],
        switch (protocol) {
          Zip32Porotcol.zcashOrchard =>
            Text("full_viewing_key".tr, style: context.textTheme.titleMedium),
          Zip32Porotcol.zcashSapling => Text("diversifiable_full_viewing_key".tr,
              style: context.textTheme.titleMedium),
        },
        WidgetConstant.height8,
        SecureContentView(
          content: viewKey.comprossed,
          isSensitive: false,
        ),
        ConditionalWidget(
            enable: index != null,
            onActive: (context) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WidgetConstant.height20,
                    Text("diversifier_index".tr, style: context.textTheme.titleMedium),
                    WidgetConstant.height8,
                    ContainerWithBorder(
                      child: Text(
                        index ?? '',
                        style: context.onPrimaryTextTheme.bodyMedium,
                      ),
                    ),
                  ],
                )),
        ConditionalWidget(
            enable: change != null,
            onActive: (context) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WidgetConstant.height20,
                    Text("scope".tr, style: context.textTheme.titleMedium),
                    WidgetConstant.height8,
                    ContainerWithBorder(
                      child: Text(
                        change ?? '',
                        style: context.onPrimaryTextTheme.bodyMedium,
                      ),
                    ),
                  ],
                )),
      ],
    );
  }
}

class _MultisigKeysView extends StatelessWidget {
  final _ViewAccountKeyInfo keys;
  final NetworkType networkType;
  const _MultisigKeysView({super.key, required this.keys, required this.networkType});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "multisig_keys_view".tr,
          style: context.textTheme.titleMedium,
        ),
        WidgetConstant.height8,
        ListView.separated(
          physics: WidgetConstant.noScrollPhysics,
          itemBuilder: (context, index) => APPExpansionListTile(
              title: AddressDrivationInfo(keys.key[index].index,
                  color: context.onPrimaryContainer,
                  style: context.onPrimaryTextTheme.titleMedium),
              children: [
                Container(
                  color: context.colors.surface,
                  margin: WidgetConstant.padding10,
                  padding: WidgetConstant.padding10,
                  child: _ViweAccountKeyView(
                    publicKey: keys.key[index],
                    keyInfo: keys,
                    networkType: networkType,
                  ),
                )
              ]),
          separatorBuilder: (context, index) => const Divider(),
          itemCount: keys.key.length,
          shrinkWrap: true,
        ),
      ],
    );
  }
}

class _ZcashAccountInfo extends StatelessWidget {
  final ReadAccountPublicKeysResponseZcashFvk ufvk;
  const _ZcashAccountInfo(this.ufvk);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      WidgetConstant.height20,
      Text("unified_full_viewing_key".tr, style: context.textTheme.titleMedium),
      WidgetConstant.height8,
      SecureContentView(content: ufvk.ufvk, isSensitive: false),
      WidgetConstant.height20,
      Text("unified_incoming_viewing_key".tr, style: context.textTheme.titleMedium),
      WidgetConstant.height8,
      SecureContentView(content: ufvk.uivk, isSensitive: false),
      WidgetConstant.height20,
    ]);
  }
}
