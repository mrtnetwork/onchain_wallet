import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain/sui/sui.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/account/controller/account_controller.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/wallet/network/sui/account/state.dart';
import 'package:on_chain_wallet/future/wallet/security/pages/accsess_wallet.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

enum _Pages { threshold, pickAddresses, review }

class SetupSuiMultisigAddress extends StatelessWidget {
  const SetupSuiMultisigAddress({super.key});

  @override
  Widget build(BuildContext context) {
    return AccessWalletView<WalletCredentialResponseLogin, WalletCredentialLogin>(
      request: WalletCredentialLogin.instance,
      title: "setup_multisig_address".tr,
      onAccsess: (_) {
        return NetworkAccountControllerView<SuiNetworkClient?, ISuiAddress?, SuiChain>(
          addressRequired: false,
          clientRequired: false,
          childBulder: (wallet, account, client, address) {
            return _SetupSuiMultisigAddress(account: account, wallet: wallet);
          },
        );
      },
    );
  }
}

class _SetupSuiMultisigAddress extends StatefulWidget {
  const _SetupSuiMultisigAddress({required this.account, required this.wallet});
  final SuiChain account;
  final WalletProvider wallet;

  @override
  State<_SetupSuiMultisigAddress> createState() => __SetupSuiMultisigAddressState();
}

