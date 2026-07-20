import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain/tron/tron.dart';

class TronAccountInfo with AppSerialization, Equality {
  final String? accountName;
  final String address;
  final BigInt balance;
  final BigInt createTime;
  final BigInt? latestOperationTime;
  final List<FrozenSupply> frozenSupply;
  final String? assetIssuedName;
  final int? freeNetUsage;
  final BigInt? latestConsumeFreeTime;
  final int netWindowSize;
  final bool netWindowOptimized;
  final TronAccountResource accountResource;
  final AccountPermission ownerPermission;

  final List<AccountPermission> activePermissions;
  final AccountPermission? witnessPermission;
  final List<FrozenV2> frozenV2;
  final List<UnfrozenV2> unfrozenV2;
  final List<AssetV2> assetV2;
  final String? assetIssuedID;
  final List<FreeAssetNetUsageV2> freeAssetNetUsageV2;
  final bool assetOptimized;

  List<AccountPermission> get permissions => [
        ownerPermission,
        ...activePermissions,
        if (witnessPermission != null) witnessPermission!
      ];

  factory TronAccountInfo.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.tronAccountInfo);

    final witness = cbor.objectAt<CborTagValue?>(14);
    return TronAccountInfo._(
        accountName: cbor.rawValueAt(0),
        address: cbor.rawValueAt(1),
        balance: cbor.rawValueAt(2),
        createTime: cbor.rawValueAt(3),
        latestOperationTime: cbor.rawValueAt(4),
        frozenSupply: cbor
            .listAt<CborObject>(5)
            .map((e) => FrozenSupply.deserialize(object: e))
            .toList(),
        assetIssuedName: cbor.rawValueAt(6),
        freeNetUsage: cbor.rawValueAt(7),
        latestConsumeFreeTime: cbor.rawValueAt(8),
        netWindowSize: cbor.rawValueAt(9),
        netWindowOptimized: cbor.rawValueAt(10),
        accountResource:
            TronAccountResource.deserialize(object: cbor.objectAt<CborTagValue>(11)),
        ownerPermission:
            AccountPermission.deserialize(object: cbor.objectAt<CborTagValue>(12)),
        activePermissions: cbor
            .listAt<CborObject>(13)
            .map((e) => AccountPermission.deserialize(object: e))
            .toList(),
        witnessPermission:
            witness == null ? null : AccountPermission.deserialize(object: witness),
        frozenV2: cbor
            .listAt<CborObject>(15)
            .map((e) => FrozenV2.deserialize(object: e))
            .toList(),
        unfrozenV2: cbor
            .listAt<CborObject>(16)
            .map((e) => UnfrozenV2.deserialize(object: e))
            .toList(),
        assetV2: cbor
            .listAt<CborObject>(17)
            .map((e) => AssetV2.deserialize(object: e))
            .toList(),
        assetIssuedID: cbor.rawValueAt(18),
        freeAssetNetUsageV2: cbor
            .listAt<CborObject>(19)
            .map((e) => FreeAssetNetUsageV2.deserialize(object: e))
            .toList(),
        assetOptimized: cbor.rawValueAt(20));
  }

  const TronAccountInfo._({
    this.accountName,
    required this.address,
    required this.balance,
    required this.createTime,
    required this.latestOperationTime,
    required this.frozenSupply,
    required this.assetIssuedName,
    required this.freeNetUsage,
    required this.latestConsumeFreeTime,
    required this.netWindowSize,
    required this.netWindowOptimized,
    required this.accountResource,
    required this.ownerPermission,
    required this.activePermissions,
    required this.witnessPermission,
    required this.frozenV2,
    required this.unfrozenV2,
    required this.assetV2,
    required this.assetIssuedID,
    required this.freeAssetNetUsageV2,
    required this.assetOptimized,
  });

  factory TronAccountInfo.fromJson(Map<String, dynamic> json) {
    return TronAccountInfo._(
      accountName: json['account_name'],
      address: json['address'],
      balance: BigintUtils.parse(json['balance'] ?? BigInt.zero),
      createTime: BigintUtils.parse(json['create_time']),
      latestOperationTime: BigintUtils.tryParse(json['latest_opration_time']),
      frozenSupply: (json['frozen_supply'] as List?)
              ?.map((supply) => FrozenSupply.fromJson(supply))
              .toList() ??
          <FrozenSupply>[],
      assetIssuedName: json['asset_issued_name'],
      freeNetUsage: json['free_net_usage'],
      latestConsumeFreeTime: BigintUtils.tryParse(json['latest_consume_free_time']),
      netWindowSize: json['net_window_size'],
      netWindowOptimized: json['net_window_optimized'],
      accountResource: TronAccountResource.fromJson(json['account_resource']),
      ownerPermission: json['owner_permission'] == null
          ? AccountPermission(
              type: PermissionType.owner,
              permissionName: "owner",
              threshold: BigInt.one,
              keys: [
                  PermissionKeys(
                      address: TronAddress(json['address']), weight: BigInt.one)
                ])
          : AccountPermission.fromJson(json['owner_permission']),
      activePermissions: (json['active_permission'] as List<dynamic>?)
              ?.map((permission) => AccountPermission.fromJson(permission))
              .toList() ??
          [
            AccountPermission(
                type: PermissionType.active,
                permissionName: "active",
                threshold: BigInt.one,
                keys: [
                  PermissionKeys(
                      address: TronAddress(json['address']), weight: BigInt.one)
                ])
          ],
      witnessPermission: json["witness_permission"] == null
          ? null
          : AccountPermission.fromJson(json['witness_permission']),
      frozenV2: (json['frozenV2'] as List<dynamic>)
          .map((frozen) => FrozenV2.fromJson(frozen))
          .toList(),
      unfrozenV2: (json['unfrozenV2'] as List?)
              ?.map((unfrozen) => UnfrozenV2.fromJson(unfrozen))
              .toList() ??
          <UnfrozenV2>[],
      assetV2:
          (json['assetV2'] as List?)?.map((asset) => AssetV2.fromJson(asset)).toList() ??
              <AssetV2>[],
      assetIssuedID: json['asset_issued_ID'],
      freeAssetNetUsageV2: (json['free_asset_net_usageV2'] as List?)
              ?.map((usage) => FreeAssetNetUsageV2.fromJson(usage))
              .toList() ??
          <FreeAssetNetUsageV2>[],
      assetOptimized: json['asset_optimized'],
    );
  }

  @override
  List get variables => [
        accountName,
        address,
        balance,
        createTime,
        latestOperationTime,
        frozenSupply,
        assetIssuedName,
        freeNetUsage,
        latestConsumeFreeTime,
        netWindowSize,
        netWindowOptimized,
        accountResource,
        ownerPermission,
        activePermissions,
        witnessPermission,
        frozenV2,
        unfrozenV2,
        assetV2,
        assetIssuedID,
        freeAssetNetUsageV2,
        assetOptimized
      ];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.tronAccountInfo;

  @override
  List<CborObject?> get serializationItems => [
        accountName?.toCbor(),
        address.toCbor(),
        balance.toCbor(),
        createTime.toCbor(),
        latestOperationTime?.toCbor(),
        AppSerialization.listFromObjects(frozenSupply.map((e) => e.toCbor()).toList()),
        assetIssuedName?.toCbor(),
        freeNetUsage?.toCbor(),
        latestConsumeFreeTime?.toCbor(),
        netWindowSize.toCbor(),
        netWindowOptimized.toCbor(),
        accountResource.toCbor(),
        ownerPermission.toCbor(),
        AppSerialization.listFromObjects(
            activePermissions.map((e) => e.toCbor()).toList()),
        witnessPermission?.toCbor(),
        AppSerialization.listFromObjects(frozenV2.map((e) => e.toCbor()).toList()),
        AppSerialization.listFromObjects(unfrozenV2.map((e) => e.toCbor()).toList()),
        AppSerialization.listFromObjects(assetV2.map((e) => e.toCbor()).toList()),
        assetIssuedID?.toCbor(),
        AppSerialization.listFromObjects(
            freeAssetNetUsageV2.map((e) => e.toCbor()).toList()),
        assetOptimized.toCbor()
      ];
}

