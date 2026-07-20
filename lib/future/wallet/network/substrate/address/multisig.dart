import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/account/controller/account_controller.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/chain_config.dart';
import 'package:on_chain_wallet/future/wallet/network/substrate/account/state.dart';
import 'package:on_chain_wallet/future/wallet/security/pages/accsess_wallet.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:polkadot_dart/polkadot_dart.dart';

enum _Pages { threshold, pickAddresses, review }

class SetupSubstrateMultisigAddress extends StatelessWidget {
  const SetupSubstrateMultisigAddress({super.key});

  @override
  Widget build(BuildContext context) {
    return AccessWalletView<WalletCredentialResponseLogin, WalletCredentialLogin>(
      request: WalletCredentialLogin.instance,
      title: "setup_multisig_address".tr,
      onAccsess: (_) {
        return NetworkAccountControllerView<SubstrateNetworkClient, ISubstrateAddress?,
            SubstrateChain>(
          addressRequired: false,
          clientRequired: true,
          childBulder: (wallet, account, client, address) {
            return _SetupSubstrateMultisigAddress(
                account: account, wallet: wallet, client: client);
          },
        );
      },
    );
  }
}

class _SetupSubstrateMultisigAddress extends StatefulWidget {
  const _SetupSubstrateMultisigAddress(
      {required this.account, required this.wallet, required this.client});
  final SubstrateChain account;
  final WalletProvider wallet;
  final SubstrateNetworkClient client;

  @override
  State<_SetupSubstrateMultisigAddress> createState() =>
      __SetupSubstrateMultisigAddressState();
}

