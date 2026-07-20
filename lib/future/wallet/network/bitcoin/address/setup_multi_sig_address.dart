import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/constant/networks/bitcoin.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class SetupBitcoinMultiSigAddressView extends StatefulWidget {
  const SetupBitcoinMultiSigAddressView({super.key});

  @override
  State<SetupBitcoinMultiSigAddressView> createState() =>
      _SetupBitcoinMultiSigAddressViewState();
}

class _SetupBitcoinMultiSigAddressViewState extends State<SetupBitcoinMultiSigAddressView>
    with SafeState<SetupBitcoinMultiSigAddressView> {
  bool get inReview => _multiSigAddress != null;
  late final BitcoinChain chainAccount;
  _BitcoinMultisigAddress? _multiSigAddress;
  _BitcoinMultisigAddress get multiSigAddress => _multiSigAddress!;
  final StreamPageProgressController progressKey = StreamPageProgressController();
  final GlobalKey<StreamWidgetState> buttonState = GlobalKey();
  final Map<String, _BitcoinMultisigSigner> _signers = {};
  List<_BitcoinMultisigSigner> get signers => _signers.values.toList();
  WalletBitcoinNetwork get network => chainAccount.network;
  int threshold = BtcConst.minMultiSigThreshold;
  bool isReady = false;
  bool signersReady = false;

  void onAddSigner(IBitcoinAddress? acc) {
    if (acc == null) return;
    if (acc.multiSigAccount) {
      context.showAlert("unavailable_multi_sig_public_key".tr);
      return;
    }
    final pubKeyHex = BytesUtils.toHexString(acc.publicKey);
    if (_signers.containsKey(pubKeyHex)) {
      context.showAlert("public_key_already_exist".tr);
      return;
    }
    final newAcc = _BitcoinMultisigSigner(
        publicKey: pubKeyHex,
        keyIndex: acc.derivationIndex.cast(),
        account: chainAccount.getOrCreateReceiptFromNetworkAddressSync(account: acc));

    _signers.addAll({newAcc.publicKey: newAcc});
    onStateUpdated();
  }

  void onAddPublicKey(PublicKeyDerivationWithMode? pubKey) {
    if (pubKey == null) return;
    final key = pubKey.selectedKey();
    if (_signers.containsKey(key)) {
      context.showAlert("public_key_already_exist".tr);
      return;
    }
    final newAcc = _BitcoinMultisigSigner(
        publicKey: key, keyIndex: pubKey.derivation.index, account: null);
    _signers.addAll({newAcc.publicKey: newAcc});
    onStateUpdated();
  }

  void onRemovePublicKey(_BitcoinMultisigSigner signer) {
    _signers.remove(signer.publicKey);
    onStateUpdated();
  }

  void onChangeSignerWeight(_BitcoinMultisigSigner address, int? weight) {
    address.onUpdateWight(weight ?? 1);
    onStateUpdated();
  }

  void onStateUpdated() {
    final signerWeight = _signerWeight();
    signersReady = signerWeight != null;
    isReady = signersReady && signerWeight! >= threshold;
    updateState();
  }

  void onChangeThreshHold(BigRational? v) {
    if (v == null || v.isDecimal || v.isNegative) return;
    final threshold = v.toBigInt().toInt();
    if (threshold > BtcConst.maxMultiSigThreshold ||
        threshold < BtcConst.minMultiSigThreshold) {
      return;
    }
    this.threshold = threshold;
    onStateUpdated();
  }

  int? _signerWeight() {
    if (_signers.isEmpty) return null;
    int sum = 0;
    for (final i in _signers.values) {
      if (i.weight > threshold) {
        return null;
      } else if (i.weight < 1) {
        return null;
      }
      sum += i.weight;
    }
    return sum;
  }

  void onReview() {
    if (!isReady) return;
    final signers = _signers.values.toList();
    _multiSigAddress = _BitcoinMultisigAddress(
        signers: signers,
        multiSigAddress: BitcoinMultiSignatureAddress(
            threshold: threshold,
            signers: signers.map((e) => e.toMultisigSigner()).toList()),
        network: network.coinParam.transacationNetwork);
    updateState();
  }

  void _onBack() {
    try {
      if (progressKey.isSuccess) return;
      if (!inReview) return;
      _multiSigAddress = null;
    } finally {
      updateState();
    }
  }

  void onChangeAddressType(BitcoinAddressType? selectType) {
    if (selectType == null) return;
    _multiSigAddress?.onChangeAddressType(selectType);
    updateState();
  }

  Future<void> onSetupAddress(bool? accept) async {
    final msig = _multiSigAddress;
    if (accept != true || msig == null) return;
    progressKey.progressText("setup_address".tr);
    final wallet = context.wallet.wallet;
    final NewAccountParams accountParams;
    if (network.type == NetworkType.bitcoinCash) {
      accountParams = BitcoinCashMultiSigNewAddressParams(
          coin: network.findCoinFromBitcoinAddressType(msig.multiSigAddressTye),
          bitcoinAddressType: msig.multiSigAddressTye,
          multiSignatureAddress: msig.multiSigAddress);
    } else {
      accountParams = BitcoinMultiSigNewAddressParams(
          coin: network.findCoinFromBitcoinAddressType(msig.multiSigAddressTye),
          bitcoinAddressType: msig.multiSigAddressTye,
          multiSignatureAddress: msig.multiSigAddress);
    }
    final result = await wallet.doAction(WalletActionDeriveNewAccount(
        newAccountParams: accountParams, chain: chainAccount));
    if (result.isErr) {
      progressKey.errorText(result.unwrapErr().localizationError);
    } else {
      progressKey.success(
          backToIdle: false,
          progressWidget: SuccessWithButtonView(
            buttonWidget: ContainerWithBorder(
                margin: WidgetConstant.paddingVertical8,
                child: AddressDetailsView(address: result.unwrap())),
            buttonText: "generate_new_address".tr,
            onPressed: () {
              if (mounted) {
                progressKey.backToIdle();
              }
            },
          ));
    }
    updateState();
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    chainAccount = context.getArgruments();
  }

  @override
  void safeDispose() {
    super.safeDispose();
    progressKey.dispose();
    _multiSigAddress = null;
    _signers.clear();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: progressKey.isSuccess || !inReview,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _onBack();
        }
      },
      child: ScaffoldPageView(
        appBar: AppBar(title: Text("generate_address".tr)),
        child: StreamPageProgress(
          controller: progressKey,
          builder: (c) => Center(
            child: CustomScrollView(
              shrinkWrap: true,
              slivers: [
                SliverConstraintsBoxView(
                    padding: WidgetConstant.padding20,
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
                      SliverToBoxAdapter(
                          child: APPAnimated(
                              isActive: inReview,
                              onActive: (context) => _BitcoinMutlsigAddressReview(this),
                              onDeactive: (context) =>
                                  _BitcoinMultisigAddressSetup(this)))
                    ])),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BitcoinMultisigAddressSetup extends StatelessWidget {
  final _SetupBitcoinMultiSigAddressViewState state;
  const _BitcoinMultisigAddressSetup(this.state);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("threshold".tr, style: context.textTheme.titleMedium),
        Text("threshhold_desc3".tr),
        WidgetConstant.height8,
        ContainerWithBorder(
            onRemoveIcon: AddOrEditIconWidget(true),
            onRemove: () {
              context
                  .openMaxExtendSliverBottomSheet<BigRational>(
                    "threshold".tr,
                    child: NumberWriteView(
                        defaultValue: BtcConst.minMultiSigThresholdRational,
                        min: BtcConst.minMultiSigThresholdRational,
                        max: BtcConst.maxMultiSigThresholdRational,
                        allowDecimal: false,
                        allowSign: false,
                        title: PageTitleSubtitle(
                            title: "threshold".tr,
                            body: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [Text("threshhold_desc3".tr)])),
                        buttonText: "setup_input".tr,
                        label: "threshold".tr),
                  )
                  .then(state.onChangeThreshHold);
            },
            child: Text(state.threshold.toString(),
                style: context.onPrimaryTextTheme.bodyMedium)),
        WidgetConstant.height20,
        Text("list_of_public_keys".tr, style: context.textTheme.titleMedium),
        Text("choose_public_key_or_generate_new_on".tr),
        WidgetConstant.height8,
        AnimatedSize(
          duration: APPConst.animationDuraion,
          child: Column(
            key: ValueKey<int>(state.signers.length),
            children: List.generate(state.signers.length, (index) {
              final signer = state.signers[index];
              return CustomizedContainer(
                  enableTap: false,
                  onTapStackIcon: () => state.onRemovePublicKey(signer),
                  onStackIcon: Icons.remove_circle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OneLineTextWidget(signer.publicKey,
                          style: context.onPrimaryTextTheme.bodyMedium),
                      AddressDrivationInfo(signer.keyIndex,
                          color: context.onPrimaryContainer),
                      Divider(color: context.onPrimaryContainer),
                      ContainerWithBorder(
                        backgroundColor: context.colors.surface,
                        child: NumberTextField(
                            iconColor: context.colors.onSurface,
                            label: "weight".tr,
                            maxWidth: double.infinity,
                            defaultValue: signer.weight,
                            readOnly: true,
                            onChangeValue: (p0) {
                              state.onChangeSignerWeight(signer, p0);
                            },
                            max: state.threshold,
                            min: 1),
                      )
                    ],
                  ));
            }),
          ),
        ),
        APPAnimated(
          isActive: true,
          onActive: (context) => ContainerWithBorder(
              onRemove: () {},
              enableTap: false,
              validate: state._signers.isNotEmpty,
              onRemoveWidget: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                      tooltip: 'accounts'.tr,
                      onPressed: () {
                        context
                            .selectOrSwitchAccount<IBitcoinAddress>(
                                account: state.chainAccount, showMultiSig: false)
                            .then(state.onAddSigner);
                      },
                      icon: Icon(Icons.supervisor_account_rounded)),
                  IconButton(
                      tooltip: 'generate_public_key'.tr,
                      onPressed: () {
                        context
                            .openMaxExtendSliverBottomSheet<PublicKeyDerivationWithMode>(
                                '',
                                bodyBuilder: (c) => PublicKeyDerivationView(
                                    controller: c,
                                    pubKeyMode: null,
                                    coins: state.chainAccount.network.coins))
                            .then(state.onAddPublicKey);
                      },
                      icon: Icon(Icons.add_box)),
                ],
              ),
              child: Text("tap_to_chose_or_create_public_key".tr)),
        ),
        APPAnimated(
            isActive: !state.isReady,
            onActive: (context) => ErrorTextContainer(
                error: state.signersReady ? "threshhold_desc3".tr : null,
                showErrorIcon: true,
                enableTap: false)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FixedElevatedButton(
                padding: WidgetConstant.paddingVertical40,
                onPressed: state.onReview,
                activePress: state.isReady,
                child: Text("review_address".tr))
          ],
        )
      ],
    );
  }
}

