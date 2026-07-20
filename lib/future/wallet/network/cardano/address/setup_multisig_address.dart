import 'dart:async';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/crypto.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/cardano/cardano.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/others/models/receipt_address.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';

class SetupCardanoMultisigAddress extends StatelessWidget {
  const SetupCardanoMultisigAddress({super.key});

  @override
  Widget build(BuildContext context) {
    return NetworkAccountControllerView<ADANetworkClient?, ICardanoAddress?, ADAChain>(
        childBulder: (wallet, account, client, address) {
          return _SetupCardanoMultisigAddress(account: account);
        },
        addressRequired: false,
        clientRequired: false,
        title: "setup_multisig_address".tr);
  }
}

class _SetupCardanoMultisigAddress extends StatefulWidget {
  final ADAChain account;
  const _SetupCardanoMultisigAddress({required this.account});

  @override
  State<_SetupCardanoMultisigAddress> createState() =>
      __SetupCardanoMultisigAddressState();
}

class __SetupCardanoMultisigAddressState extends State<_SetupCardanoMultisigAddress>
    with SafeState<_SetupCardanoMultisigAddress> {
  StreamSubscription<void>? listener;
  late final _SetupCardanoMultisigForm form = _SetupCardanoMultisigForm(widget.account);

  @override
  void onInitOnce() {
    super.onInitOnce();
    listener = form.stream.listen((void _) => updateState());
  }

  @override
  void safeDispose() {
    super.safeDispose();
    listener?.cancel();
    listener = null;
    form.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamPageProgress(
        controller: form.controller,
        builder: (context) => CustomScrollView(slivers: [
              SliverConstraintsBoxView(
                padding: WidgetConstant.paddingHorizontal20,
                sliver: MultiSliver(
                  children: [
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
                      child: ConditionalWidget(
                          onDeactive: (context) => Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ReceiptAddressView(
                                      title: 'address'.tr,
                                      address: form.generatedAddress?.address,
                                    ),
                                    WidgetConstant.height20,
                                    ConditionalWidget(
                                        enable:
                                            form.generatedAddress?.rewardAddress != null,
                                        onActive: (context) => ReceiptAddressView(
                                              title: 'reward_address'.tr,
                                              address:
                                                  form.generatedAddress?.rewardAddress,
                                            )),
                                    Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          FixedElevatedButton(
                                              activePress: form.isReady,
                                              padding: WidgetConstant.paddingVertical40,
                                              onPressed: () =>
                                                  form.importToAccount(context.wallet),
                                              child: Text("import_to_wallet".tr))
                                        ])
                                  ]),
                          enable: form.generatedAddress == null,
                          onActive: (context) => Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    WidgetConstant.height20,
                                    Text("address_type".tr,
                                        style: context.textTheme.titleMedium),
                                    WidgetConstant.height8,
                                    AppDropDownBottom<ADAAddressType>(
                                        items: {
                                          ADAAddressType.base: Text("base".tr),
                                          ADAAddressType.reward: Text("reward".tr),
                                          ADAAddressType.enterprise:
                                              Text("enterprise".tr),
                                        },
                                        value: form.addressType,
                                        onChanged: form.onChangeAddressType,
                                        hint: "shelley_address_format".tr),
                                    WidgetConstant.height20,
                                    Text("base_credential".tr,
                                        style: context.textTheme.titleMedium),
                                    Text("fill_out_base_address_credential".tr),
                                    WidgetConstant.height8,
                                    Padding(
                                      padding: WidgetConstant.paddingHorizontal20,
                                      child: _CredentialView(
                                        account: form.account,
                                        pubKeys: form.addressPubKeys,
                                        threshold: form.addressWeight,
                                        onSetupWeight: form.onSetupAddressWeight,
                                        onSetupAddress: form.onUpdateAddressPubKey,
                                        onSetupPublicKey: form.onGenerateAddressPubKey,
                                        isReady: form.baseCredenticalIsReady,
                                        allowImportPublicKey:
                                            form.allowImportBasePublicKey,
                                        onRemovePublicKey: form.onRemoveAddressPublicKey,
                                        credentialType: form.addressCredentialType,
                                        onChangeCredentialType:
                                            form.onChangeCredentialType,
                                      ),
                                    ),
                                    APPAnimated(
                                        isActive: form.isBaseAddress,
                                        onActive: (context) => Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  WidgetConstant.height20,
                                                  Text("stake_credential".tr,
                                                      style:
                                                          context.textTheme.titleMedium),
                                                  Text(
                                                      "fill_out_base_address_stake_credential"
                                                          .tr),
                                                  WidgetConstant.height8,
                                                  Padding(
                                                    padding: WidgetConstant
                                                        .paddingHorizontal20,
                                                    child: _CredentialView(
                                                        account: form.account,
                                                        pubKeys: form.stakePubKeys,
                                                        threshold: form.stakeWeight,
                                                        onSetupWeight:
                                                            form.onSetupStakeWeight,
                                                        onSetupAddress:
                                                            form.onUpdateStakePubKey,
                                                        onSetupPublicKey:
                                                            form.onGenerateStakePubKey,
                                                        onRemovePublicKey:
                                                            form.onRemoveStakePublicKey,
                                                        isReady:
                                                            form.satkeCredenticalIsReady,
                                                        allowImportPublicKey: form
                                                            .allowImportStakePublicKey,
                                                        credentialType:
                                                            form.stakeCredentialType,
                                                        onChangeCredentialType: form
                                                            .onChangeStakeCredentialType),
                                                  ),
                                                ])),
                                    ErrorTextContainer(error: form.error),
                                    Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          FixedElevatedButton(
                                              activePress: form.isReady,
                                              padding: WidgetConstant.paddingVertical40,
                                              onPressed: form.generateAddress,
                                              child: Text("review_address".tr))
                                        ])
                                  ])),
                    ),
                  ],
                ),
              )
            ]));
  }
}

