import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/wallet/global/pages/account_state.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain/aptos/src/address/address/address.dart';

abstract class AptosAccountState<W extends StatefulWidget> extends ChainAccountState<
    W,
    AptosAddress,
    AptosFATokens,
    NFTCore,
    WalletAptosNetwork,
    AptosWalletTransaction,
    IAptosAddress,
    AptosNetworkClient,
    AptosChain> {}
