import 'package:blockchain_utils/bip/bip/conf/core/coins.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

class AddressDerivationController extends StateController {
  AddressDerivationController({required this.wallet, required this.chain});
  final Chain chain;
  final WalletProvider wallet;
  WalletNetwork get network => chain.network;
  final StreamPageProgressController pageProgressKey = StreamPageProgressController();
  final GlobalKey<FormState> form = GlobalKey<FormState>();
  List<CryptoCoins> get coins => network.coins;
  CryptoCoins get coin => coins.first;

  Future<DerivableIndex?> getCoin(
      {required BuildContext context,
      required SeedTypes seedGeneration,
      required CryptoCoins selectedCoins,
      ADDRESSDNEXTDERIVATION? nextAddressDerivationBuilder}) async {
    if (!form.ready()) return null;
    if (!coins.contains(selectedCoins)) {
      throw AppCryptoExceptionConst.invalidCoin;
    }
    return await context.openMaxExtendSliverBottomSheet<DerivableIndex>(
        "setup_derivation".tr,
        bodyBuilder: (controller) => SetupDerivationModeView(
            coin: selectedCoins,
            controller: controller,
            chainAccout: chain,
            seedGenerationType: seedGeneration,
            nextAddressDerivationBuilder: nextAddressDerivationBuilder));
  }

  Future<void> generateAddress(NewAccountParams newAccount) async {
    if (!form.ready()) return;
    pageProgressKey.progressText("generating_new_addr".tr);
    final result = await wallet.wallet.doAction(
        WalletActionDeriveNewAccount(newAccountParams: newAccount, chain: chain));
    if (result.isErr) {
      pageProgressKey.errorText(result.unwrapErr().localizationError);
    } else {
      pageProgressKey.success(
          backToIdle: false,
          progressWidget: SuccessWithButtonView(
              buttonText: "generate_new_address".tr,
              buttonWidget: ContainerWithBorder(
                  margin: WidgetConstant.paddingVertical8,
                  child: AddressDetailsView(
                    address: result.unwrap(),
                    chain: chain,
                  )),
              onPressed: () {
                pageProgressKey.backToIdle();
              },
              text: "address_added_success".tr));
    }
    notify();
  }

  @override
  void close() {
    super.close();
    pageProgressKey.dispose();
  }
}