typedef _ONCHANGECREDENTIALTYPE = void Function(CardanoCredentialType?);

class _CredentialView extends StatelessWidget {
  final BigRational? threshold;
  final List<_CardanoMultisigPublicKeys> pubKeys;
  final _ONSETUPWEIGHT onSetupWeight;
  final _ONSETUPPublicKey onSetupPublicKey;
  final _ONSETUPADDRESS onSetupAddress;
  final _ONREMOVEPUBLICKEY onRemovePublicKey;
  final ADAChain account;
  final bool isReady;
  final bool allowImportPublicKey;
  final CardanoCredentialType credentialType;
  final _ONCHANGECREDENTIALTYPE onChangeCredentialType;
  const _CredentialView({
    required this.pubKeys,
    required this.onSetupWeight,
    required this.onSetupPublicKey,
    required this.onSetupAddress,
    required this.account,
    required this.isReady,
    required this.allowImportPublicKey,
    required this.onRemovePublicKey,
    required this.credentialType,
    required this.onChangeCredentialType,
    this.threshold,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasThreshold = credentialType.isPublicKey || threshold != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("credential_type".tr, style: context.textTheme.titleMedium),
      WidgetConstant.height8,
      AppDropDownBottom<CardanoCredentialType>(
          items: {for (final i in CardanoCredentialType.values) i: Text(i.name.tr)},
          value: credentialType,
          onChanged: onChangeCredentialType,
          hint: "credential_type".tr),
      WidgetConstant.height20,
      APPAnimated(
          isActive: !credentialType.isPublicKey,
          onActive: (context) =>
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("threshold".tr, style: context.textTheme.titleMedium),
                Text("threshhold_desc3".tr),
                WidgetConstant.height8,
                ContainerWithBorder(
                  validate: hasThreshold,
                  onRemoveIcon: AddOrEditIconWidget(hasThreshold),
                  onRemove: () {
                    context
                        .openMaxExtendSliverBottomSheet<BigRational>(
                          "threshold".tr,
                          child: NumberWriteView(
                            defaultValue: threshold ?? BigRational.one,
                            min: BigRational.one,
                            max: CardanoUtils.maxMultisigThreshold,
                            allowDecimal: false,
                            allowSign: false,
                            title: PageTitleSubtitle(
                                title: "threshold".tr,
                                body: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("threshhold_desc3".tr),
                                    ])),
                            buttonText: "setup_input".tr,
                            label: "threshold".tr,
                          ),
                        )
                        .then(onSetupWeight);
                  },
                  child: Text(threshold?.toString().to3Digits ?? "tap_to_input_value".tr,
                      style: context.onPrimaryTextTheme.bodyMedium),
                ),
                WidgetConstant.height20
              ])),
      APPAnimated(
          isActive: hasThreshold,
          onActive: (context) =>
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("list_of_public_keys".tr, style: context.textTheme.titleMedium),
                Text("choose_public_key_or_generate_new_on".tr),
                WidgetConstant.height8,
                APPAnimated(
                    isActive: pubKeys.isNotEmpty,
                    onActive: (context) => APPExpansionListTile(
                          margin: WidgetConstant.padding5,
                          title: RichText(
                              text: TextSpan(
                                  text: "public_keys".tr,
                                  style: context.onPrimaryTextTheme.bodyMedium,
                                  children: [
                                WidgetSpan(child: WidgetConstant.width8),
                                TextSpan(
                                    text: "n_item_selected"
                                        .tr
                                        .replaceOne(pubKeys.length.toString()),
                                    style: context.onPrimaryTextTheme.bodySmall)
                              ])),
                          children: [
                            ListView.separated(
                                itemCount: pubKeys.length,
                                shrinkWrap: true,
                                separatorBuilder: (context, index) =>
                                    Divider(color: context.onPrimaryContainer),
                                physics: WidgetConstant.noScrollPhysics,
                                itemBuilder: (context, i) => _SelectedPubkeysView(
                                    pubkey: pubKeys[i],
                                    onRemovePublicKey: onRemovePublicKey)),
                          ],
                        )),
                APPAnimated(
                  isActive: allowImportPublicKey,
                  onActive: (context) => ContainerWithBorder(
                    onRemove: () {},
                    enableTap: false,
                    validate: isReady,
                    // errorIcon: ,
                    onRemoveWidget: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                            tooltip: 'accounts'.tr,
                            onPressed: () {
                              context
                                  .selectOrSwitchAccount<ICardanoAddress>(
                                      account: account, showMultiSig: false)
                                  .then(onSetupAddress);
                            },
                            icon: Icon(Icons.supervisor_account_rounded)),
                        IconButton(
                            tooltip: 'generate_public_key'.tr,
                            onPressed: () {
                              context
                                  .openMaxExtendSliverBottomSheet<
                                      PublicKeyDerivationWithMode>(
                                    '',
                                    bodyBuilder: (c) => PublicKeyDerivationView(
                                        controller: c, coins: account.network.coins),
                                  )
                                  .then(onSetupPublicKey);
                            },
                            icon: Icon(Icons.add_box)),
                      ],
                    ),
                    child: Text("tap_to_chose_or_create_public_key".tr),
                  ),
                ),
                ErrorTextContainer(
                  enableTap: false,
                  error: isReady
                      ? null
                      : "at_least_n_public_keys_required"
                          .tr
                          .replaceOne(threshold?.toBigInt().toString() ?? '1'),
                )
              ]))
    ]);
  }
}

