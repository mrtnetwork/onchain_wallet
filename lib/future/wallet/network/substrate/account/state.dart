import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/account_state.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:polkadot_dart/polkadot_dart.dart';

abstract class SubstrateAccountState<W extends StatefulWidget> extends ChainAccountState<
    W,
    BaseSubstrateAddress,
    TokenCore,
    NFTCore,
    WalletSubstrateNetwork,
    SubstrateWalletTransaction,
    ISubstrateAddress,
    SubstrateNetworkClient,
    SubstrateChain> {}
