import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:ton_dart/ton_dart.dart';

enum TonAccountContextType {
  legacy(AppSerializationIdentifier.tonAddressLegacy),
  subwallet(AppSerializationIdentifier.tonAddressSubWallet),
  v5(AppSerializationIdentifier.tonAddressV5),
  v5SubWallet(AppSerializationIdentifier.tonAddressV5SubWallet);

  final AppSerializationIdentifier tag;
  const TonAccountContextType(this.tag);
  static TonAccountContextType fromTag(int? tag) {
    return values.firstWhere((e) => e.tag.isValid(tag),
        orElse: () => throw AppInternalError.internalError("TonAccountContextType"));
  }
}

abstract class TonAccountContext with AppSerialization, Equality {
  final TonAccountContextType type;
  final WalletVersion version;
  final bool bouncable;
  final TonWorkChain workchain;
  final TonChainId chainId;
  int? get subOrWalletId;
  const TonAccountContext(
      {required this.type,
      required this.version,
      required this.bouncable,
      required this.workchain,
      required this.chainId});
  VersionedWalletContract toWalletContract(List<int> publicKey);
  Cell buildTransaction(
      {required List<OutActionSendMsg> actions,
      required VersionedWalletState state,
      required int seqno,
      int? timeout}) {
    return TonSerializationUtils.serializeMessage(
        actions: actions, state: state, seqno: seqno, timeout: timeout);
  }

  Message toExternalMessage(
      {required Cell message,
      required List<int> signature,
      required TonAddress destination,
      StateInit? state}) {
    final body =
        beginCell().storeBuffer(signature).storeSlice(message.beginParse()).endCell();
    return Message(
        init: state,
        info: CommonMessageInfoExternalIn(dest: destination, importFee: BigInt.zero),
        body: body);
  }

  factory TonAccountContext.deserialize({List<int>? bytes, CborObject? object}) {
    final decode = AppSerialization.decodeTaggedValueWithInfo(
        cborBytes: bytes,
        cborObject: object,
        expectedTags: TonAccountContextType.values.map((e) => e.tag).toList());
    final type = TonAccountContextType.fromTag(decode.identifier.id);
    switch (type) {
      case TonAccountContextType.legacy:
        return TonAccountLegacyContext.deserialize(object: decode.tag);
      case TonAccountContextType.subwallet:
        return TonAccountSubWalletContext.deserialize(object: decode.tag);
      case TonAccountContextType.v5:
        return TonAccountV5CustomContext.deserialize(object: decode.tag);
      case TonAccountContextType.v5SubWallet:
        return TonAccountV5SubWalletContext.deserialize(object: decode.tag);
    }
  }

  @override
  SerializationIdentifier get serializationIdentifier => type.tag;
}

class TonAccountLegacyContext extends TonAccountContext {
  TonAccountLegacyContext._({
    required super.version,
    required super.bouncable,
    required super.workchain,
    required super.chainId,
  }) : super(type: TonAccountContextType.legacy);
  factory TonAccountLegacyContext({
    required WalletVersion version,
    required bool bouncable,
    required TonWorkChain workchain,
    required TonChainId chainId,
  }) {
    if (version.version > 2) {
      throw WalletExceptionConst.invalidAccountData("TonAccountLegacyContext");
    }
    return TonAccountLegacyContext._(
        version: version, bouncable: bouncable, chainId: chainId, workchain: workchain);
  }
  factory TonAccountLegacyContext.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: TonAccountContextType.legacy.tag,
        cborBytes: bytes,
        cborObject: object);
    return TonAccountLegacyContext(
        version: WalletVersion.fromValue(values.rawValueAt(0)),
        bouncable: values.rawValueAt(1),
        chainId: TonChainId.fromId(values.rawValueAt(2)),
        workchain: TonWorkChain(values.rawValueAt(3)));
  }

  @override
  VersionedWalletContract<VersionedWalletState, WalletContractTransferParams<OutAction>>
      toWalletContract(List<int> publicKey) {
    return switch (version) {
      WalletVersion.v1R1 => WalletV1R1.create(
          chainId: chainId,
          publicKey: publicKey,
          bounceableAddress: bouncable,
          workchain: workchain),
      WalletVersion.v1R2 => WalletV1R2.create(
          chainId: chainId,
          publicKey: publicKey,
          bounceableAddress: bouncable,
          workchain: workchain),
      WalletVersion.v1R3 => WalletV1R3.create(
          chainId: chainId,
          publicKey: publicKey,
          bounceableAddress: bouncable,
          workchain: workchain),
      WalletVersion.v2R1 => WalletV2R1.create(
          chainId: chainId,
          publicKey: publicKey,
          bounceableAddress: bouncable,
          workchain: workchain),
      WalletVersion.v2R2 => WalletV2R2.create(
          chainId: chainId,
          publicKey: publicKey,
          bounceableAddress: bouncable,
          workchain: workchain),
      _ => throw WalletExceptionConst.invalidAccountData(
          "TonAccountLegacyContext.toWalletContract")
    };
  }

  @override
  int? get subOrWalletId => null;
  @override
  List get variables => [version.name];

  @override
  List<CborObject?> get serializationItems => [
        version.name.toCbor(),
        bouncable.toCbor(),
        chainId.id.toCbor(),
        workchain.id.toCbor()
      ];
}

