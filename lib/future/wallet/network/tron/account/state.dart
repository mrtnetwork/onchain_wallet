import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain/on_chain.dart';

abstract class TronAccountState<W extends StatefulWidget>
    extends ChainAccountState<W, TronAPIProvider, TronAddress, TronToken,
        NFTCore, ITronAddress, TronClient, TronChain, TronWalletTransaction> {}
