import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/security/pages/accsess_wallet.dart';
import 'package:on_chain_wallet/future/widgets/widgets/json/json/widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class CardanoMultisigAccountInfoView extends StatelessWidget {
  const CardanoMultisigAccountInfoView({super.key});

  @override
  Widget build(BuildContext context) {
    return AccessWalletView<WalletCredentialResponseLogin, WalletCredentialLogin>(
      request: WalletCredentialLogin.instance,
      title: "multisig_address_infos".tr,
      onAccsess: (_) {
        return NetworkAccountControllerView<ADANetworkClient?, ICardanoAddress, ADAChain>(
          addressRequired: true,
          clientRequired: false,
          childBulder: (wallet, chain, client, account) {
            return _CardanoMultisigAccountInfoView(chain);
          },
        );
      },
    );
  }
}

class _CardanoMultisigAccountInfoView extends StatefulWidget {
  final ADAChain account;
  const _CardanoMultisigAccountInfoView(this.account);

  @override
  State<_CardanoMultisigAccountInfoView> createState() =>
      __AptosMultisigAccountInfoViewState();
}

class __AptosMultisigAccountInfoViewState extends State<_CardanoMultisigAccountInfoView>
    with SafeState<_CardanoMultisigAccountInfoView> {
  final StreamPageProgressController progressKey =
      StreamPageProgressController(initialStatus: StreamWidgetStatus.progress);
  ADAChain get account => widget.account;
  late final _CardanoCredentialInfo baseKeyInfo;
  late final ICardanoMultiSigAddress address;
  _CardanoCredentialInfo? stakeKeyInfos;

  // late final int threshold;
  _CardanoCredentialInfo extractKeyInfos(BaseCardanoMultiSignatureCredential credential) {
    if (credential.type == CardanoCredentialType.script) {
      final scriptCred = credential.cast<CardanoMultiSignatureScript>();
      final signers = scriptCred.signers
          .map((e) => _CardanoMultisigSignersInfo(
              address: account.addresses.firstWhereOrNull(
                  (i) => !i.multiSigAccount && i.derivationIndex == e.derivationIndex),
              publicKey: BytesUtils.toHexString(e.publicKey, prefix: "0x"),
              keyIndex: e.derivationIndex))
          .toList();
      return _CardanoCredentialInfo(
          signers: signers,
          threshold: scriptCred.threshold,
          type: scriptCred.type,
          scriptContent: scriptCred.script.toJson());
    }
    final pubKey = credential.cast<CardanoMultiSignatureKey>();
    return _CardanoCredentialInfo(signers: [
      _CardanoMultisigSignersInfo(
          address: account.addresses.firstWhereOrNull((i) =>
              !i.multiSigAccount && i.derivationIndex == pubKey.signer.derivationIndex),
          publicKey: BytesUtils.toHexString(pubKey.signer.publicKey, prefix: "0x"),
          keyIndex: pubKey.signer.derivationIndex)
    ], threshold: pubKey.threshold, type: pubKey.type, scriptContent: null);
  }

  Future<void> _init() async {
    if (!account.haveAddress || !account.addressSync.multiSigAccount) {
      progressKey.errorText("invalid_account".tr);
      return;
    }
    address = account.addressSync.cast();
    baseKeyInfo = extractKeyInfos(address.addressInfo.credential);
    if (address.addressInfo.addressType == ADAAddressType.base) {
      stakeKeyInfos = extractKeyInfos(address.addressInfo.stakeCredential!);
    }
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
              padding: WidgetConstant.padding20,
              sliver: SliverToBoxAdapter(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("address".tr, style: context.textTheme.titleMedium),
                  WidgetConstant.height8,
                  ContainerWithBorder(child: AddressDetailsView(address: address)),
                  WidgetConstant.height20,
                  Text("base_credential".tr, style: context.textTheme.titleMedium),
                  WidgetConstant.height8,
                  _CredentialDetailsView(credential: baseKeyInfo),
                  ConditionalWidget(
                      enable: stakeKeyInfos != null,
                      onActive: (context) =>
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            WidgetConstant.height20,
                            Text("stake_credential".tr,
                                style: context.textTheme.titleMedium),
                            WidgetConstant.height8,
                            _CredentialDetailsView(credential: stakeKeyInfos!),
                          ]))
                ],
              )))
        ]);
      },
    );
  }
}

class _CredentialDetailsView extends StatelessWidget {
  final _CardanoCredentialInfo credential;
  const _CredentialDetailsView({required this.credential});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: WidgetConstant.paddingHorizontal10,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("credential_type".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
          child:
              Text(credential.type.name.tr, style: context.onPrimaryTextTheme.bodyMedium),
        ),
        WidgetConstant.height20,
        ConditionalWidget(
            enable: credential.type.isScript,
            onActive: (context) =>
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("threshold".tr, style: context.textTheme.titleMedium),
                  WidgetConstant.height8,
                  ContainerWithBorder(
                    child: Text(credential.threshold.toString(),
                        style: context.onPrimaryTextTheme.bodyMedium),
                  ),
                  WidgetConstant.height20,
                ])),
        Text("public_keys".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        APPExpansionListTile(
          margin: WidgetConstant.padding5,
          title: Text("public_keys".tr, style: context.onPrimaryTextTheme.bodyMedium),
          children: [
            ListView.separated(
                itemCount: credential.signers.length,
                shrinkWrap: true,
                separatorBuilder: (context, index) =>
                    Divider(color: context.onPrimaryContainer),
                physics: WidgetConstant.noScrollPhysics,
                itemBuilder: (context, i) =>
                    _ShowAddressView(account: credential.signers[i])),
          ],
        ),
        ConditionalWidget(
            enable: credential.scriptContent != null,
            onActive: (context) =>
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  WidgetConstant.height20,
                  Text("script".tr, style: context.textTheme.titleMedium),
                  WidgetConstant.height8,
                  ContainerWithBorder(
                      onRemoveIcon:
                          Icon(Icons.open_in_full, color: context.onPrimaryContainer),
                      onRemove: () {
                        context.openDialogPage(
                          '',
                          child: (context) => JsonView(
                              text: credential.scriptContent!, title: 'script'.tr),
                        );
                      },
                      child: Text("content".tr))
                ])),
      ]),
    );
  }
}

class _ShowAddressView extends StatelessWidget {
  final _CardanoMultisigSignersInfo account;
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

class _CardanoMultisigSignersInfo {
  final ICardanoAddress? address;
  final String publicKey;
  final Bip32DerivationIndex keyIndex;
  const _CardanoMultisigSignersInfo(
      {required this.address, required this.publicKey, required this.keyIndex});
}

class _CardanoCredentialInfo {
  final List<_CardanoMultisigSignersInfo> signers;
  final int threshold;
  final CardanoCredentialType type;
  final Map<String, dynamic>? scriptContent;
  const _CardanoCredentialInfo(
      {required this.signers,
      required this.threshold,
      required this.type,
      this.scriptContent});
}