class TonAccountSubWalletContext extends TonAccountContext {
  final int subwalletId;
  const TonAccountSubWalletContext._({
    required super.version,
    required this.subwalletId,
    required super.bouncable,
    required super.workchain,
    required super.chainId,
  }) : super(type: TonAccountContextType.subwallet);

  factory TonAccountSubWalletContext({
    required WalletVersion version,
    required int subwalletId,
    required bool bouncable,
    required TonWorkChain workchain,
    required TonChainId chainId,
  }) {
    if (version.version < 3 || version.version > 4) {
      throw WalletExceptionConst.invalidAccountData("TonAccountSubWalletContext");
    }
    return TonAccountSubWalletContext._(
        version: version,
        subwalletId: subwalletId,
        bouncable: bouncable,
        chainId: chainId,
        workchain: workchain);
  }
  factory TonAccountSubWalletContext.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: TonAccountContextType.subwallet.tag,
        cborBytes: bytes,
        cborObject: object);
    return TonAccountSubWalletContext(
        version: WalletVersion.fromValue(values.rawValueAt(0)),
        bouncable: values.rawValueAt(1),
        subwalletId: values.rawValueAt(2),
        chainId: TonChainId.fromId(values.rawValueAt(3)),
        workchain: TonWorkChain(values.rawValueAt(4)));
  }

  @override
  VersionedWalletContract<VersionedWalletState, WalletContractTransferParams<OutAction>>
      toWalletContract(List<int> publicKey) {
    return switch (version) {
      WalletVersion.v3R1 => WalletV3R1.create(
          chainId: chainId,
          publicKey: publicKey,
          bounceableAddress: bouncable,
          subWalletId: subwalletId,
          workchain: workchain),
      WalletVersion.v3R2 => WalletV3R2.create(
          chainId: chainId,
          publicKey: publicKey,
          bounceableAddress: bouncable,
          subWalletId: subwalletId,
          workchain: workchain),
      WalletVersion.v4 => WalletV4.create(
          chainId: chainId,
          publicKey: publicKey,
          bounceableAddress: bouncable,
          subWalletId: subwalletId,
          workchain: workchain),
      _ => throw WalletExceptionConst.invalidAccountData(
          "TonAccountSubWalletContext.toWalletContract")
    };
  }

  @override
  List get variables => [version.name, subwalletId];

  @override
  int? get subOrWalletId => subwalletId;

  @override
  List<CborObject?> get serializationItems => [
        version.name.toCbor(),
        bouncable.toCbor(),
        subwalletId.toCbor(),
        chainId.id.toCbor(),
        workchain.id.toCbor()
      ];
}

class TonAccountV5CustomContext extends TonAccountContext {
  final int walletId;

  const TonAccountV5CustomContext._({
    required this.walletId,
    required super.bouncable,
    required super.workchain,
    required super.chainId,
  }) : super(type: TonAccountContextType.v5, version: WalletVersion.v5R1);
  factory TonAccountV5CustomContext({
    required WalletVersion version,
    required int contextId,
    required bool bouncable,
    required TonWorkChain workchain,
    required TonChainId chainId,
  }) {
    if (version != WalletVersion.v5R1) {
      throw WalletExceptionConst.invalidAccountData("TonAccountV5CustomContext");
    }
    return TonAccountV5CustomContext._(
        bouncable: bouncable,
        walletId: contextId,
        chainId: chainId,
        workchain: workchain);
  }
  factory TonAccountV5CustomContext.deserialize({List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: TonAccountContextType.v5.tag, cborBytes: bytes, cborObject: object);
    return TonAccountV5CustomContext(
        version: WalletVersion.fromValue(values.rawValueAt(0)),
        bouncable: values.rawValueAt(1),
        contextId: values.rawValueAt(2),
        chainId: TonChainId.fromId(values.rawValueAt(3)),
        workchain: TonWorkChain(values.rawValueAt(4)));
  }

