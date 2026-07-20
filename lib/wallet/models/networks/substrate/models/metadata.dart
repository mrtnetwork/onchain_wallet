import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/dev/src/logger.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:polkadot_dart/polkadot_dart.dart';

class _SubstrateChainConst {
  static const List<BaseSubstrateNetwork> allowedLocalTransfer = [
    PolkadotNetwork.moonbeam,
    KusamaNetwork.moonriver
  ];
  static const List<int> supportedExtrinsicVersions = [4, 5];
  static int ss58Prefix({required MetadataApi metadata}) {
    final prefix = metadata.getConstant<int?>("System", "SS58Prefix");
    return prefix ?? 0;
  }

  static bool supportAccountTemplate({required MetadataApi metadata}) {
    try {
      final StorageEntryMetadataV14 storage =
          metadata.metadata.getStorageMethod("System", "account");
      final decode = metadata.decodeLookup(storage.type.outputTypeId, storage.fallback);
      SubstrateDefaultAccount.deserializeJson(decode);
      return true;
    } catch (_) {}

    return false;
  }

  static bool supportRemark({required MetadataApi metadata}) {
    try {
      metadata.encodeCall(
          palletNameOrIndex: "System",
          value: {
            APPSubstrateConst.systemRemarkVariantName: [0x00]
          },
          fromTemplate: false);
      return true;
    } catch (_) {
      return false;
    }
  }

  static SubstrateDefaultTransfer createFakeTx(SubstrateNetworkCryptoInfo cryptoInfo) {
    if (cryptoInfo.addressPalletType.isEthereum) {
      return SubstrateDefaultTransfer(
          address: SubstrateEthereumAddress('0x0000000000000000000000000000000000000000'),
          value: BigInt.zero);
    }
    return SubstrateDefaultTransfer(
        address: SubstrateAddress('5C4hrfjw9DjXZTzV3MwzrrAr9P1MJhSrvWGWqi1eSuyUpnhM'),
        value: BigInt.zero);
  }

  static List<BalancesCallPalletMethod> transferTypes(
      {required MetadataApi metadata, required SubstrateNetworkCryptoInfo cryptoInfo}) {
    SubstrateDefaultTransfer transfer = createFakeTx(cryptoInfo);
    return [
      BalancesCallPalletMethod.transferKeepAlive,
      BalancesCallPalletMethod.transferKeepAlive
    ]
        .map((e) {
          try {
            transfer.encode(
                metadata: metadata, method: e, addressType: cryptoInfo.addressPalletType);
            return e;
          } catch (_) {
            return null;
          }
        })
        .whereType<BalancesCallPalletMethod>()
        .toList();
  }
}

class SubstrateChainMetadata {
  final int batchedCallsLimit;
  final MetadataApi metadata;
  final ExtrinsicLookupField extrinsic;
  final String genesis;
  final MetadataInfo metadataInfos;
  final RuntimeVersion runtimeVersion;
  final List<SubstrateCallPalletTransferMethod> nativeTransferMethods;
  final bool supportAccountTemplate;
  final int ss58Prefix;
  final bool supportRemarks;
  final bool supportBatch;
  final BigInt? existentialDeposit;
  final BigInt? baseDeposit;
  final int? maxSignatories;
  final BigInt? depositFactor;
  final bool supportMultisig;
  final bool supportPokeDeposit;
  final bool supportTransferLocalToken;
  final XCMVersion xcmVersion;
  final BaseSubstrateNetworkController? controller;
  bool get supportXcmTransfer => controller != null;
  bool get supportTokenTransfer => controller != null;
  final BaseSubstrateNetwork? internalNetwork;
  final bool hasCurrencyConvertionApi;
  final bool hasXcmPaymentApi;
  final bool hasDryRunApi;
  final List<String> rpcMethods;
  XCMVersionedLocation? chargeAssetTxPaymentNativeLocation() {
    if (controller != null &&
        extrinsic.chargeAssetTxPayment &&
        hasCurrencyConvertionApi) {
      return controller?.defaultNativeAsset.tryGetlocalizedLocation(
          reserveNetwork: controller!.network,
          version: controller!.network.defaultXcmVersion);
    }
    return null;
  }

  MetadataWithExtrinsic metadataWithExtrinsic() {
    return MetadataWithExtrinsic(api: metadata, extrinsic: extrinsic);
  }

  List<MultisigCallPalletMethod> multisigMethods() {
    if (!supportMultisig) return [];
    if (supportPokeDeposit) return MultisigCallPalletMethod.values;
    return MultisigCallPalletMethod.values
        .where((e) => e != MultisigCallPalletMethod.pokeDeposit)
        .toList();
  }

