import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/account_state.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain/sui/src/src.dart';

abstract class SuiAccountState<W extends StatefulWidget> extends ChainAccountState<
    W,
    SuiAddress,
    TokenCore,
    NFTCore,
    WalletSuiNetwork,
    SuiWalletTransaction,
    ISuiAddress,
    SuiNetworkClient,
    SuiChain> {}
