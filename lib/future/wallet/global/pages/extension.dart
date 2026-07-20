import 'package:blockchain_utils/networks/types/address.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/select_account.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/setup_amount.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/others/others.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';

import 'select_or_write_address.dart';

extension ExtQuicWalletPageAccess on BuildContext {
  Future<CHAINACCOUNT?> selectOrSwitchAccount<CHAINACCOUNT extends ChainAccount>({
    required APPCHAINACCOUNT<CHAINACCOUNT> account,
    bool isSwitch = false,
    required bool showMultiSig,
    OnSelectAccountFilter<CHAINACCOUNT>? filter,
    List<CHAINACCOUNT>? defaultAddresses,
  }) async {
    assert(defaultAddresses == null || !isSwitch);
    return openDialogPage<CHAINACCOUNT>(
      "switch_account".tr,
      child: (context) => SwitchOrSelectAccountView<CHAINACCOUNT>(
          account: account,
          showMultiSig: showMultiSig,
          isSwitch: isSwitch,
          defaultAddresses: defaultAddresses,
          filter: filter),
    );
  }

  Future<List<ReceiptAddress<NETWORKADDRESS>>?>
      selectAccount<NETWORKADDRESS extends IAddress>({
    required APPCHAINADDRESS<NETWORKADDRESS> account,
    final String? title,
    bool multipleSelect = false,
    final RECIPIENTFILTER<NETWORKADDRESS>? onFilterAccount,
  }) {
    return openSliverBottomSheet(
      "",
      initiaalExtend: (account.addresses.length > 2) ? 1 : 0.9,
      bodyBuilder: (c) => SelectOrWriteAddressView<NETWORKADDRESS>(
          account: account,
          scrollController: c,
          onFilterAccount: onFilterAccount,
          title: title,
          multipleSelect: multipleSelect),
    );
  }

  Future<List<ReceiptAddress<NETWORKADDRESS>>?>
      selectAccountNew<NETWORKADDRESS extends IAddress>({
    required APPCHAINADDRESS<NETWORKADDRESS> account,
    final String? title,
    bool multipleSelect = false,
    final RECIPIENTFILTER<NETWORKADDRESS>? onFilterAccount,
  }) {
    return openSliverBottomSheet(
      "",
      initiaalExtend: (account.addresses.length > 2) ? 1 : 0.9,
      bodyBuilder: (c) => SelectOrWriteAddressView<NETWORKADDRESS>(
          account: account,
          scrollController: c,
          onFilterAccount: onFilterAccount,
          title: title,
          multipleSelect: multipleSelect),
    );
  }

  Future<BigInt?> setupAmount(
      {required Token token, BigInt? max, BigInt? min, String? title}) {
    assert(min == null || min >= BigInt.zero, "negative not allowed for min amount.");
    return openSliverBottomSheet<BigInt>(title ?? 'setup_amount'.tr,
        child: SetupNetworkAmount(token: token, max: max, min: min ?? BigInt.zero),
        initiaalExtend: 0.9);
  }
}
