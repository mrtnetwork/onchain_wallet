import 'package:flutter/material.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/wallet/requests/typed_data.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/web3/pages/typed_data.dart';
import 'package:on_chain_wallet/future/wallet/network/ethereum/web3/types/types.dart';
import 'package:on_chain_wallet/future/wallet/web3/core/state.dart';
import 'package:on_chain_wallet/wallet/api/api.dart';
import 'package:on_chain_wallet/wallet/controller/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/networks/ethereum/params/models/sign_typed_data.dart';

class Web3EthereumSignTypedDataStateController extends Web3EthereumStateController<String,
    EthereumNetworkClient?, Web3EthreumTypdedData> {
  Web3EthereumSignTypedDataStateController(
      {required super.walletProvider, required super.request});

  @override
  Future<Web3RequestResponseData<String>> getResponse() async {
    final account = defaultAccount;
    final sign = await walletProvider.wallet.doAction(WalletActionWalletRequest(
        request: WalletRequestEthereumTypedDataSign(
      message: params.typedData,
      index: account.derivationIndex.cast(),
    )));
    return Web3RequestResponseData(response: sign.unwrap().signatureHex);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return Web3EthereumSignTypedDataStateView(controller: this);
  }
}
