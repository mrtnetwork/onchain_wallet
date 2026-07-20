import 'package:blockchain_utils/bip/bip/conf/bip/bip_coins.dart';
import 'package:blockchain_utils/bip/bip/conf/bip44/bip44_coins.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain/aptos/aptos.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/account/controller/account_controller.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/wallet/network/aptos/account/state.dart';
import 'package:on_chain_wallet/future/wallet/security/pages/accsess_wallet.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/models/networks/aptos/models/types.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

enum _Pages { threshold, pickAddresses, review }

class SetupAptosMultisigAddress extends StatelessWidget {
  const SetupAptosMultisigAddress({super.key});

  @override
  Widget build(BuildContext context) {
    return AccessWalletView<WalletCredentialResponseLogin, WalletCredentialLogin>(
      request: WalletCredentialLogin.instance,
      title: "setup_multisig_address".tr,
      onAccsess: (_) {
        return NetworkAccountControllerView<AptosNetworkClient?, IAptosAddress?,
            AptosChain>(
          addressRequired: false,
          clientRequired: false,
          childBulder: (wallet, account, client, address) {
            return _SetupAptosMultisigAddress(account: account, wallet: wallet);
          },
        );
      },
    );
  }
}

class _SetupAptosMultisigAddress extends StatefulWidget {
  const _SetupAptosMultisigAddress({required this.account, required this.wallet});
  final AptosChain account;
  final WalletProvider wallet;

  @override
  State<_SetupAptosMultisigAddress> createState() => __SetupAptosMultisigAddressState();
}