class AccountPermission with AppSerialization, Equality {
  final PermissionType type;
  final int? id;
  final String? permissionName;
  final BigInt threshold;
  final String? operations;
  final List<PermissionKeys> keys;
  bool get isActivePermission => type == PermissionType.active;
  bool get isWitnessPermission => type == PermissionType.witness;
  bool get isOwner => type == PermissionType.owner;
  Permission toPermission() {
    return Permission(
        id: id,
        keys: keys.map((e) => TronKey(address: e.address, weight: e.weight)).toList(),
        operations: BytesUtils.tryFromHexString(operations),
        type: type,
        permissionName: permissionName,
        threshold: threshold);
  }

  AccountPermission clone() {
    return AccountPermission(
        type: type,
        permissionName: permissionName,
        threshold: threshold,
        id: id,
        operations: operations,
        keys: keys.map((e) => e.clone()).toList());
  }

  factory AccountPermission.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.accountPermission);
    final keys = cbor
        .listAt<CborObject>(5)
        .map((e) => PermissionKeys.deserialize(object: e))
        .toList();
    return AccountPermission(
        type: PermissionType.fromName(cbor.rawValueAt(0),
            defaultPermission: PermissionType.owner),
        id: cbor.rawValueAt(1),
        permissionName: cbor.rawValueAt(2),
        threshold: cbor.rawValueAt(3),
        operations: cbor.rawValueAt(4),
        keys: keys);
  }

  AccountPermission({
    required this.type,
    this.id,
    required this.permissionName,
    required this.threshold,
    this.operations,
    required this.keys,
  });

  factory AccountPermission.fromJson(Map<String, dynamic> json) {
    return AccountPermission(
      type:
          PermissionType.fromName(json["type"], defaultPermission: PermissionType.owner),
      id: json['id'],
      permissionName: json['permission_name'],
      threshold: BigintUtils.parse(json['threshold']),
      operations: json['operations'],
      keys: (json['keys'] as List?)?.map((e) => PermissionKeys.fromJson(e)).toList() ??
          <PermissionKeys>[],
    );
  }

  // CopyWith method for immutable updates
  AccountPermission copyWith({
    PermissionType? type,
    int? id,
    String? permissionName,
    BigInt? threshold,
    String? operations,
    List<PermissionKeys>? keys,
  }) {
    return AccountPermission(
      type: type ?? this.type,
      id: id ?? this.id,
      permissionName: permissionName ?? this.permissionName,
      threshold: threshold ?? this.threshold,
      operations: operations ?? this.operations,
      keys: keys ?? this.keys,
    );
  }

  @override
  List get variables => [type, id, permissionName, threshold, operations, keys];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.accountPermission;

  @override
  List<CborObject?> get serializationItems => [
        type.name.toCbor(),
        id?.toCbor(),
        permissionName?.toCbor(),
        threshold.toCbor(),
        operations?.toCbor(),
        AppSerialization.listFromObjects(keys.map((e) => e.toCbor()).toList())
      ];
}