class __SetupSuiMultisigAddressState extends SuiAccountState<_SetupSuiMultisigAddress>
    with ProgressMixin {
  @override
  SuiChain get account => widget.account;
  _Pages page = _Pages.threshold;
  final GlobalKey<FormState> formKey =
      GlobalKey(debugLabel: "__SetupSuiMultisigAddressState_formKey");

  int threshold = 2;
  bool allowAddAccount = true;
  String? error;

  bool get isReady => error == null;

  String? onValidateThreshold(String? v) {
    final threshold = IntUtils.tryParse(v);
    if (threshold == null ||
        threshold < SuiAccountConst.multisigAccountMinThreshold ||
        threshold > SuiAccountConst.multisigAccountMaxThreshold) {
      return "threshold_validator"
          .tr
          .replaceOne(SuiAccountConst.multisigAccountMinThreshold.toString())
          .replaceTwo(SuiAccountConst.multisigAccountMaxThreshold.toString());
    }
    return null;
  }

  String? validateMultisig() {
    if (threshold < SuiAccountConst.multisigAccountMinThreshold ||
        threshold > SuiAccountConst.multisigAccountMaxThreshold) {
      return "threshold_validator"
          .tr
          .replaceOne(SuiAccountConst.multisigAccountMinThreshold.toString())
          .replaceTwo(SuiAccountConst.multisigAccountMaxThreshold.toString());
    }
    if (signers.length > SuiAccountConst.multisigAccountMaxPublicKey) {
      return "exceeded_multisig_maximum_publickey".tr;
    }
    if (signers.isEmpty) {
      return "at_least_one_account_required".tr;
    }
    for (final i in signers) {
      if (i.weight < SuiAccountConst.multisigAccountPublicKeyMinWeight ||
          i.weight > SuiAccountConst.multisigAccountPublicKeyMaxWeight) {
        return "address_weight_validator"
            .tr
            .replaceOne(SuiAccountConst.multisigAccountPublicKeyMinWeight.toString())
            .replaceTwo(SuiAccountConst.multisigAccountPublicKeyMaxWeight.toString());
      }
    }
    final totalWeight = signers.fold(0, (p, c) => p + c.weight);
    if (totalWeight < threshold) {
      return "threshhold_desc3".tr;
    }
    return null;
  }

  void checkError() {
    error = validateMultisig();
    allowAddAccount = signers.length < SuiAccountConst.multisigAccountMaxPublicKey;
  }

  void onChangeThreshold(int? threshold) {
    this.threshold = threshold ?? SuiAccountConst.multisigAccountMinThreshold;
    updateState();
  }

  void submitThreshold() {
    if (!formKey.ready()) return;
    page = _Pages.pickAddresses;
    checkError();
    updateState();
  }

  List<_SuiSigner> signers = [];

  String? filterAccount(ISuiAddress address) {
    if (address.multiSigAccount) {
      return "unavailable_multi_sig_public_key".tr;
    }
    if (signers.any((e) =>
        e.keyScheme.curve == address.keyScheme.curve &&
        BytesUtils.bytesEqual(e.publicKey, address.publicKey))) {
      return "public_key_already_exist".tr;
    }
    return null;
  }

  Future<void> addAddress() async {
    final address = await context.selectOrSwitchAccount<ISuiAddress>(
        account: account, showMultiSig: false, filter: filterAccount);
    if (address == null) return;
    final signer = _SuiSigner(
        keyIndex: address.derivationIndex.cast(),
        publicKey: address.publicKey,
        account: address);
    signers.add(signer);
    checkError();
    updateState();
  }

  Future<void> addPublicKey() async {
    final pubKey =
        await context.openMaxExtendSliverBottomSheet<PublicKeyDerivationWithMode>('',
            bodyBuilder: (c) =>
                PublicKeyDerivationView(controller: c, coins: account.network.coins));
    if (pubKey == null) return;
    final error = () {
      if (signers.any((e) => BytesUtils.bytesEqual(
          e.publicKey, pubKey.derivation.key.normalizedComprossedBytes))) {
        return "public_key_already_exist".tr;
      }
      return null;
    }();
    if (error != null) {
      context.showAlert(error.tr);
      return;
    }
    final signer = _SuiSigner(
        keyIndex: pubKey.derivation.index.cast(),
        publicKey: pubKey.derivation.key.normalizedComprossedBytes,
        account: account.addresses.firstWhereOrNull((e) =>
            !e.multiSigAccount &&
            BytesUtils.bytesEqual(
                e.publicKey, pubKey.derivation.key.normalizedComprossedBytes)));
    signers.add(signer);
    checkError();
    updateState();
  }

  void onChangeWeight(_SuiSigner address, int? weight) {
    address.weight = weight ?? SuiAccountConst.multisigAccountPublicKeyMinWeight;
    checkError();
    updateState();
  }

  void updateThreshold() {
    page = _Pages.threshold;
    updateState();
  }

  void removeAddress(_SuiSigner signer) {
    signers.remove(signer);
    checkError();
    updateState();
  }

  void reviewAddress() {
    try {
      checkError();
      if (!isReady) return;
      page = _Pages.review;
    } finally {
      updateState();
    }
  }

  void clearState() {
    threshold = 2;
    signers.clear();
    page = _Pages.threshold;
    updateState();
  }

  void onBackButton(bool _, Object? __) {
    switch (page) {
      case _Pages.review:
        page = _Pages.pickAddresses;
        break;
      case _Pages.pickAddresses:
        page = _Pages.threshold;
        break;
      default:
    }
    updateState();
  }

  bool get canBack {
    return (page == _Pages.review && progressKey.isSuccess) || page == _Pages.threshold;
  }

  Future<void> generateAddress() async {
    progressKey.progressText("setup_address".tr);
    final r = await IResult.call(() async {
      final publicKeys = signers
          .map((e) => SuiMultisigAccountPublicKeyInfo.create(
              derivationIndex: e.keyIndex.cast(),
              keyScheme: e.keyScheme,
              publicKey: e.publicKey,
              wieght: e.weight))
          .toList();
      final multisig =
          SuiMultisigAccountInfo.create(publicKeys: publicKeys, threshold: threshold);

      final address = SuiAddrEncoder().encodeMultisigKey(
          pubKey: publicKeys.map((e) {
            return SuiPublicKeyAndWeight(
                publicKey: IPublicKey.fromBytes(
                    e.publicKey,
                    e.keyScheme.curve == EllipticCurveTypes.nist256p1Hybrid
                        ? EllipticCurveTypes.nist256p1
                        : e.keyScheme.curve),
                weight: e.weight);
          }).toList(),
          threshold: threshold);
      return SuiMultiSigNewAddressParams(
          multiSignatureAddress: multisig,
          coin: account.network.coins.first,
          address: SuiAddress(address));
    }, delay: APPConst.oneSecoundDuration);
    if (r.isErr) {
      progressKey.errorText(r.unwrapErr().localizationError,
          showBackButton: true, backToIdle: false);
      return;
    }
    final import = await widget.wallet.wallet.doAction(
        WalletActionDeriveNewAccount(newAccountParams: r.unwrap(), chain: account));
    if (import.isErr) {
      progressKey.errorText(import.unwrapErr().localizationError,
          showBackButton: true, backToIdle: false);
      return;
    }
    progressKey.success(
        backToIdle: false,
        progressWidget: SuccessWithButtonView(
          buttonWidget: ContainerWithBorder(
              margin: WidgetConstant.paddingVertical8,
              child: AddressDetailsView(address: import.unwrap())),
          buttonText: "generate_new_address".tr,
          onPressed: () {
            clearState();
            progressKey.backToIdle();
          },
        ));
    updateState();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      canPop: canBack,
      onPopInvokedWithResult: onBackButton,
      child: StreamPageProgress(
        controller: progressKey,
        builder: (context) => CustomScrollView(slivers: [
          SliverConstraintsBoxView(
            padding: WidgetConstant.paddingHorizontal20,
            sliver: MultiSliver(children: [
              SliverToBoxAdapter(
                child: PageTitleSubtitle(
                    title: "multisig_address".tr,
                    body: Column(children: [
                      Text("multisig_address_desc".tr),
                      AlertTextContainer(
                          message: "mutlisig_address_alert".tr, enableTap: false)
                    ])),
              ),
              APPSliverAnimatedSwitcher<_Pages>(enable: page, widgets: {
                _Pages.threshold: (context) => _SetupTreshold(this),
                _Pages.pickAddresses: (context) => _PickAddress(this),
                _Pages.review: (context) => _ReviewAddress(this)
              })
            ]),
          ),
        ]),
      ),
    );
  }
}