class _BitcoinMutlsigAddressReview extends StatelessWidget {
  final _SetupBitcoinMultiSigAddressViewState state;
  const _BitcoinMutlsigAddressReview(this.state);

  @override
  Widget build(BuildContext context) {
    final mSig = state.multiSigAddress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("type_of_address".tr, style: context.textTheme.titleMedium),
        WidgetConstant.height8,
        RadioGroup<BitcoinAddressType>(
            groupValue: mSig.multiSigAddressTye,
            onChanged: state.onChangeAddressType,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(mSig.supportTyes.length, (index) {
                  final supportTypes = mSig.supportTyes.keys.toList();
                  final key = supportTypes[index];
                  final view = mSig.supportTyes[key]!;
                  return RadioListTile<BitcoinAddressType>(title: Text(view), value: key);
                }))),
        AnimatedSwitcher(
          duration: APPConst.animationDuraion,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            key: ValueKey<BitcoinAddressType>(mSig.multiSigAddressTye),
            children: [
              WidgetConstant.height20,
              Text("address".tr, style: context.textTheme.titleMedium),
              WidgetConstant.height8,
              ContainerWithBorder(
                  child: CopyTextIcon(
                      isSensitive: false,
                      widget: SelectableText(mSig.addressStr),
                      dataToCopy: mSig.addressStr)),
              WidgetConstant.height20,
              Text("list_of_public_keys".tr, style: context.textTheme.titleMedium),
              Text("public_keys_and_weight_of_each".tr),
              WidgetConstant.height8,
              Column(
                children: List.generate(mSig.signers.length, (index) {
                  final signer = mSig.signers[index];
                  return ContainerWithBorder(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AddressDrivationInfo(signer.keyIndex,
                          color: context.onPrimaryContainer),
                      OneLineTextWidget(signer.publicKey,
                          style: context.onPrimaryTextTheme.bodyMedium),
                      Divider(color: context.onPrimaryContainer),
                      Text(signer.weight.toString(),
                          style: context.onPrimaryTextTheme.bodyMedium),
                    ],
                  ));
                }),
              ),
              WidgetConstant.height20,
              Text("multi_sig_script".tr, style: context.textTheme.titleMedium),
              WidgetConstant.height8,
              ContainerWithBorder(
                  child: LargeTextContainer(
                      text: state.multiSigAddress.viewScript,
                      color: context.onPrimaryContainer,
                      maxLines: 5)),
              WidgetConstant.height20,
              Text("address_script".tr, style: context.textTheme.titleMedium),
              WidgetConstant.height8,
              ContainerWithBorder(
                  child: CopyableTextWidget(
                      text: state.multiSigAddress.scriptPubKey,
                      color: context.onPrimaryContainer,
                      maxLines: 5)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FixedElevatedButton(
                    padding: WidgetConstant.paddingVertical40,
                    onPressed: () {
                      context
                          .openSliverDialog<bool>(
                              widget: (p0) => DialogTextView(
                                    text: "backup_multi_sig_address_desc".tr,
                                    buttonWidget: const DialogDoubleButtonView(),
                                  ),
                              label: "backup".tr)
                          .then(state.onSetupAddress);
                    },
                    child: Text("setup_address".tr),
                  ),
                ],
              ),
            ],
          ),
        )
      ],
    );
  }
}

