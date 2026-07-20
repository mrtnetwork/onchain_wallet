import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/account_state.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

abstract class BitcoinAccountState<W extends StatefulWidget> extends ChainAccountState<
    W,
    BitcoinNetworkAddress,
    TokenCore,
    NFTCore,
    WalletBitcoinNetwork,
    BitcoinWalletTransaction,
    IBitcoinAddress,
    BitcoinNetworkClient,
    BitcoinChain> {}