class _ReviewAddress extends StatelessWidget {
  const _ReviewAddress(this.state);
  final __SetupSuiMultisigAddressState state;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("threshold".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
            onRemove: state.updateThreshold,
            onRemoveIcon: Icon(Icons.edit, color: context.onPrimaryContainer),
            child: Text(state.threshold.toString(),
                style: context.onPrimaryTextTheme.titleMedium)),
        WidgetConstant.height20,
        Text("list_of_public_keys".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        APPAnimatedSize(
            isActive: true,
            onActive: (context) => ListView.separated(
                  physics: WidgetConstant.noScrollPhysics,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final account = state.signers[index];
                    return _ShowAddressView(signer: account, state: state);
                  },
                  itemCount: state.signers.length,
                  separatorBuilder: (context, index) => WidgetConstant.divider,
                ),
            onDeactive: (c) => WidgetConstant.sizedBox),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          FixedElevatedButton(
            padding: WidgetConstant.paddingVertical40,
            onPressed: state.generateAddress,
            activePress: state.isReady,
            child: Text("generate_address".tr),
          )
        ])
      ]),
    );
  }
}

class _PickAddress extends StatelessWidget {
  const _PickAddress(this.state);
  final __SetupSuiMultisigAddressState state;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("threshold".tr, style: context.textTheme.titleMedium),
        Text("threshhold_desc3".tr),
        WidgetConstant.height8,
        ContainerWithBorder(
            onRemove: state.updateThreshold,
            onRemoveIcon: Icon(Icons.edit, color: context.onPrimaryContainer),
            child: Text(state.threshold.toString(),
                style: context.onPrimaryTextTheme.titleMedium)),
        WidgetConstant.height20,
        Text("list_of_public_keys".tr, style: context.textTheme.titleMedium),
        Text("choose_public_key_or_generate_new_on".tr),
        WidgetConstant.height8,
        APPAnimatedSize(
            isActive: true,
            onActive: (context) => ListView.separated(
                  physics: WidgetConstant.noScrollPhysics,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    // final keys = state.selectedAccounts.keys.toList();
                    final account = state.signers[index];
                    return _ShowAddressView(
                        signer: account, state: state, onRemove: state.removeAddress);
                  },
                  itemCount: state.signers.length,
                  separatorBuilder: (context, index) => WidgetConstant.divider,
                ),
            onDeactive: (c) => WidgetConstant.sizedBox),
        APPAnimatedSize(
            isActive: true,
            onActive: (context) => ContainerWithBorder(
                  validate: state.signers.isNotEmpty,
                  onRemove: () {},
                  enableTap: false,
                  onRemoveWidget: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                          tooltip: 'accounts'.tr,
                          onPressed: state.addAddress,
                          icon: Icon(Icons.supervisor_account_rounded)),
                      IconButton(
                          tooltip: 'generate_public_key'.tr,
                          onPressed: state.addPublicKey,
                          icon: Icon(Icons.add_box)),
                    ],
                  ),
                  child: Text("tap_to_chose_or_create_public_key".tr),
                ),
            onDeactive: (context) => WidgetConstant.sizedBox),
        ErrorTextContainer(error: state.error),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          FixedElevatedButton(
            padding: WidgetConstant.paddingVertical40,
            onPressed: state.reviewAddress,
            activePress: state.isReady,
            child: Text("review_address".tr),
          )
        ])
      ]),
    );
  }
}