class _BitcoinMultisigSigner {
  final String publicKey;
  final ReceiptAddress<BitcoinNetworkAddress>? account;
  final DerivableIndex keyIndex;
  _BitcoinMultisigSigner(
      {required this.publicKey, required this.account, required this.keyIndex});
  int weight = 1;
  bool isValid(int threshold) {
    return weight >= 1 && weight <= threshold;
  }

  void onUpdateWight(final int weight) {
    this.weight = weight;
  }

  BitcoinMultiSigSignerDetails toMultisigSigner() {
    return BitcoinMultiSigSignerDetails(
        derivationIndex: keyIndex,
        publicKey: BytesUtils.fromHexString(publicKey),
        weight: weight);
  }
}

class _BitcoinMultisigAddress {
  final List<_BitcoinMultisigSigner> signers;
  final BitcoinMultiSignatureAddress multiSigAddress;
  final BasedUtxoNetwork network;
  final String viewScript;
  final Map<BitcoinAddressType, String> supportTyes;
  late String addressStr;
  late String scriptPubKey;
  late BitcoinBaseAddress address;
  BitcoinAddressType multiSigAddressTye = P2shAddressType.p2pkhInP2sh;
  _BitcoinMultisigAddress(
      {required this.multiSigAddress, required this.network, required this.signers})
      : viewScript = multiSigAddress.multiSigScript.script.join(" "),
        supportTyes =
            buildMultisigTypes(multiSigAddress: multiSigAddress, network: network) {
    address = generateAddress();
    scriptPubKey = address.toScriptPubKey().script.join(" ");
    addressStr = address.toAddress(network);
  }

