import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/read_account_private_key.dart';
import 'package:on_chain_wallet/future/tools/secure_state/secure_state.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/address_details.dart';
import 'package:on_chain_wallet/future/wallet/security/pages/accsess_wallet.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/models/account/account.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/crypto/wallet/keys.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

class AccountPrivteKeyView extends StatelessWidget {
  const AccountPrivteKeyView({super.key});

  @override
  Widget build(BuildContext context) {
    final wallet = context.wallet;
    ChainAccount? account;
    ViewImportedSecretKey? customKey;
    final args = context.getDynamicArgs();
    if (args is ChainAccount) {
      account = args;
    } else {
      args as ViewImportedSecretKey;
      customKey = args;
    }

    return AccessWalletView<WalletCredentialResponse,
            WalletCredential<WalletCredentialResponse>>(
        request: customKey == null
            ? WalletCredentialAccountKey(account: account!)
            : WalletCredentialImportedKey(key: customKey),
        onAccsess: (credential) {
          return _AccountPrivateKeyView(
              keys: credential,
              account: account,
              network: wallet.wallet.network,
              customKey: customKey);
        },
        title: "export_private_key".tr,
        subtitle: PageTitleSubtitle(
            title: "private_key".tr,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("export_private_key_desc".tr),
                WidgetConstant.height8,
                Text("enter_wallet_password_to_continue".tr),
              ],
            )));
  }
}

class _AccountPrivateKeyView extends StatefulWidget {
  const _AccountPrivateKeyView({
    required this.keys,
    required this.account,
    required this.network,
    required this.customKey,
  });
  final WalletCredentialResponse keys;
  // final WalletCredentialResponseVerify credential;
  final ChainAccount? account;
  final ViewImportedSecretKey? customKey;
  final WalletNetwork network;
  @override
  State<_AccountPrivateKeyView> createState() => _AccountPrivateKeyViewState();
}

