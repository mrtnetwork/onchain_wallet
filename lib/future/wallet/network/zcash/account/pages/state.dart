import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/account_state.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:zcash_dart/zcash.dart';

abstract class ZcashAccountState<W extends StatefulWidget> extends ChainAccountState<
    W,
    ZcashAddress,
    TokenCore,
    NFTCore,
    WalletZcashNetwork,
    ZcashWalletTransaction,
    IZcashAddress,
    ZcashNetworkClient,
    ZcashChain> {}