  BitcoinBaseAddress generateAddress() {
    switch (multiSigAddressTye) {
      case SegwitAddressType.p2wsh:
        return multiSigAddress.toP2wshAddress(network: network);
      case P2shAddressType.p2pkhInP2sh:
      case P2shAddressType.p2pkhInP2sh32:
      case P2shAddressType.p2pkhInP2shwt:
      case P2shAddressType.p2pkhInP2sh32wt:
        return multiSigAddress.toP2shAddress(addressType: multiSigAddressTye.cast());
      default:
        return multiSigAddress.toP2wshInP2shAddress(network: network);
    }
  }

  void onChangeAddressType(BitcoinAddressType type) {
    if (!supportTyes.containsKey(type)) return;
    multiSigAddressTye = type;
    address = generateAddress();
    scriptPubKey = address.toScriptPubKey().script.join(" ");
    addressStr = address.toAddress(network);
  }

  static Map<BitcoinAddressType, String> buildMultisigTypes(
      {required BitcoinMultiSignatureAddress multiSigAddress,
      required BasedUtxoNetwork network}) {
    final List<BitcoinAddressType> supportTyes = network.supportedAddress;
    final Map<BitcoinAddressType, String> supportedMultisigTypes = {};
    supportedMultisigTypes[P2shAddressType.p2pkhInP2sh] = "P2SH";
    if (supportTyes.contains(P2shAddressType.p2pkhInP2sh32)) {
      supportedMultisigTypes[P2shAddressType.p2pkhInP2shwt] = "P2SHWT";
      supportedMultisigTypes[P2shAddressType.p2pkhInP2sh32] = "P2SH32";
      supportedMultisigTypes[P2shAddressType.p2pkhInP2sh32wt] = "P2SH32WT";
    }
    if (supportTyes.contains(SegwitAddressType.p2wpkh) &&
        multiSigAddress.canSelectSegwit) {
      supportedMultisigTypes[P2shAddressType.p2wshInP2sh] =
          P2shAddressType.p2wshInP2sh.name;
      supportedMultisigTypes[SegwitAddressType.p2wsh] = SegwitAddressType.p2wsh.name;
    }
    return supportedMultisigTypes.immutable;
  }
}