  // final
  bool get supportNativeTransfer => nativeTransferMethods.isNotEmpty;
  int get transactionVersion => runtimeVersion.transactionVersion;
  int get specVersion => runtimeVersion.specVersion;
  bool get supportRuntimeApi => metadata.metadata.supportRuntimeApi;

  List<int> genesisBytes() {
    return BytesUtils.fromHexString(genesis);
  }

  SubstrateChainMetadata._(
      {required this.metadataInfos,
      required this.batchedCallsLimit,
      required this.genesis,
      required this.metadata,
      required this.runtimeVersion,
      required this.extrinsic,
      required this.baseDeposit,
      required this.depositFactor,
      required this.maxSignatories,
      required this.nativeTransferMethods,
      required this.supportAccountTemplate,
      required this.ss58Prefix,
      required this.supportMultisig,
      required this.supportBatch,
      required this.supportRemarks,
      required this.controller,
      required this.internalNetwork,
      required this.hasCurrencyConvertionApi,
      required this.hasXcmPaymentApi,
      required this.hasDryRunApi,
      required this.supportPokeDeposit,
      required this.xcmVersion,
      required this.supportTransferLocalToken,
      required List<String> rpcMethods,
      this.existentialDeposit})
      : rpcMethods = rpcMethods.immutable;
  factory SubstrateChainMetadata(
      {required String genesis,
      required MetadataApi metadata,
      required SubstrateNetworkControllerParams apiParams,
      required List<String> rpcMethods}) {
    final substrateNetwork = BaseSubstrateNetwork.fromGenesis(genesis);
    BaseSubstrateNetworkController? controller;
    if (substrateNetwork != null) {
      controller = MethodUtils.fallbackOnException(
          () => SubstrateNetworkControllerFinder.buildApi(
              network: substrateNetwork, params: apiParams),
          logOnDebug: false);
    }
    final existentialDeposit = BigintUtils.tryParse(metadata.tryGetConstant(
        SubtrateMetadataPallet.balances.name,
        APPSubstrateConst.existentialDepositStorageName));
    final depositBase = BigintUtils.tryParse(metadata.tryGetConstant(
        SubtrateMetadataPallet.multisig.name, APPSubstrateConst.depositBase));
    final depositFactor = BigintUtils.tryParse(metadata.tryGetConstant(
        SubtrateMetadataPallet.multisig.name, APPSubstrateConst.depositFactor));
    final maxSignatories = IntUtils.tryParse(metadata.tryGetConstant(
        SubtrateMetadataPallet.multisig.name, APPSubstrateConst.maxSignatories));
    final int? batchedCallsLimit = IntUtils.tryParse(metadata.tryGetConstant(
        SubtrateMetadataPallet.utility.name, APPSubstrateConst.batchedCallsLimit));
    final metadataInfos = metadata.metadata.palletsInfos();
    final metadataExtrinsic = metadataInfos.extrinsic.firstWhere(
        (e) =>
            _SubstrateChainConst.supportedExtrinsicVersions.contains(e.version) &&
            e.addressType != null &&
            e.signatureType != null,
        orElse: () => throw WalletException.message('unsuported_network_metadata'));
    final extrinsic = MethodUtils.fallbackOnException(
      () => ExtrinsicBuilderUtils.buildExtrinsicFields(metadata, metadataExtrinsic),
      mode: LoggerMode.info,
      onError: (exception, trace) => AppLogData(
          runtime: "SubstrateChainMetadata",
          err: exception,
          trace: trace.toString(),
          msg: "Unsupported network metadata."),
    );
    if (extrinsic == null) {
      throw WalletException.message('unsuported_network_metadata');
    }
    List<SubstrateCallPalletTransferMethod> transferMethods = [];
    if (controller != null) {
      transferMethods =
          SubstrateNetworkControllerLocalAssetTransferBuilder.transferMethods(
              metadata: MetadataWithExtrinsic(api: metadata, extrinsic: extrinsic),
              asset: controller.defaultNativeAsset);
    } else {
      transferMethods = _SubstrateChainConst.transferTypes(
          metadata: metadata, cryptoInfo: extrinsic.crypto);
    }

    bool pokeDeposit = false;
    bool supportMultisig = extrinsic.crypto.type != SubstrateChainType.ethereum;
    if (supportMultisig && maxSignatories != null) {
      try {
        final musigMethods =
            metadata.metadata.getCallMethodNames(SubtrateMetadataPallet.multisig.name);
        supportMultisig &= MultisigCallPalletMethod.values.every((e) {
          if (e == MultisigCallPalletMethod.pokeDeposit) return true;
          return musigMethods.contains(e.method);
        });
        pokeDeposit = musigMethods.contains(MultisigCallPalletMethod.pokeDeposit.method);
      } catch (_) {
        supportMultisig = false;
      }
    }

    final bool hasDryRunApi = SubstrateRuntimeApiDryRunMethods.values.every(
        (e) => SubstrateQuickRuntimeApi.dryRun.methodExists(api: metadata, method: e));
    final bool hasXcmPaymentApi = SubstrateRuntimeApiXCMPaymentMethods.values.every((e) =>
        SubstrateQuickRuntimeApi.xcmPayment.methodExists(api: metadata, method: e));
    final bool hasCurrencyConvertionApi = SubstrateRuntimeApiAssetConversionMethods.values
        .every((e) => SubstrateQuickRuntimeApi.assetConversion
            .methodExists(api: metadata, method: e));
    final supportBatch = batchedCallsLimit != null &&
        metadata.callMethodExists(
            SubtrateMetadataPallet.utility.name, UtilityCallPalletMethod.batchAll.method);
    return SubstrateChainMetadata._(
        batchedCallsLimit: batchedCallsLimit ?? 0,
        hasCurrencyConvertionApi: hasCurrencyConvertionApi,
        internalNetwork: substrateNetwork,
        controller: controller,
        hasXcmPaymentApi: hasXcmPaymentApi,
        hasDryRunApi: hasDryRunApi,
        metadataInfos: metadataInfos,
        supportTransferLocalToken: controller != null &&
            (controller.network.allowLocalTransfer ||
                _SubstrateChainConst.allowedLocalTransfer.contains(controller.network)),
        genesis: genesis,
        metadata: metadata,
        runtimeVersion: metadata.runtimeVersion(),
        extrinsic: extrinsic,
        baseDeposit: depositBase,
        depositFactor: depositFactor,
        maxSignatories: maxSignatories,
        nativeTransferMethods: transferMethods,
        supportPokeDeposit: pokeDeposit,
        xcmVersion: substrateNetwork?.defaultXcmVersion ?? XCMVersion.v4,
        supportAccountTemplate:
            _SubstrateChainConst.supportAccountTemplate(metadata: metadata),
        ss58Prefix: _SubstrateChainConst.ss58Prefix(metadata: metadata),
        supportBatch: supportBatch,
        supportRemarks: _SubstrateChainConst.supportRemark(metadata: metadata),
        supportMultisig: supportMultisig && maxSignatories != null,
        rpcMethods: rpcMethods,
        existentialDeposit: existentialDeposit != null && existentialDeposit > BigInt.zero
            ? existentialDeposit
            : null);
  }