class __SetupAptosMultisigAddressState
    extends AptosAccountState<_SetupAptosMultisigAddress> with ProgressMixin {
  @override
  AptosChain get account => widget.account;
  _Pages page = _Pages.threshold;
  List<BipCoins> coins = [];
  AptosSupportKeyScheme algorithm = AptosSupportKeyScheme.multiKey;
  void onChangeAlgorithm(AptosSupportKeyScheme? alg) {
    algorithm = alg ?? algorithm;
    signers.clear();
    switch (alg) {
      case AptosSupportKeyScheme.multiEd25519:
        coins = account.network.coins
            .where((e) => e.conf.type == EllipticCurveTypes.ed25519)
            .toList();
        break;
      case AptosSupportKeyScheme.multiKey:
        coins = account.network.coins;
        break;
      default:
    }
    updateState();
  }

  late final Map<AptosSupportKeyScheme, Widget> algorithmTypesWidget;

  final GlobalKey<FormState> formKey =
      GlobalKey(debugLabel: "__SetupAptosMultisigAddressState_formKey");

  int threshold = 2;
  bool allowAddAccount = true;
  String? error;
  int minThreshold = AptosAccountConst.mulitKeyMinRequiredSignature;

  bool get isReady => error == null;
  String? onValidateThreshold(String? v) {
    final threshold = IntUtils.tryParse(v);
    return _onValidateThreshold(threshold);
  }

  String? _onValidateThreshold(int? threshold) {
    switch (algorithm) {
      case AptosSupportKeyScheme.multiEd25519:
        if (threshold == null ||
            threshold < AptosAccountConst.mulitKeyMinRequiredSignature ||
            threshold > AptosAccountConst.multiKeyMaxRequiredSignature) {
          return "aptos_required_signature_validator"
              .tr
              .replaceOne(AptosAccountConst.mulitKeyMinRequiredSignature.toString())
              .replaceTwo(AptosAccountConst.multiKeyMaxRequiredSignature.toString());
        }
      default:
        if (threshold == null ||
            threshold < AptosAccountConst.multiEd25519MinThreshold ||
            threshold > AptosAccountConst.multiEd25519MaxKeys) {
          return "threshold_validator"
              .tr
              .replaceOne(AptosAccountConst.multiEd25519MinThreshold.toString())
              .replaceTwo(AptosAccountConst.multiEd25519MaxKeys.toString());
        }
    }
    return null;
  }

  String? validateMultiEd25519() {
    if (signers.length > AptosAccountConst.multiEd25519MaxKeys) {
      return "exceeded_multisig_maximum_publickey".tr;
    }
    if (signers.length < AptosAccountConst.multiEd25519MinKeys) {
      return "at_least_n_account_required"
          .tr
          .replaceOne(AptosAccountConst.multiEd25519MinKeys.toString());
    }
    final totalWeight = signers.length;
    if (totalWeight < threshold) {
      return "threshhold_desc3".tr;
    }
    return null;
  }

  String? validateMultiKey() {
    if (signers.length > AptosAccountConst.multiEd25519MaxKeys) {
      return "exceeded_multisig_maximum_publickey".tr;
    }
    if (signers.length < AptosAccountConst.mulitKeyMinRequiredSignature) {
      return "at_least_n_account_required"
          .tr
          .replaceOne(AptosAccountConst.mulitKeyMinRequiredSignature.toString());
    }
    final totalWeight = signers.length;
    if (totalWeight < threshold) {
      return "aptos_required_signature_validator2".tr;
    }
    return null;
  }

  String? validateMultisig() {
    final thresholdError = _onValidateThreshold(threshold);
    if (thresholdError != null) return thresholdError;
    switch (algorithm) {
      case AptosSupportKeyScheme.multiKey:
        return validateMultiKey();
      default:
        return validateMultiEd25519();
    }
  }

  void checkError() {
    error = validateMultisig();
    allowAddAccount = signers.length < AptosAccountConst.multiEd25519MaxKeys;
  }

  void onChangeThreshold(int? threshold) {
    this.threshold = threshold ?? AptosAccountConst.mulitKeyMinRequiredSignature;
    updateState();
  }

  void submitThreshold() {
    if (!formKey.ready()) return;
    page = _Pages.pickAddresses;
    checkError();
    updateState();
  }

  Set<_AptosSigner> signers = {};

  String? filterAccount(IAptosAddress address) {
    if (address.multiSigAccount) {
      return "unavailable_multi_sig_public_key".tr;
    }
    if (signers.any((e) => BytesUtils.bytesEqual(e.publicKey, address.publicKey))) {
      return "address_already_exist".tr;
    }
    if (signers.any((e) =>
        e.keyScheme.curve == address.keyScheme.curve &&
        e.keyIndex == address.derivationIndex)) {
      return "public_key_already_exist".tr;
    }
    if (algorithm == AptosSupportKeyScheme.multiEd25519) {
      if (address.keyScheme.curve != algorithm.curve) {
        return "aptos_mutli_ed25519_key_type_validator".tr;
      }
    }
    return null;
  }

  Future<void> addAddress() async {
    final address = await context.selectOrSwitchAccount<IAptosAddress>(
        account: account, showMultiSig: false, filter: filterAccount);
    if (address == null) return;
    final error = filterAccount(address);
    if (error != null) {
      context.showAlert(error.tr);
      return;
    }
    final signer = _AptosSigner(
        keyIndex: address.derivationIndex.cast(),
        publicKey: address.publicKey,
        account: address);
    signers.add(signer);
    checkError();
    updateState();
  }

  String? validatePublicKey(PublicKeyDerivationWithMode publicKey) {
    if (signers.any((e) => BytesUtils.bytesEqual(
        e.publicKey, publicKey.derivation.key.normalizedComprossedBytes))) {
      return "public_key_already_exist".tr;
    }
    if (signers.any((e) => e.keyIndex == publicKey.derivation.index)) {
      return "public_key_already_exist".tr;
    }
    if (algorithm == AptosSupportKeyScheme.multiEd25519) {
      if (publicKey.derivation.key.curve != algorithm.curve) {
        return "aptos_mutli_ed25519_key_type_validator".tr;
      }
    }
    return null;
  }

  Future<void> addPublicKey() async {
    final pubKey =
        await context.openMaxExtendSliverBottomSheet<PublicKeyDerivationWithMode>('',
            bodyBuilder: (c) => PublicKeyDerivationView(controller: c, coins: coins));
    if (pubKey == null) return;
    final error = validatePublicKey(pubKey);
    if (error != null) {
      context.showAlert(error.tr);
      return;
    }
    final signer = _AptosSigner(
        keyIndex: pubKey.derivation.index.cast(),
        publicKey: pubKey.derivation.key.normalizedComprossedBytes,
        account: account.addresses.firstWhereOrNull((e) {
          if (e.multiSigAccount) return false;
          return BytesUtils.bytesEqual(
              e.publicKey, pubKey.derivation.key.normalizedComprossedBytes);
        }));
    signers.add(signer);
    checkError();
    updateState();
  }

  void updateThreshold() {
    page = _Pages.threshold;
    updateState();
  }

  void removeAddress(_AptosSigner address) {
    signers.remove(address);
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
          .map((e) => AptosMultisigAccountPublicKeyInfo.create(
              derivationIndex: e.keyIndex.cast(),
              keyScheme: e.keyScheme,
              publicKey: e.publicKey))
          .toList();
      final multisigAccount = AptosMultisigAccountInfo.create(
          publicKeys: publicKeys, requiredSignature: threshold, keyScheme: algorithm);

      return AptosMultiSigNewAddressParams(
          multiSignatureAddress: multisigAccount, coin: account.network.coins.first);
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
  void onInitOnce() {
    super.onInitOnce();
    algorithm = AptosSupportKeyScheme.multiKey;
    coins = account.network.coins;
    algorithmTypesWidget = {
      for (final i in AptosSupportKeyScheme.values)
        if (i.isMultisig) i: Text(i.name)
    };
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
  final __SetupAptosMultisigAddressState state;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("threshold".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        ContainerWithBorder(
            onRemove: () {},
            enableTap: false,
            onRemoveWidget: IconButton(
                onPressed: () {
                  state.updateThreshold();
                },
                icon: Icon(Icons.edit, color: context.onPrimaryContainer)),
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
                    final signer = state.signers.elementAt(index);
                    return _SelectedAddressView(signer: signer, state: state);
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
  final __SetupAptosMultisigAddressState state;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ConditionalWidgets(enable: state.algorithm, widgets: {
          AptosSupportKeyScheme.multiEd25519: (context) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("threshold".tr, style: context.textTheme.titleMedium),
                  Text("threshhold_desc3".tr)
                ],
              ),
          AptosSupportKeyScheme.multiKey: (context) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("required_signature".tr, style: context.textTheme.titleMedium),
                  Text("required_signature_desc".tr)
                ],
              )
        }),
        WidgetConstant.height8,
        ContainerWithBorder(
            enableTap: false,
            onRemove: () {},
            onRemoveWidget: IconButton(
                onPressed: () {
                  state.updateThreshold();
                },
                icon: Icon(Icons.edit, color: context.onPrimaryContainer)),
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
                    final signer = state.signers.elementAt(index);
                    return _SelectedAddressView(
                        signer: signer, state: state, onRemove: state.removeAddress);
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
        ErrorTextContainer(error: state.error, enableTap: false),
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
  final __SetupAptosMultisigAddressState state;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WidgetConstant.height20,
          Text("key_scheme".tr, style: context.textTheme.titleMedium),
          WidgetConstant.height8,
          AppDropDownBottom(
              items: state.algorithmTypesWidget,
              hint: "key_scheme".tr,
              onChanged: state.onChangeAlgorithm,
              isExpanded: true,
              value: state.algorithm),
          WidgetConstant.height20,
          ConditionalWidgets(enable: state.algorithm, widgets: {
            AptosSupportKeyScheme.multiEd25519: (context) => Column(
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
                              max: AptosAccountConst.multiKeyMaxRequiredSignature,
                              min: AptosAccountConst.mulitKeyMinRequiredSignature,
                              defaultValue: state.threshold),
                        ),
                      ],
                    ),
                  ],
                ),
            AptosSupportKeyScheme.multiKey: (context) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("required_signature".tr, style: context.textTheme.titleMedium),
                    Text("required_signature_desc".tr),
                    WidgetConstant.height8,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: NumberTextField(
                              label: "required_signature".tr,
                              readOnly: false,
                              onChangeValue: state.onChangeThreshold,
                              validator: state.onValidateThreshold,
                              max: AptosAccountConst.multiKeyMaxRequiredSignature,
                              min: AptosAccountConst.mulitKeyMinRequiredSignature,
                              defaultValue: state.threshold),
                        ),
                      ],
                    ),
                  ],
                )
          }),
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

