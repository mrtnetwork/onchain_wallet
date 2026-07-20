import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/networks/ton/ton.dart';
import 'package:ton_dart/ton_dart.dart';

mixin TonWeb3TransactionApiController on DisposableMixin {
  TonNetworkClient get client;

  Future<TonWeb3TransactionMessageInfo> getWeb3TransactionMessageInfo(
      {required ITonAddress address,
      required TonChain account,
      required Web3TonTransactionMessage message}) async {
    final destination =
        account.getOrCreateReceiptFromNetworkAddressSync(address: message.address);
    final StateInit? init = message.stateInit == null
        ? null
        : StateInit.deserialize(message.stateInit!.beginParse());
    if (message.payload == null) {
      return TonWeb3TransactionMessageInfo(
          amount: message.amount,
          destination: destination,
          initState: init,
          network: account.network);
    }
    final info = TonWeb3TransactionPayload.fromPayload(
        payload: message.payload!,
        destination: message.address,
        chainId: address.network.coinParam.chainId);
    switch (info.type) {
      case TonWeb3TransactionPayloadType.transfer:
      case TonWeb3TransactionPayloadType.jetton:
        break;
      default:
        return TonWeb3TransactionMessageInfo(
            amount: message.amount,
            destination: destination,
            payload: info,
            initState: init,
            network: account.network);
    }

    final jettonInfo = await IResult.call(() async {
      final tokenInfo = await client.getJettonWalletData(message.address);
      final tokens = (await address.getAccountTokens()).unwrap();
      TonJettonToken? jetton =
          tokens.firstWhereOrNull((e) => e.walletAddress == message.address);

      bool? isAccountJetton = jetton == null ? null : true;
      if (jetton == null) {
        final balance = await IResult.call(
            () async => await client.getJettonBalance(message.address));
        jetton = await client.getJettonInfo(TonAccountJettonResponse(
            tokenAddress: tokenInfo.minterAddress,
            balance: balance.ok() ?? BigInt.zero,
            owner: address.networkAddress,
            jettonWalletAddress: message.address));
        final jettonWalletAddress = await IResult.call(() async =>
            await client.getJettonWalletAddress(
                minterAddress: jetton!.minterAddress, owner: address.networkAddress));
        if (jettonWalletAddress.ok() == message.address) {
          isAccountJetton = true;
        }
      }
      // updateJettonBalance(jetton);
      return (jetton, isAccountJetton);
    });
    if (jettonInfo.isErr) {
      return TonWeb3TransactionMessageInfo(
          amount: message.amount,
          destination: destination,
          initState: init,
          payload: info,
          network: account.network);
    }
    final contractInfo = info as ContractTonTransactionPayload;
    BigInt? transfer;
    if (info.type == TonWeb3TransactionPayloadType.transfer) {
      transfer = info.jettonAmount;
    }
    final TonWeb3TransactionPayload payload = JettonContractTonTransactionPayload(
        payload: info.payload,
        content: contractInfo.contentJson,
        token: jettonInfo.unwrap().$1,
        isAccountJetton: jettonInfo.unwrap().$2,
        transferAmount: transfer,
        type: transfer != null
            ? TonWeb3TransactionPayloadType.transfer
            : TonWeb3TransactionPayloadType.jetton,
        operation: info.operation,
        tonAmount: info.tonAmount);
    return TonWeb3TransactionMessageInfo(
        amount: message.amount,
        destination: destination,
        initState: init,
        payload: payload,
        network: account.network);
  }
}