  List<PalletInfo> constantPallets() {
    return metadataInfos.pallets.where((e) => e.contants != null).toList();
  }

  List<PalletInfo> callPallets() {
    return metadataInfos.pallets.where((e) => e.calls != null).toList();
  }

  List<PalletInfo> storagePallets() {
    return metadataInfos.pallets.where((e) => e.storage != null).toList();
  }

  StorageInfo? getAccountInfoStorageKey() {
    final system =
        metadataInfos.pallets.firstWhereOrNull((e) => e.name.toLowerCase() == "system");
    return system?.storage?.firstWhereOrNull((e) => e.name.toLowerCase() == "account");
  }

  MetadataTypeInfo getTypeInfo(Si1Variant variant) {
    MetadataTypeInfo info = variant.typeInfo(metadata.registry, 0);
    info = info.copyWith(name: info.name ?? variant.name);
    return info;
  }

  MetadataTypeInfo? getLookupTypeInfo(int? lockupId, {String? name}) {
    if (lockupId == null) return null;
    final info =
        metadata.metadata.getLookup(lockupId).typeInfo(metadata.registry, lockupId);
    if (name == null) return info;
    return info.copyWith(name: name);
  }

  ExtrinsicInfo createExtrinsic(
      {required List<int>? signature,
      required BaseSubstrateAddress address,
      required EllipticCurveTypes algorithm,
      required ExtrinsicPayloadInfo payload}) {
    final buffer = DynamicByteTracker();
    List<int>? encodeSignature;
    if (signature != null) {
      final encodedAddress = extrinsic.encodeSigner(address: address, metadata: metadata);
      encodeSignature = extrinsic.encodeSignature(
          algorithm: algorithm, signature: signature, metadata: metadata);
      buffer.add(encodedAddress);
      buffer.add(encodeSignature);
    }
    if (payload.extrinsic != null) {
      buffer.add(payload.extrinsic!.encodeExtrinsic(metadata));
    }
    final encodeBytes = buffer.toBytes().asImmutableBytes;
    final encodeData = BytesUtils.toHexString(encodeBytes);
    return ExtrinsicInfo(
        payload: payload,
        serializedExtrinsic: encodeData,
        version: extrinsic.extrinsicInfo.version,
        encodeSignature: encodeSignature);
  }
}