class _AccountPrivateKeyViewState extends State<_AccountPrivateKeyView>
    with SafeState<_AccountPrivateKeyView>, AndroidSecureState<_AccountPrivateKeyView> {
  final StreamPageProgressController progressKey =
      StreamPageProgressController(initialStatus: StreamWidgetStatus.progress);
  WalletNetwork get network => widget.network;
  bool hasMultipleKey = false;
  WalletCredentialResponseVerify? get credential => widget.keys.verificationId;
  ReadAccountPrivateKeysResponse? response;

  List<_ViweAccountKey> keys = [];
  late _ViweAccountKey selectedKey;
  void onChangeKey(_ViweAccountKey? changeKey) {
    if (selectedKey == changeKey || changeKey == null) return;
    selectedKey = changeKey;
    updateState();
  }

  // PrivateKeysView toNetworkKeyFormat(PrivateKeysView key) {
  //   switch (network.type) {
  //     case NetworkType.xrpl:
  //       return key.copyWith(
  //           inNetworkStyle: MethodUtils.fallbackOnException(
  //               () => RippleUtils.toRipplePrivateKey(key.privateKey, key.curve),
  //               logOnDebug: false));
  //     case NetworkType.sui:
  //       return key.copyWith(
  //           inNetworkStyle: MethodUtils.fallbackOnException(
  //               () => SuiCryptoUtils.encodeSuiSecretKey(key.privateKeyBytes(),
  //                   type: key.curve),
  //               logOnDebug: false));
  //     case NetworkType.aptos:
  //       return key.copyWith(
  //           inNetworkStyle: MethodUtils.fallbackOnException(
  //               () => AptosCryptoUtils.encodeAptosPrivateKey(key.privateKeyBytes(),
  //                   type: key.curve),
  //               logOnDebug: false));
  //     default:
  //       return key;
  //   }
  // }

  List<_ViweAccountKey> initKeys() {
    List<_ViweAccountKey> viweKeys = [];
    switch (widget.keys) {
      case WalletCredentialResponseAccountKey acc:
        final account = widget.account;
        if (account == null) {
          throw AppInternalError.internalError("Account should not be null");
        }
        response = acc.credentials;

        switch (acc.credentials) {
          case ReadAccountPrivateKeysResponseDefault keys:
            final List<CryptoPrivateKeyDataWithInfo> cKeys = keys.keys.map((e) {
              final viewKey = e.viewKey;
              return e.copyWith(viewKey: viewKey.withNetworkKeyStyle(network.type));
            }).toList();
            if (account.multiSigAccount) {
              viweKeys
                  .add(_ViweAccountKey(key: _ViewAccountKeyInfo(key: cKeys), name: ''));
            } else {
              viweKeys.addAll(cKeys.map((e) => _ViweAccountKey(
                  key: _ViewAccountKeyInfo(key: [e]), name: e.index?.name ?? '')));
            }

            break;
          case ReadAccountPrivateKeysResponseZcash keys:
            for (final i in keys.keys) {
              viweKeys.add(_ViweAccountKey(
                key: _ViewAccountKeyInfo(key: i.keys),
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

      case WalletCredentialResponseImportedKey key:
        viweKeys.add(_ViweAccountKey(
            key: _ViewAccountKeyInfo(key: [key.credential]), name: key.keyName ?? ""));
        break;
      default:
        throw AppInternalError.internalError("Unexpected response.");
    }
    if (viweKeys.isEmpty) {
      throw AppInternalError.internalError("No key to view.");
    }
    return viweKeys;
  }

  Future<void> init() async {
    final init = await IResult.call(() async => initKeys());
    if (init.isErr) {
      progressKey.errorText(init.unwrapErr().localizationError, backToIdle: false);
      return;
    }
    keys = init.unwrap();
    selectedKey = keys.first;
    hasMultipleKey = keys.length > 1;

    progressKey.backToIdle();
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    init();
  }

  @override
  Widget build(BuildContext context) {
    return StreamPageProgress(
      controller: progressKey,
      initialWidget: ProgressWithTextView(text: "retrieve_account_informations".tr),
      builder: (context) => SensitiveContent(
        sensitivity: ContentSensitivity.sensitive,
        child: CustomScrollView(
          slivers: [
            SliverConstraintsBoxView(
              padding: WidgetConstant.padding20,
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AlertTextContainer(message: "export_private_key_desc".tr),
                    WidgetConstant.height20,
                    if (widget.account != null) ...[
                      Text("address_details".tr, style: context.textTheme.titleMedium),
                      WidgetConstant.height8,
                      ContainerWithBorder(
                        child: CopyableTextWidget(
                          text: widget.account!.address,
                          widget: AddressDetailsView(
                              address: widget.account!,
                              color: context.onPrimaryContainer),
                        ),
                      ),
                      WidgetConstant.height20,
                    ],
                    ConditionalWidgetWithValue<String>(
                      value: switch (response) {
                        ReadAccountPrivateKeysResponseZcash key => key.ufsk,
                        _ => null,
                      },
                      onValue: (context, value) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _HiddenKeyView(
                                title: "unified_full_spend_key".tr,
                                keyData: value,
                                credential: credential),
                            WidgetConstant.height20,
                          ],
                        );
                      },
                    ),
                    if (hasMultipleKey) ...[
                      Text("keys".tr, style: context.textTheme.titleMedium),
                      Text("switch_between_keys".tr),
                      WidgetConstant.height8,
                      AppDropDownBottom(
                          onChanged: onChangeKey,
                          items: {for (final i in keys) i: Text(i.name.tr)},
                          hint: "key_name".tr,
                          value: selectedKey),
                      WidgetConstant.height20,
                    ],
                    AnimatedSwitcher(
                      duration: APPConst.animationDuraion,
                      child: switch (selectedKey.key.key.length) {
                        1 => _KeysView(
                            key: ValueKey(selectedKey),
                            privateKey: selectedKey.key.key[0],
                            keyInfo: selectedKey.key,
                            state: this,
                          ),
                        _ => _MultisigKeysView(
                            key: ValueKey(selectedKey),
                            keys: selectedKey.key,
                            state: this,
                          )
                      },
                    ),
                    WidgetConstant.height20
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeysView extends StatelessWidget {
  final CryptoPrivateKeyDataWithInfo privateKey;
  final _ViewAccountKeyInfo keyInfo;
  const _KeysView(
      {required this.privateKey, required this.keyInfo, required this.state, super.key});
  final _AccountPrivateKeyViewState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConditionalWidgetWithValue(
          value: privateKey.index,
          onValue: (context, index) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("derivation_path".tr, style: context.textTheme.titleMedium),
                WidgetConstant.height8,
                ContainerWithBorder(
                    child:
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ConditionalWidget(
                    enable: privateKey.walletName != null,
                    onActive: (context) => Text(privateKey.walletName ?? ''),
                  ),
                  AddressDrivationInfo(index,
                      color: context.onPrimaryContainer,
                      style: context.onPrimaryTextTheme.bodySmall)
                ])),
                WidgetConstant.height20,
                ConditionalWidgetWithValue(
                  value: privateKey.importedKeyName,
                  onValue: (context, value) {
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "imported_key".tr,
                            style: context.textTheme.titleMedium,
                          ),
                          WidgetConstant.height8,
                          ContainerWithBorder(
                            child: Text(
                              value,
                              style: context.onPrimaryTextTheme.bodyMedium,
                            ),
                          ),
                          WidgetConstant.height20,
                        ]);
                  },
                )
              ],
            );
          },
        ),
        switch (privateKey.key) {
          Zip32PrivateKeyData key => _ZipPublicKeyView(
              viewKey: privateKey.viewKey,
              protocol: key.protocol,
              state: state,
            ),
          _ => _BipPublicKeyView(
              viewKey: privateKey.viewKey,
              state: state,
            )
        },
        ConditionalWidget(
            onActive: (context) =>
                _MoneroKeysView(privateKey: privateKey.viewKey.cast(), state: state),
            enable: privateKey.viewKey.keyType == CryptoPrivateKeyDataType.monero)
      ],
    );
  }
}