class PermissionKeys with AppSerialization, Equality {
  PermissionKeys({required this.address, required this.weight});
  factory PermissionKeys.fromJson(Map<String, dynamic> json) {
    return PermissionKeys(
        address: TronAddress(json["address"]), weight: BigintUtils.parse(json["weight"]));
  }
  final TronAddress address;
  final BigInt weight;
  PermissionKeys clone() {
    return PermissionKeys(address: address, weight: weight);
  }

  factory PermissionKeys.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.permissionKeys);
    return PermissionKeys(
        address: TronAddress(cbor.rawValueAt(0)), weight: cbor.rawValueAt(1));
  }

  @override
  List get variables => [address, weight];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.permissionKeys;

  @override
  List<CborObject?> get serializationItems =>
      [address.toAddress().toCbor(), weight.toCbor()];
}

class FrozenSupply with AppSerialization, Equality {
  final BigInt frozenBalance;
  final BigInt expireTime;

  factory FrozenSupply.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.frozenSupply);
    return FrozenSupply._(
        frozenBalance: cbor.rawValueAt(0), expireTime: cbor.rawValueAt(1));
  }

  FrozenSupply._({
    required this.frozenBalance,
    required this.expireTime,
  });

  factory FrozenSupply.fromJson(Map<String, dynamic> json) {
    return FrozenSupply._(
      frozenBalance: BigInt.from(json['frozen_balance']),
      expireTime: BigInt.from(json['expire_time']),
    );
  }

  @override
  List get variables => [frozenBalance, expireTime];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.frozenSupply;

  @override
  List<CborObject?> get serializationItems =>
      [frozenBalance.toCbor(), expireTime.toCbor()];
}