  @override
  WalletV5R1 toWalletContract(List<int> publicKey) {
    return WalletV5R1.create(
        chainId: chainId,
        publicKey: publicKey,
        bounceableAddress: bouncable,
        workchain: workchain,
        context: V5R1CustomContext(context: walletId, chainId: chainId));
  }

  @override
  Cell buildTransaction(
      {required List<OutActionSendMsg> actions,
      required VersionedWalletState state,
      required int seqno,
      int? timeout}) {
    return TonSerializationUtils.serializeV5(
        accountSeqno: seqno,
        actions: OutActionsV5(actions: actions),
        type: WalletV5AuthType.external,
        timeout: timeout,
        context: V5R1CustomContext(context: walletId, chainId: chainId));
  }

  @override
  Message toExternalMessage(
      {required Cell message,
      required List<int> signature,
      required TonAddress destination,
      StateInit? state}) {
    final body =
        beginCell().storeSlice(message.beginParse()).storeBuffer(signature).endCell();
    return Message(
        init: state,
        info: CommonMessageInfoExternalIn(dest: destination, importFee: BigInt.zero),
        body: body);
  }

  @override
  int? get subOrWalletId => walletId;
  @override
  List get variables => [version.name, walletId];

  @override
  List<CborObject?> get serializationItems => [
        version.name.toCbor(),
        bouncable.toCbor(),
        walletId.toCbor(),
        chainId.id.toCbor(),
        workchain.id.toCbor()
      ];
}

class TonAccountV5SubWalletContext extends TonAccountContext {
  final int subwalletId;

  const TonAccountV5SubWalletContext._({
    required this.subwalletId,
    required super.bouncable,
    required super.workchain,
    required super.chainId,
  }) : super(type: TonAccountContextType.v5SubWallet, version: WalletVersion.v5R1);

  factory TonAccountV5SubWalletContext({
    required WalletVersion version,
    required int subwalletId,
    required bool bouncable,
    required TonWorkChain workchain,
    required TonChainId chainId,
  }) {
    if (version != WalletVersion.v5R1) {
      throw WalletExceptionConst.invalidAccountData("TonAccountV5SubWalletContext");
    }
    return TonAccountV5SubWalletContext._(
        subwalletId: subwalletId,
        bouncable: bouncable,
        chainId: chainId,
        workchain: workchain);
  }
  factory TonAccountV5SubWalletContext.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final values = AppSerialization.decodeTaggedValue(
        identifier: TonAccountContextType.v5SubWallet.tag,
        cborBytes: bytes,
        cborObject: object);
    return TonAccountV5SubWalletContext(
        version: WalletVersion.fromValue(values.rawValueAt(0)),
        bouncable: values.rawValueAt(1),
        subwalletId: values.rawValueAt(2),
        chainId: TonChainId.fromId(values.rawValueAt(3)),
        workchain: TonWorkChain(values.rawValueAt(4)));
  }

  @override
  WalletV5R1 toWalletContract(List<int> publicKey) {
    return WalletV5R1.create(
        chainId: chainId,
        publicKey: publicKey,
        bounceableAddress: bouncable,
        workchain: workchain,
        context: V5R1ClientContext(
            subwalletNumber: subwalletId, chainId: chainId, workchain: workchain));
  }

  @override
  Cell buildTransaction({
    required List<OutActionSendMsg> actions,
    required VersionedWalletState state,
    required int seqno,
    int? timeout,
  }) {
    return TonSerializationUtils.serializeV5(
        accountSeqno: seqno,
        actions: OutActionsV5(actions: actions),
        type: WalletV5AuthType.external,
        timeout: timeout,
        context: V5R1ClientContext(
            subwalletNumber: subwalletId, chainId: chainId, workchain: workchain));
  }

  @override
  Message toExternalMessage(
      {required Cell message,
      required List<int> signature,
      required TonAddress destination,
      StateInit? state}) {
    final body =
        beginCell().storeSlice(message.beginParse()).storeBuffer(signature).endCell();
    return Message(
        init: state,
        info: CommonMessageInfoExternalIn(dest: destination, importFee: BigInt.zero),
        body: body);
  }

  @override
  int? get subOrWalletId => subwalletId;
  @override
  List get variables => [version.name, subwalletId];

  @override
  List<CborObject?> get serializationItems => [
        version.name.toCbor(),
        bouncable.toCbor(),
        subwalletId.toCbor(),
        chainId.id.toCbor(),
        workchain.id.toCbor()
      ];
}