class _BipPublicKeyView extends StatelessWidget {
  final PrivateKeysView viewKey;
  final _AccountPrivateKeyViewState state;
  const _BipPublicKeyView({required this.viewKey, required this.state});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HiddenKeyView(
            title: "private_key".tr,
            subtitle: viewKey.curve.name.camelCase,
            keyData: viewKey.privateKey,
            credential: state.credential,
            type: WalletBackupTypes.privatekey),
        if (viewKey.extendKey != null) ...[
          WidgetConstant.height20,
          _HiddenKeyView(
              title: "extended_private_key".tr,
              keyData: viewKey.extendKey!,
              credential: state.credential,
              type: WalletBackupTypes.extendedKey),
        ],
        if (viewKey.wif != null) ...[
          WidgetConstant.height20,
          _HiddenKeyView(
              title: "wif".tr,
              keyData: viewKey.wif!,
              credential: state.credential,
              type: WalletBackupTypes.wif),
        ],
        if (viewKey.inNetworkStyle != null) ...[
          WidgetConstant.height20,
          _HiddenKeyView(
            title: "n_style".tr.replaceOne(state.network.type.name),
            keyData: viewKey.inNetworkStyle!,
          ),
        ],
      ],
    );
  }
}

class _ZipPublicKeyView extends StatelessWidget {
  final PrivateKeysView viewKey;
  final Zip32Porotcol protocol;
  final _AccountPrivateKeyViewState state;
  const _ZipPublicKeyView({
    required this.viewKey,
    required this.protocol,
    required this.state,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HiddenKeyView(
            title: switch (protocol) {
              Zip32Porotcol.zcashOrchard => "orchard_spend_key".tr,
              Zip32Porotcol.zcashSapling => "sapling_extended_spend_key".tr,
            },
            subtitle: viewKey.curve.name.camelCase,
            keyData: switch (protocol) {
              Zip32Porotcol.zcashOrchard => viewKey.privateKey,
              Zip32Porotcol.zcashSapling => viewKey.extendKey ?? viewKey.privateKey,
            },
            credential: state.credential,
            type: switch (protocol) {
              Zip32Porotcol.zcashOrchard => WalletBackupTypes.orchardSpendKey,
              Zip32Porotcol.zcashSapling => WalletBackupTypes.saplingExtendedSpandingKey,
            }),
        if (viewKey.inNetworkStyle != null) ...[
          WidgetConstant.height20,
          _HiddenKeyView(
            title: "n_style".tr.replaceOne(state.network.type.name),
            keyData: viewKey.inNetworkStyle!,
          ),
        ],
      ],
    );
  }
}

class _MoneroKeysView extends StatelessWidget {
  final MoneroPrivateKeysView privateKey;
  const _MoneroKeysView({required this.privateKey, required this.state});
  final _AccountPrivateKeyViewState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WidgetConstant.height20,
        _HiddenKeyView(
            title: "spend_private_key".tr,
            keyData: privateKey.spendPrivateKey,
            credential: state.credential,
            type: WalletBackupTypes.privatekey),
        WidgetConstant.height20,
        _HiddenKeyView(
            title: "view_private_key".tr,
            keyData: privateKey.viewPrivateKey,
            credential: state.credential,
            type: WalletBackupTypes.privatekey),
      ],
    );
  }
}

class _HiddenKeyView extends StatelessWidget {
  final String title;
  final String keyData;
  final String? subtitle;
  final WalletBackupTypes? type;
  final WalletCredentialResponseVerify? credential;
  const _HiddenKeyView(
      {required this.title,
      required this.keyData,
      this.subtitle,
      this.type,
      this.credential});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.textTheme.titleMedium),
        if (subtitle != null) Text(subtitle!),
        WidgetConstant.height8,
        SecureContentView(content: keyData, backupType: type, credential: credential),
      ],
    );
  }
}

class _ViewAccountKeyInfo {
  final List<CryptoPrivateKeyDataWithInfo> key;
  const _ViewAccountKeyInfo({required this.key});
}

class _ViweAccountKey {
  final _ViewAccountKeyInfo key;
  final String name;
  const _ViweAccountKey({
    required this.key,
    required this.name,
  });
}

class _MultisigKeysView extends StatelessWidget {
  final _ViewAccountKeyInfo keys;
  final _AccountPrivateKeyViewState state;
  const _MultisigKeysView({required this.keys, required this.state, super.key});
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
              title: ConditionalWidget(
                  enable: keys.key[index].index != null,
                  onActive: (context) => AddressDrivationInfo(keys.key[index].index!,
                      color: context.onPrimaryContainer,
                      style: context.onPrimaryTextTheme.titleMedium)),
              children: [
                Container(
                  color: context.colors.surface,
                  margin: WidgetConstant.padding10,
                  padding: WidgetConstant.padding10,
                  child: _KeysView(
                    privateKey: keys.key[index],
                    keyInfo: keys,
                    state: state,
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