typedef _ONREMOVEPUBLICKEY = void Function(_CardanoMultisigPublicKeys);

class _SelectedPubkeysView extends StatelessWidget {
  final _CardanoMultisigPublicKeys pubkey;
  final _ONREMOVEPUBLICKEY onRemovePublicKey;
  const _SelectedPubkeysView({required this.pubkey, required this.onRemovePublicKey});

  @override
  Widget build(BuildContext context) {
    return CustomizedContainer(
      onTapStackIcon: () => onRemovePublicKey(pubkey),
      enableTap: false,
      onRemoveIcon: Icon(Icons.remove_circle, color: context.primaryContainer),
      backgroundColor: context.onPrimaryContainer,
      reverseColor: context.primaryContainer,
      child: Column(children: [
        ConditionalWidget(
          enable: pubkey.address != null,
          onActive: (context) => ContainerWithBorder(
              backgroundColor: context.primaryContainer,
              child: AddressDetailsView(
                  showBalance: false,
                  address: pubkey.address!,
                  color: context.onPrimaryContainer)),
        ),
        ContainerWithBorder(
            backgroundColor: context.primaryContainer,
            child: CopyableTextWidget(
              text: pubkey.key,
              color: context.onPrimaryContainer,
              widget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OneLineTextWidget(pubkey.key,
                      style: context.onPrimaryTextTheme.bodyMedium),
                  AddressDrivationInfo(pubkey.keyIndex,
                      color: context.onPrimaryContainer),
                ],
              ),
            )),
      ]),
    );
  }
}