class FrozenV2 with AppSerialization, Equality {
  final BigInt amount;
  final ResourceCode type;

  factory FrozenV2.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.assetFrozenV2);
    return FrozenV2._(
        type: ResourceCode.fromName(cbor.rawValueAt(1))!, amount: cbor.rawValueAt(0));
  }

  FrozenV2._({
    required this.amount,
    required this.type,
  });

  factory FrozenV2.fromJson(Map<String, dynamic> json) {
    return FrozenV2._(
      amount: BigintUtils.tryParse(json["amount"]) ?? BigInt.zero,
      type: ResourceCode.fromName(json['type'], orElse: ResourceCode.bandWidth)!,
    );
  }

  @override
  List get variables => [amount, type];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.assetFrozenV2;

  @override
  List<CborObject?> get serializationItems => [amount.toCbor(), type.name.toCbor()];
}

class UnfrozenV2 with AppSerialization, Equality {
  final String? type;
  final BigInt unfreezeAmount;
  final BigInt unfreezeExpireTime;

  factory UnfrozenV2.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.assetUnfreezV2);
    return UnfrozenV2._(
        type: cbor.rawValueAt(0),
        unfreezeAmount: cbor.rawValueAt(1),
        unfreezeExpireTime: cbor.rawValueAt(2));
  }

  UnfrozenV2._({
    required this.type,
    required this.unfreezeAmount,
    required this.unfreezeExpireTime,
  });

  factory UnfrozenV2.fromJson(Map<String, dynamic> json) {
    return UnfrozenV2._(
      type: json['type'],
      unfreezeAmount: BigintUtils.parse(json['unfreeze_amount']),
      unfreezeExpireTime: BigintUtils.parse(json['unfreeze_expire_time']),
    );
  }

  @override
  List get variables => [type, unfreezeAmount, unfreezeExpireTime];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.assetUnfreezV2;

  @override
  List<CborObject?> get serializationItems => [
        type?.toCbor(),
        unfreezeAmount.toCbor(),
        unfreezeExpireTime.toCbor(),
      ];
}

class AssetV2 with AppSerialization, Equality {
  final String key;
  final BigInt value;

  AssetV2._({required this.key, required this.value});

  factory AssetV2.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.assetVersion2);
    return AssetV2._(key: cbor.rawValueAt(0), value: cbor.rawValueAt(1));
  }

  factory AssetV2.fromJson(Map<String, dynamic> json) {
    return AssetV2._(key: json['key'], value: BigintUtils.parse(json["value"]));
  }

  @override
  List get variables => [key, value];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.assetVersion2;

  @override
  List<CborObject?> get serializationItems => [
        key.toCbor(),
        value.toCbor(),
      ];
}

class FreeAssetNetUsageV2 with AppSerialization, Equality {
  final String key;
  final BigInt value;

  FreeAssetNetUsageV2._({required this.key, required this.value});

