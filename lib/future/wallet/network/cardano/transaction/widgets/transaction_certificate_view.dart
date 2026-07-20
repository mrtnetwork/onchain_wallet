import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/transaction/types/types.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

class CardanoTransactionCertificateView extends StatefulWidget {
  final ADAChain account;
  const CardanoTransactionCertificateView(this.account, {super.key});

  @override
  State<CardanoTransactionCertificateView> createState() =>
      _CardanoTransactionCertificateViewState();
}

class _CardanoTransactionCertificateViewState
    extends State<CardanoTransactionCertificateView> with SafeState {
  ReceiptAddress<ADAAddress>? reward;
  ICardanoAddress? address;
  String? poolId;
  ADATransactionCertificateType type = ADATransactionCertificateType.registraction;

  bool isReady = false;

  void checkIsReady() {
    isReady = reward != null && address != null;
    if (type == ADATransactionCertificateType.delegation) {
      isReady &= poolId != null;
    }
    updateState();
  }

  void onChageCertificate(ADATransactionCertificateType? newCertificate) {
    type = newCertificate ?? type;
    checkIsReady();
  }

  String? onFilterAccount(ICardanoAddress address) {
    if (address.rewardAddress == null) {
      return "stake_address_validator".tr;
    }
    return null;
  }

  bool _validateRewardAccount(ICardanoAddress addr) {
    if (addr.rewardAddress == null) {
      context.showAlert("stake_address_validator".tr);
      return false;
    }
    return true;
  }

  void updateRewardAddress(ICardanoAddress? addr) {
    if (addr == null) return;
    if (_validateRewardAccount(addr)) {
      address = addr;
      reward = ReceiptAddress<ADAAddress>(
          view: addr.rewardAddress!.address,
          type: addr.rewardAddress!.addressType.name,
          networkAddress: addr.rewardAddress!,
          account: addr);
      checkIsReady();
    }
  }

  void onSetupPoolId(String? poolId) {
    if (poolId?.trim().length != CardanoConst.poolIDbech32Length) {
      this.poolId = null;
    } else {
      this.poolId = poolId;
    }
    checkIsReady();
  }

  String? validatePoolId(String? v) {
    if (v == null || v.trim().length != CardanoConst.poolIDbech32Length) {
      return "cardano_pool_id_validator".tr;
    }
    final poolid = MethodUtils.fallbackOnException(() => Ed25519PoolKeyHash.fromBech32(v),
        logOnDebug: false);
    if (poolid == null) return "cardano_pool_id_validator".tr;
    return null;
  }

  ADACertificateBuilder toCertificateBuilder() {
    final credential = reward!.networkAddress.cast<ADARewardAddress>().paymentCredential;
    switch (type) {
      case ADATransactionCertificateType.deregistration:
        return ADACertificateBuilder(
            certificate: StakeDeregistration(credential), signer: reward!.networkAddress);
      case ADATransactionCertificateType.registraction:
        return ADACertificateBuilder(certificate: StakeRegistration(credential));
      default:
        final poolid = Ed25519PoolKeyHash.fromBech32(poolId!);
        return ADACertificateBuilder(
            signer: reward!.networkAddress,
            certificate: StakeDelegation(
              stakeCredential: credential,
              poolKeyHash: poolid,
            ));
    }
  }

  ADATransactionCertificate toAdaTransactionCertificate() {
    return ADATransactionCertificate(
        certificate: toCertificateBuilder(),
        type: type,
        rewardAccount: ReceiptAddress(
            view: reward!.networkAddress.address,
            type: reward!.networkAddress.addressType.name,
            networkAddress: reward!.networkAddress,
            account: address));
  }

  void onSubmit() {
    if (!isReady) return;
    context.pop(toAdaTransactionCertificate());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("certificate_type".tr, style: context.textTheme.titleMedium),
        Text("add_certificate_to_transaction_desc".tr),
        WidgetConstant.height8,
        AppDropDownBottom(
          items: {
            for (final i in ADATransactionCertificateType.values) i: Text(i.viewName.tr)
          },
          hint: "certificate_type".tr,
          onChanged: onChageCertificate,
          value: type,
        ),
        WidgetConstant.height20,
        ReceiptAddressView(
          title: "stake_address".tr,
          onTap: () {
            context
                .selectOrSwitchAccount<ICardanoAddress>(
                    account: widget.account, showMultiSig: true, filter: onFilterAccount)
                .then(updateRewardAddress);
          },
          address: reward,
        ),
        APPAnimatedSwitcher(enable: type, widgets: {
          ADATransactionCertificateType.delegation: (context) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WidgetConstant.height20,
                Text("pool_id".tr, style: context.textTheme.titleMedium),
                Text("cardano_enter_pool_id_desc".tr),
                WidgetConstant.height8,
                ContainerWithBorder(
                    onRemoveIcon: Icon(
                      Icons.add_box,
                      color: context.onPrimaryContainer,
                    ),
                    validate: poolId != null,
                    onRemove: () {
                      context
                          .openSliverBottomSheet<String>(
                            "pool_id".tr,
                            child: StringWriterView(
                              customForm: validatePoolId,
                              title: PageTitleSubtitle(
                                  title: "pool_id".tr,
                                  body: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("cardano_enter_pool_id_desc".tr),
                                    ],
                                  )),
                              buttonText: "setup_pool_id".tr,
                              label: "pool_id".tr,
                            ),
                          )
                          .then(onSetupPoolId);
                    },
                    child: Text(
                      poolId ?? "tap_to_input_value".tr,
                      style: context.onPrimaryTextTheme.bodyMedium,
                    )),
              ],
            );
          }
        }),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FixedElevatedButton(
                padding: WidgetConstant.paddingVertical20,
                onPressed: isReady ? onSubmit : null,
                child: Text("setup_certificate".tr))
          ],
        )
      ],
    );
  }
}
