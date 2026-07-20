import 'package:flutter/material.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/account_state.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

abstract class MoneroAccountState<W extends StatefulWidget> extends ChainAccountState<
    W,
    MoneroAddress,
    TokenCore,
    NFTCore,
    WalletMoneroNetwork,
    MoneroWalletTransaction,
    IMoneroAddress,
    MoneroNetworkClient,
    MoneroChain> {}
