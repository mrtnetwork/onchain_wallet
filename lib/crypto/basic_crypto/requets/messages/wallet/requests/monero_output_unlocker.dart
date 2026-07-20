import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/types.dart';
import 'package:on_chain_wallet/crypto/crypto_libs/core/app_crypto.dart';
import 'package:on_chain_wallet/crypto/wallet/keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';

final class WalletRequestMoneroOutputUnlocker
    extends WalletRequest<MoneroAccountTxTrackerResponse> {
  final List<String> txIds;
  final DefaultAPIProvider provider;
  final List<MoneroSyncAccount> accounts;

  WalletRequestMoneroOutputUnlocker(
      {required List<String> txIds,
      required List<MoneroSyncAccount> accounts,
      required this.provider})
      : txIds = txIds.map((e) => StringUtils.normalizeHex(e)).toImutableList,
        accounts = accounts.immutable;

  factory WalletRequestMoneroOutputUnlocker.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletRequestMethod.moneroOutputUnlocker.tag);
    return WalletRequestMoneroOutputUnlocker(
      txIds: values.listAt<CborStringValue>(0).map((e) => e.value).toList(),
      provider: DefaultAPIProvider.deserialize(object: values.objectAt<CborTagValue>(1)),
      accounts: values
          .listAt<CborTagValue>(2)
          .map((e) => MoneroSyncAccount.deserialize(object: e))
          .toList(),
    );
  }

  @override
  WalletRequestMethod get method => WalletRequestMethod.moneroOutputUnlocker;

  @override
  List<CborObject?> get serializationItems => [
        AppSerialization.listFromObjects(txIds.map((e) => CborStringValue(e)).toList()),
        provider.toCbor(),
        AppSerialization.listFromObjects(accounts.map((e) => e.toCbor()).toList()),
      ];

  @override
  Future<MoneroAccountTxTrackerResponse> parsResult(MessageArgsComplete result) async {
    return MoneroAccountTxTrackerResponse.deserialize(object: result.result);
  }

  IResult<MoneroUtxo?> unlockUtxo({
    required MoneroLockedOutput lockedOutput,
    required String txId,
    required int blockHeight,
    required BigInt globalIndex,
    required DerivableIndex masterIndex,
    required MoneroSyncAccount syncAccount,
    required MemoryWalletContext wallet,
  }) {
    try {
      final key = wallet
          .readSecretKeys([masterIndex])
          .get(masterIndex)
          .cast<MoneroPrivateKeyData>();
      final output = MoneroTransactionHelper.toUnlockOutput(
          out: lockedOutput,
          account: MoneroAccountKeys(
              account: key.toMoneroAccount(),
              network: MoneroNetwork.mainnet,
              indexes: syncAccount.accounts.map((e) => e.index).toList()));
      if (output == null) return ResultOk(null);
      return ResultOk(MoneroUtxo(
          globalIndex: globalIndex,
          output: output,
          txId: txId,
          blockHeight: blockHeight));
    } catch (e, trace) {
      return ResultErr.from(e, trace: trace);
    }
  }

  @override
  Future<MoneroAccountTxTrackerResponse> result(
      MemoryWalletContext wallet, AppContext context) async {
    final List<MoneroAccountTxTrackerStatus> status = [];
    final client = MoneroClient.fromProviders(provider: provider, netApi: context.netApi);
    Map<MoneroAccountKeys, MoneroSyncAccount> accountTxes =
        Map.fromEntries(accounts.map((e) => MapEntry(e.getAccountKeys(), e)));
    final accountsKeys = accountTxes.keys.toList();
    final crypto = AppCryptoLibs.instance();
    final monero = (await crypto.moneroCrypto(context, accountsKeys)).unwrap();
    final txes = await client.getTxes(txIds: txIds);
    Map<(MoneroTransaction, String, int), List<MoneroUnlockedOutputWithAccountKey>>
        findOutputs = {};
    for (final i in txes.entries) {
      switch (i.value) {
        case MoneroTxResponse txResponse:
          final outoutIndices = txResponse.outoutIndices;
          final height = txResponse.height;
          final transaction = txResponse.toTx();
          if (outoutIndices == null ||
              height == null ||
              transaction.vout.length != outoutIndices.length) {
            status.add(MoneroAccountTxTrackerNotFound(txId: i.key, inMempool: true));
            break;
          }
          final outputs = monero.moneroUnlockOutput(
              transaction: transaction, txHash: i.key, outputIndices: outoutIndices);
          if (outputs.isEmpty) {
            status.add(MoneroAccountTxTrackerNotFound(txId: i.key, noAccountUtxos: true));
            break;
          }
          findOutputs[(transaction, i.key, height)] = outputs;
          break;
        case null:
          status.add(MoneroAccountTxTrackerNotFound(txId: i.key));
          break;
      }
    }

    Map<MoneroSyncAccount, List<MoneroUtxo>> unlockedUtxos = {};

    for (final txOutputs in findOutputs.entries) {
      bool isOk = false;
      for (final output in txOutputs.value) {
        final syncAccount = accountTxes[output.account];
        assert(syncAccount != null, "Unexcpected unlock output response");
        if (syncAccount == null) continue;
        final unlock = unlockUtxo(
            lockedOutput: output.output,
            txId: txOutputs.key.$2,
            blockHeight: txOutputs.key.$3,
            globalIndex: output.globalIndex,
            masterIndex: syncAccount.derivationKey.index,
            syncAccount: syncAccount,
            wallet: wallet);
        assert(!unlock.isErr,
            "Unexcpected unlock output response. ${unlock.err()?.exception}");
        final unlockedOutput = unlock.ok();
        if (unlockedOutput == null) continue;
        isOk = true;
        final accountUtxos = unlockedUtxos[syncAccount] ??= [];
        accountUtxos.add(unlockedOutput);
      }
      if (!isOk) {
        status
            .add(MoneroAccountTxTrackerNotFound(txId: txOutputs.key.$2, hasError: true));
      }
    }
    final height = await client.getHeight();
    List<TxKeyImage> keyImages = unlockedUtxos.values
        .expand((e) => e.map((e) => e.output.keyImage).toList())
        .toList();
    if (keyImages.isNotEmpty) {
      keyImages = await client.getSpendedKeyImages(keyImages);
    }
    for (final i in unlockedUtxos.entries) {
      for (final unlockOutput in i.value) {
        if (keyImages.contains(unlockOutput.output.keyImage)) {
          status.add(MoneroAccountTxTrackerSpended(
              txId: unlockOutput.txId, keyImage: unlockOutput.output.keyImage));
        } else {
          final account = i.key.getUtxoAccount(unlockOutput);
          assert(account != null, "Utxo account not found!");
          if (account == null) continue;

          status.add(MoneroAccountTxTrackerUtxo(
              txId: unlockOutput.txId, utxo: unlockOutput, index: account));
        }
      }
    }
    return MoneroAccountTxTrackerResponse(txes: status, height: height);
  }

  @override
  Duration get processTimeout => Duration(seconds: txIds.length * 40);

  @override
  CryptoProcessLevel get level =>
      txIds.length > 3 ? CryptoProcessLevel.high : CryptoProcessLevel.normal;
}
