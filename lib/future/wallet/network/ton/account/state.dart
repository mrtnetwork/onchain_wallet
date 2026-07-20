import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:ton_dart/ton_dart.dart';

abstract class TonAccountState<W extends StatefulWidget> extends ChainAccountState<
    W,
    TonAddress,
    TonJettonToken,
    NFTCore,
    WalletTonNetwork,
    TonWalletTransaction,
    ITonAddress,
    TonNetworkClient,
    TonChain> {}