class _CardanoMultisigPublicKeys with Equality {
  final PublicKeyDerivationWithMode? publicKey;
  final ICardanoAddress? address;
  final String key;
  final DerivationIndex keyIndex;
  const _CardanoMultisigPublicKeys(
      {this.publicKey, this.address, required this.key, required this.keyIndex});
  @override
  List get variables => [key];
}

typedef _ONSETUPWEIGHT = void Function(BigRational?);
typedef _ONSETUPADDRESS = void Function(ICardanoAddress?);
typedef _ONSETUPPublicKey = void Function(PublicKeyDerivationWithMode?);

class _CardanoGeneratedAddress {
  final CardanoMultiSignatureAddressDetails multiSigAddresInfo;
  final ReceiptAddress<ADAAddress> address;
  final ReceiptAddress<ADAAddress>? rewardAddress;
  const _CardanoGeneratedAddress({
    required this.multiSigAddresInfo,
    required this.address,
    required this.rewardAddress,
  });
}

class _SetupCardanoMultisigForm with DisposableMixin, StreamStateController {
  final ADAChain account;
  _SetupCardanoMultisigForm(this.account);
  final StreamPageProgressController controller = StreamPageProgressController();
  _CardanoGeneratedAddress? generatedAddress;

  late final int maxThreshold = CardanoUtils.maxMultisigThreshold.toBigInt().toInt();
  String? _error;
  String? get error => _error;
  BigRational? stakeWeight;
  BigRational? addressWeight;
  CardanoCredentialType addressCredentialType = CardanoCredentialType.script;
  CardanoCredentialType stakeCredentialType = CardanoCredentialType.script;

  final List<_CardanoMultisigPublicKeys> addressPubKeys = [];
  final List<_CardanoMultisigPublicKeys> stakePubKeys = [];
  ADAAddressType addressType = ADAAddressType.base;
  bool isBaseAddress = true;

  bool baseCredenticalIsReady = false;
  bool satkeCredenticalIsReady = false;
  bool isReady = false;

  bool allowImportBasePublicKey = false;
  bool allowImportStakePublicKey = false;
  bool _allowImportBasePublicKey() {
    if (addressCredentialType.isPublicKey) {
      return addressPubKeys.isEmpty;
    }
    if (addressPubKeys.length < maxThreshold) return true;
    return false;
  }

  void onChangeStakeCredentialType(CardanoCredentialType? type) {
    if (type == null) return;
    stakeCredentialType = type;
    if (stakeCredentialType == CardanoCredentialType.publicKey) {
      if (stakePubKeys.length > 1) {
        stakePubKeys.clear();
      }
      stakeWeight = null;
    }
    onStateUpdated();
  }

  void onChangeCredentialType(CardanoCredentialType? type) {
    if (type == null) return;
    addressCredentialType = type;
    if (addressCredentialType == CardanoCredentialType.publicKey) {
      if (addressPubKeys.length > 1) {
        addressPubKeys.clear();
      }
      addressWeight = null;
    }
    onStateUpdated();
  }

  bool _allowImportStakePublicKey() {
    if (addressType != ADAAddressType.base) return false;
    if (stakeCredentialType.isPublicKey) {
      return stakePubKeys.isEmpty;
    }
    if (stakePubKeys.length < maxThreshold) return true;
    return false;
  }

  bool _baseCredenticalIsReady() {
    if (addressCredentialType.isPublicKey) {
      return addressPubKeys.length == 1;
    }
    final threshold = addressWeight?.toBigInt().toInt();
    if (threshold == null) return false;
    if (addressPubKeys.length < threshold) return false;
    return true;
  }

  bool _stakeCredenticalIsReady() {
    if (addressType != ADAAddressType.base) return true;
    if (stakeCredentialType.isPublicKey) {
      return stakePubKeys.length == 1;
    }
    final threshold = stakeWeight?.toBigInt().toInt();
    if (threshold == null) return false;
    if (stakePubKeys.length < threshold) return false;
    return true;
  }

  String? _getError() {
    if (baseCredenticalIsReady && satkeCredenticalIsReady) {
      if (isBaseAddress) return null;
      final base = addressPubKeys.clone()..sort((k, v) => k.key.compareTo(v.key));
      final stake = stakePubKeys.clone()..sort((k, v) => k.key.compareTo(v.key));
      if (CompareUtils.iterableIsEqual(base, stake)) {
        return "ada_base_stake_key_same_error".tr;
      }
    }
    return null;
  }