  factory FreeAssetNetUsageV2.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.frozenAssetsNetUsage);
    return FreeAssetNetUsageV2._(key: cbor.rawValueAt(0), value: cbor.rawValueAt(1));
  }

  factory FreeAssetNetUsageV2.fromJson(Map<String, dynamic> json) {
    return FreeAssetNetUsageV2._(
      key: json['key'],
      value: BigintUtils.parse(json['value']),
    );
  }

  @override
  List get variables => [key, value];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.frozenAssetsNetUsage;

  @override
  List<CborObject?> get serializationItems => [
        key.toCbor(),
        value.toCbor(),
      ];
}

class TronAccountResource with AppSerialization, Equality {
  final int energyWindowSize;
  final BigInt? delegatedFrozenV2BalanceForEnergy;
  final bool energyWindowOptimized;

  TronAccountResource._(
      {required this.energyWindowSize,
      required this.delegatedFrozenV2BalanceForEnergy,
      required this.energyWindowOptimized});

  factory TronAccountResource.fromJson(Map<String, dynamic> json) {
    return TronAccountResource._(
      energyWindowSize: json['energy_window_size'],
      delegatedFrozenV2BalanceForEnergy:
          BigintUtils.tryParse(json['delegated_frozenV2_balance_for_energy']),
      energyWindowOptimized: json['energy_window_optimized'],
    );
  }

  @override
  String toString() {
    return '''
      TronAccountResource {
        energyWindowSize: $energyWindowSize,
        delegatedFrozenV2BalanceForEnergy: $delegatedFrozenV2BalanceForEnergy,
        energyWindowOptimized: $energyWindowOptimized
      }
    ''';
  }

  factory TronAccountResource.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.tronAccountResource);
    return TronAccountResource._(
        energyWindowSize: cbor.rawValueAt(0),
        delegatedFrozenV2BalanceForEnergy: cbor.rawValueAt(1),
        energyWindowOptimized: cbor.rawValueAt(2));
  }

  @override
  List get variables =>
      [energyWindowSize, delegatedFrozenV2BalanceForEnergy, energyWindowOptimized];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.tronAccountResource;

  @override
  List<CborObject?> get serializationItems => [
        energyWindowSize.toCbor(),
        delegatedFrozenV2BalanceForEnergy?.toCbor(),
        energyWindowOptimized.toCbor()
      ];
}