typedef _ONSELECTAPTOSSIGNER = void Function(_AptosSigner signer);

class _SelectedAddressView extends StatelessWidget {
  final _AptosSigner signer;
  final _ONSELECTAPTOSSIGNER? onRemove;
  final __SetupAptosMultisigAddressState state;
  const _SelectedAddressView({this.onRemove, required this.signer, required this.state});
  @override
  Widget build(BuildContext context) {
    return CustomizedContainer(
      enableTap: false,
      onTapStackIcon: onRemove == null ? null : () => onRemove!(signer),
      onStackIcon: Icons.remove_circle,
      child: Column(children: [
        ConditionalWidget(
          enable: signer.account != null,
          onActive: (context) => ContainerWithBorder(
              backgroundColor: context.onPrimaryContainer,
              child: AddressDetailsView(
                  showBalance: false,
                  address: signer.account!,
                  color: context.primaryContainer)),
        ),
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
      ]),
    );
  }
}

class _AptosSigner with Equality {
  final Bip32DerivationIndex keyIndex;
  final List<int> publicKey;
  final IAptosAddress? account;
  final AptosSupportKeyScheme keyScheme;
  late final String publicKeyHex = BytesUtils.toHexString(publicKey);
  _AptosSigner({required this.keyIndex, required this.publicKey, required this.account})
      : keyScheme = AptosSupportKeyScheme.fromCoin(keyIndex.currencyCoin as Bip44Coins);

  @override
  List get variables => [publicKey];
}
