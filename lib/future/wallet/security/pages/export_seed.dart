import 'package:blockchain_utils/bip/mnemonic/mnemonic.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/tools/secure_state/secure_state.dart';
import 'package:on_chain_wallet/future/wallet/security/pages/accsess_wallet.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/crypto/wallet/keys.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class ExportSeedView extends StatelessWidget {
  const ExportSeedView({super.key});
  @override
  Widget build(BuildContext context) {
    return AccessWalletView<WalletCredentialResponseMnemonic, WalletCredentialMnemonic>(
        request: WalletCredentialMnemonic(),
        onAccsess: (credential) {
          return _ExportSeedView(
              mnemonic: credential.credential, credential: credential.id);
        },
        title: "export_mnemonic".tr,
        subtitle: PageTitleSubtitle(
            title: "export_mnemonic".tr, body: Text("export_mnemonic_desc2".tr)));
  }
}

class _ExportSeedView extends StatefulWidget {
  const _ExportSeedView({required this.mnemonic, required this.credential});
  final AccessMnemonicResponse mnemonic;
  final WalletCredentialResponseVerify credential;

  @override
  State<_ExportSeedView> createState() => _ExportSeedViewState();
}

class _ExportSeedViewState extends State<_ExportSeedView>
    with SafeState<_ExportSeedView>, AndroidSecureState<_ExportSeedView> {
  List<_ViewMnemonicData> mnemonics = [];

  List<_ViewMnemonicData> _buildMnemonics() {
    List<_ViewMnemonicData> mnemonics = [];
    final wallet = context.wallet.wallet.wallet;
    mnemonics.add(_ViewMnemonicData(
        name: wallet.name,
        subwalletId: null,
        mnemonic: widget.mnemonic.mnemonic,
        createdAt: wallet.created.toOnlyDateStr()));
    for (final i in widget.mnemonic.subWallets) {
      final sWallet = wallet.subWallets.firstWhereOrNull((e) => e.id == i.subWalletId);
      // assert(sWallet != null, "wallet not found ${i.subWalletId}");
      if (sWallet == null) continue;
      mnemonics.add(_ViewMnemonicData(
          name: sWallet.name,
          subwalletId: sWallet.id,
          mnemonic: i.mnemonic,
          createdAt: sWallet.created.toOnlyDateStr()));
    }
    return mnemonics;
  }

  late _ViewMnemonicData mnemonic;

  Map<_ViewMnemonicData, Widget> _buildItems() {
    return {
      for (final i in mnemonics)
        i: Row(
          children: [
            ConditionalWidget(
              enable: i.subwalletId == null,
              onActive: (context) => Icon(Icons.account_balance_wallet),
              onDeactive: (context) => Icon(Icons.account_balance_wallet_outlined),
            ),
            WidgetConstant.width8,
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(i.name, style: context.textTheme.bodyMedium),
                Text(i.createdAt, style: context.textTheme.bodySmall)
              ]),
            )
          ],
        )
    };
  }

  Map<_ViewMnemonicData, Widget> items = {};
  void onChangeMnemonic(final _ViewMnemonicData? mnemonic) {
    if (mnemonic == null) return;
    this.mnemonic = mnemonic;
    updateState();
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    mnemonics = _buildMnemonics();
    mnemonic = mnemonics.first;
    items = _buildItems();
  }

  @override
  Widget build(BuildContext context) {
    return SensitiveContent(
      sensitivity: ContentSensitivity.sensitive,
      child: CustomScrollView(
        shrinkWrap: true,
        slivers: [
          SliverConstraintsBoxView(
            padding: WidgetConstant.paddingHorizontal20,
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  WidgetConstant.height20,
                  PageTitleSubtitle(
                      title: "export_mnemonic".tr,
                      body: LargeTextView([
                        "export_mnemonic_desc2".tr,
                        "mnemonic_security_des1".tr,
                        "mnemonic_security_des2".tr,
                        "mnemonic_security_des3".tr
                      ])),
                  AppDropDownBottom(
                      items: items,
                      isDense: false,
                      isExpanded: true,
                      value: mnemonic,
                      onChanged: onChangeMnemonic),
                  WidgetConstant.height8,
                  APPAnimated(
                    onActive: (context) => SecureContentView(
                        key: ValueKey(mnemonic),
                        content: mnemonic.mnmonicStr,
                        credential: widget.credential,
                        backupType: WalletBackupTypes.mnemonic),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewMnemonicData {
  final String name;
  final int? subwalletId;
  final Mnemonic mnemonic;
  final String mnmonicStr;
  final String createdAt;
  _ViewMnemonicData(
      {required this.name,
      required this.subwalletId,
      required this.mnemonic,
      required this.createdAt})
      : mnmonicStr = mnemonic.toStr();
}
