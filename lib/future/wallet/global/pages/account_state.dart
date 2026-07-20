import 'package:blockchain_utils/networks/types/address.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

abstract class ChainAccountState<
    W extends StatefulWidget,
    NETWORKADDRESS extends IAddress,
    T extends TokenCore,
    N extends NFTCore,
    NETWORK extends WalletNetwork,
    TRANSACTION extends ChainTransaction,
    ADDRESS extends ChainAccount<NETWORKADDRESS, T, N, TRANSACTION, NETWORK>,
    CL extends NetworkClient<TRANSACTION, BaseNetworkToken, NETWORKADDRESS, NETWORK>,
    CHAIN extends Chain<
        NETWORKADDRESS,
        T,
        N,
        NETWORK,
        TRANSACTION,
        ADDRESS,
        CL,
        NetworkApiProvider<NETWORK, CL>,
        IChainContext<NETWORKADDRESS, T, N, NETWORK, TRANSACTION, ADDRESS, CL,
            NetworkApiProvider<NETWORK, CL>>>> extends State<W> with SafeState<W> {
  CHAIN get account;
  ADDRESS get address => account.addressSync;
  List<ADDRESS> get addresses => account.addresses;
  CL? get client => null;
  NETWORK get network => account.network;
}