class TronAccountResourceInfo with AppSerialization, Equality {
  factory TronAccountResourceInfo.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue cbor = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.tronAccountResourceInfo);
    return TronAccountResourceInfo(
      freeNetUsed: cbor.rawValueAt(0),
      freeNetLimit: cbor.rawValueAt(1),
      netLimit: cbor.rawValueAt(2),
      netUsed: cbor.rawValueAt(3),
      energyLimit: cbor.rawValueAt(4),
      energyUsed: cbor.rawValueAt(5),
      tronPowerLimit: cbor.rawValueAt(6),
      tronPowerUsed: cbor.rawValueAt(7),
    );
  }

  final BigInt freeNetUsed;
  final BigInt freeNetLimit;
  final BigInt netLimit;
  final BigInt netUsed;
  final BigInt energyLimit;
  final BigInt energyUsed;

  final int tronPowerUsed;
  final int tronPowerLimit;
  late final BigInt totalBandWith;
  late final BigInt howManyEnergy;
  late final BigInt totalBandWithUsed;
  int get howManyVote => tronPowerLimit - tronPowerUsed;
  BigInt get howManyBandwIth => totalBandWith - totalBandWithUsed;

  /// {freeNetLimit: 600, assetNetUsed: [{key: 1001470, value: 0}], assetNetLimit: [{key: 1001470, value: 0}], TotalNetLimit: 43200000000, TotalNetWeight: 84045925899, TotalEnergyLimit: 50000000000000, TotalEnergyWeight: 564732458708}
  /// {freeNetUsed: 265, freeNetLimit: 600, assetNetUsed: [{key: 1001470, value: 0}], assetNetLimit: [{key: 1001470, value: 0}], TotalNetLimit: 43200000000, TotalNetWeight: 84045925899, TotalEnergyLimit: 50000000000000, TotalEnergyWeight: 564732458708}
  TronAccountResourceInfo({
    required this.freeNetUsed,
    required this.freeNetLimit,
    required this.netLimit,
    required this.netUsed,
    required this.energyLimit,
    required this.energyUsed,
    required this.tronPowerLimit,
    required this.tronPowerUsed,
  }) {
    totalBandWith = freeNetLimit + netLimit;
    totalBandWithUsed = netUsed + freeNetUsed;
    howManyEnergy = energyLimit - energyUsed;
    if (howManyEnergy < BigInt.zero) {
      howManyEnergy = BigInt.zero;
    }
  }

  factory TronAccountResourceInfo.empty() => TronAccountResourceInfo(
      freeNetUsed: BigInt.zero,
      freeNetLimit: BigInt.zero,
      netLimit: BigInt.zero,
      netUsed: BigInt.zero,
      energyLimit: BigInt.zero,
      energyUsed: BigInt.zero,
      tronPowerLimit: 0,
      tronPowerUsed: 0);

  factory TronAccountResourceInfo.fromJson(Map<String, dynamic> json) {
    return TronAccountResourceInfo(
      freeNetLimit: BigintUtils.tryParse(json["freeNetLimit"]) ?? BigInt.zero,
      freeNetUsed: BigintUtils.tryParse(json["freeNetUsed"]) ?? BigInt.zero,
      netLimit: BigintUtils.tryParse(json["NetLimit"]) ?? BigInt.zero,
      netUsed: BigintUtils.tryParse(json["NetUsed"]) ?? BigInt.zero,
      energyUsed: BigintUtils.tryParse(json["EnergyUsed"]) ?? BigInt.zero,
      energyLimit: BigintUtils.tryParse(json["EnergyLimit"]) ?? BigInt.zero,
      tronPowerUsed: json["tronPowerUsed"] ?? 0,
      tronPowerLimit: json["tronPowerLimit"] ?? 0,
    );
  }

  @override
  String toString() {
    return '''
      TronAccountResource {
        freeNetUsed: $freeNetUsed,
        freeNetLimit: $freeNetLimit,
        netLimit: $netLimit,
        netUsed: $netUsed,
        energyLimit: $energyLimit,
        energyUsed: $energyUsed,
        totalBandWith: $totalBandWith,
        totalBandWithUsed: $totalBandWithUsed,
        tronPowerUsed: $tronPowerUsed,
        tronPowerLimit: $tronPowerLimit,
        howManyVote: $howManyVote,
        howManyBandwIth: $howManyBandwIth,
        howManyEnergy: $howManyEnergy,
      }
    ''';
  }

  Map<String, dynamic> toJson() {
    return {
      "freeNetLimit": freeNetLimit,
      "freeNetUsed": freeNetUsed,
      "NetLimit": netLimit,
      "NetUsed": netUsed,
      "EnergyUsed": energyUsed,
      "EnergyLimit": energyLimit,
    };
  }

  @override
  List get variables => [
        freeNetUsed,
        freeNetLimit,
        netLimit,
        netUsed,
        energyLimit,
        energyUsed,
        tronPowerLimit,
        tronPowerUsed
      ];

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.tronAccountResourceInfo;

  @override
  List<CborObject?> get serializationItems => [
        freeNetUsed.toCbor(),
        freeNetLimit.toCbor(),
        netLimit.toCbor(),
        netUsed.toCbor(),
        energyLimit.toCbor(),
        energyUsed.toCbor(),
        tronPowerLimit.toCbor(),
        tronPowerUsed.toCbor(),
      ];
}

class TronAccountData {
  final TronAccountResourceInfo? resource;
  final TronAccountInfo? accountInfo;
  const TronAccountData({this.resource, this.accountInfo});
  BigInt get balance => accountInfo?.balance ?? BigInt.zero;
}