  void onStateUpdated() {
    baseCredenticalIsReady = _baseCredenticalIsReady();
    satkeCredenticalIsReady = _stakeCredenticalIsReady();
    allowImportBasePublicKey = _allowImportBasePublicKey();
    allowImportStakePublicKey = _allowImportStakePublicKey();
    _error = _getError();
    isReady = _error == null && baseCredenticalIsReady && satkeCredenticalIsReady;
    notify();
  }

  void _cleanStakeState() {
    stakePubKeys.clear();
    stakeWeight = null;
  }

  void onChangeAddressType(ADAAddressType? addressType) {
    if (addressType == null) return;
    this.addressType = addressType;
    isBaseAddress = addressType == ADAAddressType.base;
    if (!isBaseAddress) _cleanStakeState();
    onStateUpdated();
  }

  bool isValidThreshold(BigRational weight) {
    if (weight.isDecimal ||
        weight.isNegative ||
        weight < BigRational.one ||
        weight > CardanoUtils.maxMultisigThreshold) {
      return false;
    }
    return true;
  }

  void onSetupAddressWeight(BigRational? weight) {
    if (weight == null) return;
    if (!isValidThreshold(weight)) return;
    addressWeight = weight;
    onStateUpdated();
  }

  void onSetupStakeWeight(BigRational? weight) {
    if (weight == null) return;
    if (!isValidThreshold(weight)) return;
    assert(addressType == ADAAddressType.base);
    stakeWeight = weight;
    onStateUpdated();
  }

  void onUpdateAddressPubKey(ICardanoAddress? address) {
    if (address == null) return;
    if (address.multiSigAccount) return;
    final key = _CardanoMultisigPublicKeys(
        key: CryptoKeyUtils.normalizePublicKeyHex(
            address.addressInfo.publicKeyHex!, address.coin.conf.type),
        address: address,
        keyIndex: address.derivationIndex);
    addressPubKeys.add(key);
    onStateUpdated();
  }

  void onGenerateAddressPubKey(PublicKeyDerivationWithMode? pubKeys) {
    if (pubKeys == null) return;
    if (pubKeys.derivation.key.curve != EllipticCurveTypes.ed25519Kholaw) {
      return;
    }
    final key = _CardanoMultisigPublicKeys(
        key: CryptoKeyUtils.normalizePublicKeyHex(
            pubKeys.derivation.viewKey.comprossed, pubKeys.derivation.key.curve),
        address: account.addresses.firstWhereOrNull((e) =>
            !e.multiSigAccount &&
            StringUtils.hexEqual(
                pubKeys.derivation.viewKey.comprossed, e.addressInfo.publicKeyHex!)),
        publicKey: pubKeys,
        keyIndex: pubKeys.derivation.index);
    addressPubKeys.add(key);
    onStateUpdated();
  }

  void onUpdateStakePubKey(ICardanoAddress? address) {
    if (address == null) return;
    if (address.multiSigAccount) return;
    final key = _CardanoMultisigPublicKeys(
        key: CryptoKeyUtils.normalizePublicKeyHex(
            address.addressInfo.publicKeyHex!, address.coin.conf.type),
        address: address,
        keyIndex: address.derivationIndex);
    stakePubKeys.add(key);
    onStateUpdated();
  }

  /// PublicKeyDerivationWithMode
  void onGenerateStakePubKey(PublicKeyDerivationWithMode? pubKeys) {
    if (pubKeys == null) return;
    if (pubKeys.derivation.key.curve != EllipticCurveTypes.ed25519Kholaw) {
      return;
    }

    final key = _CardanoMultisigPublicKeys(
        key: CryptoKeyUtils.normalizePublicKeyHex(
            pubKeys.derivation.viewKey.comprossed, pubKeys.derivation.key.curve),
        publicKey: pubKeys,
        address: account.addresses.firstWhereOrNull((e) =>
            !e.multiSigAccount &&
            StringUtils.hexEqual(
                pubKeys.derivation.viewKey.comprossed, e.addressInfo.publicKeyHex!)),
        keyIndex: pubKeys.derivation.index);
    stakePubKeys.add(key);
    onStateUpdated();
  }

  void onRemoveAddressPublicKey(_CardanoMultisigPublicKeys publicKey) {
    addressPubKeys.remove(publicKey);
    onStateUpdated();
  }

  void onRemoveStakePublicKey(_CardanoMultisigPublicKeys publicKey) {
    stakePubKeys.remove(publicKey);
    onStateUpdated();
  }