class __SetupSubstrateMultisigAddressState
    extends SubstrateAccountState<_SetupSubstrateMultisigAddress>
    with
        ChainConfigStateController<SubstrateChain, SubstrateChainConfig,
            SubstrateNetworkController> {
  final StreamPageProgressController progressKey =
      StreamPageProgressController(initialStatus: StreamWidgetStatus.progress);
  final int minSignatories = SubstrateAddressUtils.minMultisigThreshold;
  int maxSignatories = SubstrateAddressUtils.defaultMaxMultisigSignatories;
  @override
  SubstrateChain get account => widget.account;
  _Pages page = _Pages.threshold;
  final GlobalKey<FormState> formKey =
      GlobalKey(debugLabel: "__SetupSubstrateMultisigAddressState_formKey");
  int threshold = 2;
  bool allowAddAccount = true;
  String? error;
  bool get isReady => error == null;
  List<_SubstrateSigner> signers = [];
  String? onValidateThreshold(String? v) {
    final threshold = IntUtils.tryParse(v);
    if (threshold == null || threshold < minSignatories || threshold > maxSignatories) {
      return "threshold_validator"
          .tr
          .replaceOne(minSignatories.toString())
          .replaceTwo(maxSignatories.toString());
    }
    return null;
  }

  String? validateMultisig() {
    final threshold = this.threshold;
    final String? err = onValidateThreshold(threshold.toString());
    if (err != null) {
      return err;
    }
    if (signers.isEmpty) {
      return "at_least_one_account_required".tr;
    }
    if (signers.length < threshold) {
      return "total_number_of_signers_must_reach_threshold".tr;
    }

    return null;
  }

  void checkError() {
    error = validateMultisig();
    allowAddAccount = signers.length < maxSignatories;
  }

  void onChangeThreshold(int? threshold) {
    this.threshold = threshold ?? minSignatories;
    updateState();
  }

  void submitThreshold() {
    if (!formKey.ready()) return;
    page = _Pages.pickAddresses;
    checkError();
    updateState();
  }

  String? filterAccount(BaseSubstrateAddress address) {
    final accountAddress = account.getAddressSync(networkAddress: address);
    if (accountAddress != null && accountAddress.multiSigAccount) {
      return "unavailable_multi_sig_public_key".tr;
    }
    if (signers.any((e) => e.address.networkAddress.rawAddress == address.rawAddress)) {
      return "address_already_exist".tr;
    }
    return null;
  }

  Future<void> addAddress() async {
    final addresses = await context.selectAccount<BaseSubstrateAddress>(
        account: account, multipleSelect: true, onFilterAccount: filterAccount);
    if (addresses == null) return;
    signers = {
      ...signers,
      ...addresses.map((e) => _SubstrateSigner(
          account.getOrCreateReceiptFromNetworkAddressSync(address: e.networkAddress)))
    }.toList();
    checkError();
    updateState();
  }

  void updateThreshold() {
    page = _Pages.threshold;
    updateState();
  }

  void removeAddress(_SubstrateSigner signer) {
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

  CryptoCoins findCoin() {
    final coins = account.network.coins;
    return coins.firstWhere((e) => e.conf.type == EllipticCurveTypes.secp256k1,
        orElse: () => coins.first);
  }

  Future<void> generateAddress() async {
    progressKey.progressText("setup_address".tr);
    final r = await IResult.call(() async {
      final multisig = SubstrateMultisigAccountInfo.create(
          signers: signers.map((e) => e.address.networkAddress).toList(),
          threshold: threshold,
          maxSigntories: maxSignatories);
      final address =
          multisig.toAddress(ss58Format: account.network.coinParam.ss58Format);
      CryptoCoins coin = findCoin();
      return SubstrateMultiSigNewAddressParams(
          multiSignatureAddress: multisig, coin: coin, address: address);
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

  Future<void> init() async {
    if (!widget.client.metadata.supportMultisig) {
      progressKey.errorText("unsupported_current_network_feature".tr, backToIdle: false);
      return;
    }
    progressKey.backToIdle();
    final config = await getChainConfig(
        walletProvider: context.wallet,
        type: account.network.type,
        onCreate: () => SubstrateChainConfig());

    if (!config.acceptMultisigTerm) {
      final success = await context.openDialogPage<bool>("setup_multisig_address".tr,
          widget: (context) => DialogTitleAndMultiTextView(
                title: "before_you_continue".tr,
                buttonWidget: DialogSingleButtonView(
                  buttonLabel: "got_it_dont_show_again".tr,
                ),
                content: [
                  "substrate_multisig_same_network_desc".tr,
                  "substrate_multisig_eth_incompatible_desc".tr,
                  "substrate_multisig_cannot_validate_all_desc".tr,
                  "substrate_multisig_network_uncertainty_desc".tr,
                ],
              ));
      if (success == true) {
        await updateChainConfig(
            walletProvider: context.wallet,
            config: config.copyWith(acceptMultisigTerm: true),
            type: account.network.type);
      }
    }
    progressKey.backToIdle();
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    maxSignatories = widget.client.metadata.maxSignatories ?? maxSignatories;
    init();
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
  final __SetupSubstrateMultisigAddressState state;

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
        Text("list_of_signers".tr, style: context.textTheme.titleMedium),
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
  final __SetupSubstrateMultisigAddressState state;

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
        Text("list_of_signers".tr, style: context.textTheme.titleMedium),
        Text("substrate_chose_signer_desc".tr),
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
                  onRemove: state.addAddress,
                  enableTap: true,
                  onRemoveIcon: Icon(Icons.add_box, color: context.onPrimaryContainer),
                  child: Text("tap_to_choose_address".tr),
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
  final __SetupSubstrateMultisigAddressState state;

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
                    max: state.maxSignatories,
                    min: state.minSignatories,
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

typedef _ONSELECTSUBSTRATESIGNER = void Function(_SubstrateSigner signer);

class _ShowAddressView extends StatelessWidget {
  final _SubstrateSigner signer;
  final __SetupSubstrateMultisigAddressState state;
  final _ONSELECTSUBSTRATESIGNER? onRemove;
  const _ShowAddressView({required this.signer, required this.state, this.onRemove});
  @override
  Widget build(BuildContext context) {
    return CustomizedContainer(
        enableTap: false,
        onTapStackIcon: onRemove == null ? null : () => onRemove!(signer),
        onStackIcon: Icons.remove_circle,
        iconAlginment: CrossAxisAlignment.start,
        child: ReceiptAddressDetailsView(
            address: signer.address, color: context.onPrimaryContainer));
  }
}

class _SubstrateSigner with Equality {
  final ReceiptAddress<BaseSubstrateAddress> address;
  _SubstrateSigner(this.address);

  @override
  List get variables => [address.networkAddress.rawAddress];
}