class _SetupTreshold extends StatelessWidget {
  const _SetupTreshold(this.state);
  final __SetupSuiMultisigAddressState state;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("threshold".tr, style: context.textTheme.titleMedium),
          Text("threshhold_desc3".tr),
          WidgetConstant.height8,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: NumberTextField(
                    label: "threshold".tr,
                    readOnly: false,
                    onChangeValue: state.onChangeThreshold,
                    validator: state.onValidateThreshold,
                    max: SuiAccountConst.multisigAccountMaxThreshold,
                    min: SuiAccountConst.multisigAccountMinThreshold,
                    defaultValue: state.threshold),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FixedElevatedButton(
                  padding: WidgetConstant.paddingVertical40,
                  onPressed: state.submitThreshold,
                  child: Text("continue".tr))
            ],
          )
        ],
      ),
    );
  }
}

typedef _ONSELECTSUISIGNER = void Function(_SuiSigner signer);

class _ShowAddressView extends StatelessWidget {
  final _SuiSigner signer;
  final __SetupSuiMultisigAddressState state;
  final _ONSELECTSUISIGNER? onRemove;
  const _ShowAddressView({required this.signer, required this.state, this.onRemove});
  @override
  Widget build(BuildContext context) {
    return CustomizedContainer(
      onTapStackIcon: onRemove == null ? null : () => onRemove!(signer),
      onStackIcon: Icons.remove_circle,
      enableTap: false,
      iconAlginment: CrossAxisAlignment.start,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("public_key".tr, style: context.onPrimaryTextTheme.labelLarge),
        WidgetConstant.height8,
        ContainerWithBorder(
            backgroundColor: context.onPrimaryContainer,
            child: CopyableTextWidget(
              text: signer.publicKeyHex,
              color: context.primaryContainer,
              widget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OneLineTextWidget(signer.publicKeyHex,
                      style: context.primaryTextTheme.bodyMedium),
                  AddressDrivationInfo(signer.keyIndex, color: context.primaryContainer),
                ],
              ),
            )),
        ConditionalWidget(
          enable: signer.account != null,
          onActive: (context) => ContainerWithBorder(
              backgroundColor: context.onPrimaryContainer,
              child: AddressDetailsView(
                  showBalance: false,
                  address: signer.account!,
                  color: context.primaryContainer)),
        ),
        WidgetConstant.height20,
        ConditionalWidget(
          enable: onRemove != null,
          onDeactive: (context) =>
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("weight".tr, style: context.onPrimaryTextTheme.labelLarge),
            WidgetConstant.height8,
            ContainerWithBorder(
                backgroundColor: context.onPrimaryContainer,
                child: Text(signer.weight.toString(),
                    style: context.primaryTextTheme.titleMedium)),
          ]),
          onActive: (context) =>
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("weight".tr, style: context.onPrimaryTextTheme.labelLarge),
            Text("multisig_address_weight_desc".tr),
            WidgetConstant.height8,
            ContainerWithBorder(
                backgroundColor: context.colors.surface,
                child: NumberTextField(
                    readOnly: false,
                    onChangeValue: (p0) {
                      state.onChangeWeight(signer, p0);
                    },
                    max: SuiAccountConst.multisigAccountPublicKeyMaxWeight,
                    defaultValue: signer.weight,
                    min: SuiAccountConst.multisigAccountPublicKeyMinWeight))
          ]),
        ),
      ]),
    );
  }
}

class _SuiSigner with Equality {
  final Bip32DerivationIndex keyIndex;
  final List<int> publicKey;
  final ISuiAddress? account;
  final SuiSupportKeyScheme keyScheme;
  int weight = 1;
  late final String publicKeyHex = BytesUtils.toHexString(publicKey);
  _SuiSigner({required this.keyIndex, required this.publicKey, required this.account})
      : keyScheme = SuiSupportKeyScheme.fromCoin(keyIndex.currencyCoin as Bip44Coins);

  @override
  List get variables => [publicKey];
}
