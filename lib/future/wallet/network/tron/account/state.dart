import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain/on_chain.dart';

abstract class TronAccountState<W extends StatefulWidget> extends ChainAccountState<
    W,
    TronAddress,
    TronToken,
    NFTCore,
    WalletTronNetwork,
    TronWalletTransaction,
    ITronAddress,
    TronClient,
    TronChain> {}