  void clearState() {
    generatedAddress = null;
    _error = null;
    addressWeight = null;
    stakeWeight = null;
    addressCredentialType = CardanoCredentialType.script;
    stakeCredentialType = CardanoCredentialType.script;
    addressPubKeys.clear();
    stakePubKeys.clear();
    addressType = ADAAddressType.base;
    onStateUpdated();
  }

  Future<void> importToAccount(WalletProvider wallet) async {
    final address = generatedAddress;
    final coin = account.network.coins.firstOrNull;
    if (address == null || coin == null) {
      return;
    }
    controller.progressText("setup_address".tr);
    final r = await IResult.call(() async {
      return CardanoMultisigNewAddressParams(
          addressInfo: address.multiSigAddresInfo,
          coin: account.network.coins.elementAt(0));
    }, delay: APPConst.oneSecoundDuration);
    if (r.isErr) {
      controller.errorText(r.unwrapErr().localizationError,
          showBackButton: true, backToIdle: false);
      return;
    }
    final import = await wallet.wallet.doAction(
        WalletActionDeriveNewAccount(newAccountParams: r.unwrap(), chain: account));
    if (import.isErr) {
      controller.errorText(import.unwrapErr().localizationError,
          showBackButton: true, backToIdle: false);
      return;
    }
    controller.success(
        backToIdle: false,
        progressWidget: SuccessWithButtonView(
          buttonWidget: ContainerWithBorder(
              margin: WidgetConstant.paddingVertical8,
              child: AddressDetailsView(address: import.unwrap())),
          buttonText: "generate_new_address".tr,
          onPressed: () {
            clearState();
            controller.backToIdle();
          },
        ));
  }

  Future<void> generateAddress() async {
    final stakeThreshold = stakeWeight?.toBigInt().toInt();
    final baseThreshold = addressWeight?.toBigInt().toInt();
    if (!isReady) return;
    controller.progressText("generating_new_addr".tr);
    final address = await IResult.call(() async {
      final List<CardanoMultiSigSignerDetails> signers = addressPubKeys
          .map((e) => CardanoMultiSigSignerDetails(
              publicKey: BytesUtils.fromHexString(e.key),
              derivationIndex: e.keyIndex.cast()))
          .toList();
      if (addressCredentialType.isScript && baseThreshold == null) {
        return null;
      }
      final credential = switch (addressCredentialType) {
        CardanoCredentialType.script =>
          CardanoMultiSignatureScript(threshold: baseThreshold!, signers: signers),
        CardanoCredentialType.publicKey => CardanoMultiSignatureKey(signer: signers.first)
      };
      BaseCardanoMultiSignatureCredential? stakeCredential;
      if (isBaseAddress) {
        if (stakeCredentialType.isScript && stakeThreshold == null) {
          return null;
        }
        final List<CardanoMultiSigSignerDetails> signers = stakePubKeys
            .map((e) => CardanoMultiSigSignerDetails(
                publicKey: BytesUtils.fromHexString(e.key),
                derivationIndex: e.keyIndex.cast()))
            .toList();
        stakeCredential = switch (stakeCredentialType) {
          CardanoCredentialType.script =>
            CardanoMultiSignatureScript(threshold: stakeThreshold!, signers: signers),
          CardanoCredentialType.publicKey =>
            CardanoMultiSignatureKey(signer: signers.first)
        };
      }
      final addressInfo = CardanoMultiSignatureAddressDetails(
          addressType: addressType,
          credential: credential,
          stakeCredential: stakeCredential);
      final address = addressInfo.toAddress(account.network.coinParam.networkType);
      final rewardAddress = address.addressType == ADAAddressType.base
          ? address.cast<ADABaseAddress>().stakeAddress()
          : null;
      return _CardanoGeneratedAddress(
          multiSigAddresInfo: addressInfo,
          rewardAddress: rewardAddress == null
              ? null
              : ReceiptAddress(view: rewardAddress.address, networkAddress: address),
          address: ReceiptAddress(view: address.address, networkAddress: address));
    }, delay: APPConst.oneSecoundDuration);
    if (address.isErr) {
      controller.errorText(address.unwrapErr().localizationError,
          backToIdle: false, showBackButton: true);
      return;
    }
    generatedAddress = address.unwrap();
    controller.backToIdle();
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }
}
