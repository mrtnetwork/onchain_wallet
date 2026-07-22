import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:on_chain/tron/tron.dart';
import 'package:on_chain_swap/on_chain_swap.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/networks/solidity/solidity.dart';
import 'package:on_chain_wallet/crypto/networks/tron/tron.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/tron/client/tron.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/networks/tron/models/account_delegated_resource_info.dart';
import 'package:on_chain_wallet/wallet/models/networks/tron/models/delegated_resouce_balance.dart';
import 'package:on_chain_wallet/wallet/models/networks/tron/models/tron_account_info.dart';

mixin TronTransactionApiController on DisposableMixin {
  final Map<TronAddress, bool> _accountActivities = {};
  final CachedObject<TronChainParameters> _chainParamets =
      CachedObject(interval: const Duration(minutes: 10));
  TronClient get client;

  Future<(MaxDelegatedResourceAmount, MaxDelegatedResourceAmount)>
      getMaxDelegatedEnergyAndBandwidth(ITronAddress address) async {
    return client.getMaxDelegatedEnergyAndBandwidth(address.networkAddress);
  }

  Future<TronChainParameters> getChainParameters() async {
    return _chainParamets.get(onFetch: () async => await client.getChainParameters());
  }

  Future<TronTransactionBlockRequirment> transactionBlockRequirment(
      {bool simulate = false, Duration? expiration}) async {
    if (simulate) {
      final BigInt timestamp = BigInt.from(DateTime.now().millisecondsSinceEpoch);
      return TronTransactionBlockRequirment(
          refBlockBytes: List<int>.filled(2, 0),
          refBlockHash: List<int>.filled(8, 0),
          expiration: timestamp,
          timestamp: timestamp);
    }
    final block = await client.getNowBlock();
    return TronTransactionBlockRequirment(
        refBlockBytes: block.blockHeader.rawData.refBlockBytes,
        refBlockHash: block.blockHeader.rawData.refBlockHash,
        expiration: BigInt.from(DateTime.now()
            .add(expiration ?? TronUtils.defaultTronTrasactionExpiration)
            .millisecondsSinceEpoch),
        timestamp: block.blockHeader.rawData.timestamp);
  }

  Future<bool> isAccountActive(TronAddress address) async {
    if (_accountActivities.containsKey(address)) {
      return _accountActivities[address]!;
    }
    final account = await client.getAccount(address);
    _accountActivities[address] = account != null;
    return _accountActivities[address]!;
  }

  Future<int> estimateContractTrigger(TriggerSmartContract contract) async {
    return await client.estimateContractEnergy(
        ownerAddress: contract.ownerAddress,
        contractAddress: contract.contractAddress,
        data: BytesUtils.toHexString(contract.data!),
        fragment: SolidityContractUtils.erc20Transfer);
  }

  bool checkAccountPermission(
      {required ITronAddress address,
      required TransactionContractType transactionType,
      required TronAccountInfo? account}) {
    if (account == null) return false;
    final List<AccountPermission> permissions = [
      account.ownerPermission,
      ...account.activePermissions
    ];
    if (address.multiSigAccount) {
      final msigAccount = address as ITronMultisigAddress;
      final int? permissionId = msigAccount.multiSignatureAccount.permissionID;
      BigInt sumOfThereshHold = BigInt.zero;
      final List<PermissionKeys> signers = msigAccount.multiSignatureAccount.signers
          .map((e) => PermissionKeys(
              address: TronAddress.fromPublicKey(BytesUtils.fromHexString(e.publicKey)),
              weight: e.weight))
          .toList();
      final findPermission =
          permissions.firstWhereOrNull((element) => element.id == permissionId);
      if (findPermission == null) return false;

      for (final i in findPermission.keys) {
        final findSigner = signers.firstWhereOrNull(
            (element) => element.address.toAddress() == i.address.toAddress());
        if (findSigner == null) continue;
        sumOfThereshHold = sumOfThereshHold + findSigner.weight;
      }
      if (sumOfThereshHold >= findPermission.threshold) {
        if (findPermission.operations == null) {
          return true;
        }
        final operations =
            TronHelper.decodePermissionOperation(findPermission.operations!);
        if (operations.contains(transactionType)) {
          return true;
        }
        return false;
      }
      return false;
    }
    final accountAccess = permissions.where((element) =>
        element.keys.map((e) => e.address.toAddress()).contains(account.address));
    for (final i in accountAccess) {
      final accKey = i.keys
          .firstWhereOrNull((element) => element.address.toAddress() == account.address);
      if (accKey == null) return false;
      if (accKey.weight == i.threshold) {
        if (i.type == PermissionType.owner) {
          return true;
        }
        final operations = TronHelper.decodePermissionOperation(i.operations!);
        if (operations.contains(transactionType)) {
          return true;
        }
      }
    }
    return false;
  }

  Future<DelegatedAccountResourceInfo> getDelegatedResourceInfo(
      TronAddress from, TronAddress to) async {
    final details = await client.getDelegatedResourceInfo(from, to);
    return details;
  }
}
