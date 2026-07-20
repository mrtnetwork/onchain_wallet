import 'dart:async';
import 'package:on_chain_wallet/app/core.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/wallet_signing_password.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

abstract class UIWallet extends AppWalletController {
  UIWallet({required this.navigatorKey, required MainAppContext context}) {
    config = WalletConfigDefault(uiAction: onWalletUiAction, context: context);
  }
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  late final WalletConfigDefault config;

  Future<IResult<WalletCredentialResponseVerify>> _getPassword(
      {required Set<DerivableIndex> keys, required Set<ChainAccount> addresses}) async {
    final pw = await navigatorKey.currentContext
        ?.openSliverBottomSheet<WalletCredentialResponseVerify>("sign_transaction".tr,
            initiaalExtend: 1,
            bodyBuilder: (controller) => WalletSigningPassword(
                addresses: addresses, keys: keys, controller: controller));
    if (pw == null) {
      return ResultErr.fromException(WalletExceptionConst.rejectSigning);
    }
    return ResultOk(pw);
  }

  Future<IResult<T>> signTransaction<T>({
    required WalletActionSign<T> params,
  }) async {
    late final Set<ChainAccount> addresses = params.request.addresses.toSet();
    late final Set<DerivableIndex> keys = addresses
        .map((e) => e.derivableIndexes(
            request: params.derivationRequest ?? AccountDerivationIndexRequestSigners()))
        .expand((e) => e)
        .toSet();
    if (wallet.protectWallet || !isUnlock) {
      final credential = await _getPassword(addresses: addresses, keys: keys);
      return credential.andThenAsync((credential) async {
        return await super.doAction<T>(params.copyWith(credential: credential));
      });
    }
    return await super.doAction<T>(params);
  }

  Future<IResult<T>> onWalletUiAction<T extends Object?>(
      WalletUiAction<T> request) async {
    final context = navigatorKey.currentContext;
    assert(context != null, "Missing navigator context");
    if (context == null || !context.mounted) {
      return ResultErr.fromException(AppExceptionConst.walletContextNotAvailable);
    }
    return context.wallet.onWalletUiAction<T>(request);
  }

  Future<IResult<void>> init() async {
    return await doAction(WalletActionInit());
  }

  // void dispose() {}
}
