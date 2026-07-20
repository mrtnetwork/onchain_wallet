import 'package:blockchain_utils/bip/bip.dart';
import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';

import 'package:cosmos_sdk/cosmos_sdk.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_bridge/database/models/table.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';

import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/wallet/api/service/types/provider.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/models/account/utxos.dart';
import 'signing_response.dart';

typedef OnSignRequest = Future<T> Function<T extends SignResponse>(SignRequest<T>);

sealed class SignRequest<T extends SignResponse> with AppSerialization {
  Duration get processTimeout;
  final SigningRequestMode signingMode;
  List<DerivableIndex> get indexes;
  const SignRequest({required this.signingMode});
  factory SignRequest.deserialize({List<int>? bytes, CborObject? object}) {
    final CborTagValue tag =
        AppSerialization.decode(cborBytes: bytes, cborObject: object);
    final signingMode = SigningRequestMode.fromTag(tag.tags);
    final SignRequest response = switch (signingMode) {
      SigningRequestMode.bitcoin ||
      SigningRequestMode.bitcoinCash =>
        BitcoinSigning.deserialize(object: tag),
      SigningRequestMode.cosmos => CosmosSigningRequest.deserialize(object: tag),
      SigningRequestMode.monero => MoneroSigningRequest.deserialize(object: tag),
      SigningRequestMode.zcash => ZcashSingningRequest.deserialize(object: tag),
      _ => GlobalSignRequest.deserialize(object: tag)
    };
    return response.cast();
  }
  E cast<E extends SignRequest>() {
    if (this is! E) {
      throw AppInternalError.internalError("SignRequest");
    }
    return this as E;
  }

  T toReponse({List<int>? bytes, CborObject? object});
}

enum SigningRequestMode {
  bitcoin(AppSerializationIdentifier.bitconNetwork),
  eth(AppSerializationIdentifier.evmNetwork),
  ripple(AppSerializationIdentifier.xrpNetwork),
  cardano(AppSerializationIdentifier.cardanoNetwork),
  ton(AppSerializationIdentifier.tonNetwork),
  cosmos(AppSerializationIdentifier.cosmosNetwork),
  solana(AppSerializationIdentifier.solanaNetwork),
  tron(AppSerializationIdentifier.tvmNetwork),
  substrate(AppSerializationIdentifier.substrateNetwork),
  stellar(AppSerializationIdentifier.stellar),
  monero(AppSerializationIdentifier.monero),
  bitcoinCash(AppSerializationIdentifier.bitcoinCashNetwork),
  aptos(AppSerializationIdentifier.aptos),
  sui(AppSerializationIdentifier.sui),
  moneroSpendKey(AppSerializationIdentifier.moneroSpendKeySign),
  zcash(AppSerializationIdentifier.zcash);

  final AppSerializationIdentifier tag;
  const SigningRequestMode(this.tag);
  static SigningRequestMode fromTag(List<int> tags) {
    return values.firstWhere((element) => element.tag.isValidTags(tags),
        orElse: () => throw AppInternalError.internalError("SigningRequestMode"));
  }
}

final class BitcoinSigning extends GlobalSignRequest {
  final int? sighash;
  final bool useTaproot;
  final bool useBchSchnorr;

  BitcoinSigning(
      {required super.digest,
      this.sighash,
      required this.useTaproot,
      required Bip32DerivationIndex super.index,
      required super.signingMode,
      required this.useBchSchnorr})
      : assert(
            signingMode == SigningRequestMode.bitcoin ||
                signingMode == SigningRequestMode.bitcoinCash,
            "invalid bitcoin signingMode."),
        super._();

  factory BitcoinSigning.deserialize({List<int>? bytes, CborObject? object}) {
    final CborTagValue tag = AppSerialization.decode(
      cborBytes: bytes,
      cborObject: object,
    );
    final signingMode = SigningRequestMode.fromTag(tag.tags);
    if (signingMode != SigningRequestMode.bitcoin &&
        signingMode != SigningRequestMode.bitcoinCash) {
      throw AppInternalError.internalError("BitcoinSigning");
    }
    final CborListValue values = tag.asValue();
    return BitcoinSigning(
        digest: values.rawValueAt(1),
        sighash: values.rawValueAt(2),
        useTaproot: values.rawValueAt(3),
        index: Bip32DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
        signingMode: signingMode,
        useBchSchnorr: values.rawValueAt(4));
  }

  @override
  List<CborObject?> get serializationItems => [
        index.toCbor(),
        digest.toCborBytes(),
        sighash?.toCbor(),
        useTaproot.toCbor(),
        useBchSchnorr.toCbor()
      ];
  @override
  SerializationIdentifier get serializationIdentifier => signingMode.tag;
}

final class GlobalSignRequest extends SignRequest<GlobalSignResponse> {
  final List<int> digest;
  final DerivableIndex index;
  GlobalSignRequest._({
    required List<int> digest,
    required super.signingMode,
    required this.index,
  }) : digest = digest.asImmutableBytes;

  factory GlobalSignRequest.deserialize({List<int>? bytes, CborObject? object}) {
    final CborTagValue tag =
        AppSerialization.decode(cborBytes: bytes, cborObject: object);
    final CborListValue values = tag.asValue();
    final index = DerivableIndex.deserialize(object: values.objectAt<CborTagValue>(0));
    final List<int> digest = values.rawValueAt(1);
    final signingMode = SigningRequestMode.fromTag(tag.tags);
    return GlobalSignRequest._(digest: digest, signingMode: signingMode, index: index);
  }

  factory GlobalSignRequest.eth({
    required List<int> digest,
    required Bip32DerivationIndex index,
  }) {
    return GlobalSignRequest._(
        digest: digest, signingMode: SigningRequestMode.eth, index: index);
  }
  factory GlobalSignRequest.ripple({
    required List<int> digest,
    required Bip32DerivationIndex index,
  }) {
    return GlobalSignRequest._(
        digest: digest, signingMode: SigningRequestMode.ripple, index: index);
  }
  factory GlobalSignRequest.tron({
    required List<int> digest,
    required Bip32DerivationIndex index,
  }) {
    return GlobalSignRequest._(
        digest: digest, signingMode: SigningRequestMode.tron, index: index);
  }
  factory GlobalSignRequest.solana({
    required List<int> digest,
    required Bip32DerivationIndex index,
  }) {
    return GlobalSignRequest._(
        digest: digest, signingMode: SigningRequestMode.solana, index: index);
  }
  factory GlobalSignRequest.aptos(
      {required List<int> digest, required Bip32DerivationIndex index}) {
    return GlobalSignRequest._(
        digest: digest, signingMode: SigningRequestMode.aptos, index: index);
  }
  factory GlobalSignRequest.sui({
    required List<int> digest,
    required Bip32DerivationIndex index,
  }) {
    return GlobalSignRequest._(
        digest: digest, signingMode: SigningRequestMode.sui, index: index);
  }
  factory GlobalSignRequest.stellar(
      {required List<int> digest, required Bip32DerivationIndex index}) {
    return GlobalSignRequest._(
        digest: digest, signingMode: SigningRequestMode.stellar, index: index);
  }
  factory GlobalSignRequest.moneroSpendKey(
      {required List<int> digest, required Bip32DerivationIndex index}) {
    return GlobalSignRequest._(
        digest: digest, signingMode: SigningRequestMode.moneroSpendKey, index: index);
  }
  factory GlobalSignRequest.ton({
    required List<int> digest,
    required Bip32DerivationIndex index,
  }) {
    return GlobalSignRequest._(
        digest: digest, signingMode: SigningRequestMode.ton, index: index);
  }
  factory GlobalSignRequest.cardano({
    required List<int> digest,
    required Bip32DerivationIndex index,
  }) {
    return GlobalSignRequest._(
        digest: digest, signingMode: SigningRequestMode.cardano, index: index);
  }
  factory GlobalSignRequest.substrate(
      {required List<int> digest, required DerivableIndex index}) {
    return GlobalSignRequest._(
        digest: digest, signingMode: SigningRequestMode.substrate, index: index);
  }

  @override
  SerializationIdentifier get serializationIdentifier => signingMode.tag;

  @override
  List<CborObject?> get serializationItems => [index.toCbor(), digest.toCborBytes()];

  @override
  List<DerivableIndex> get indexes => [index];

  @override
  GlobalSignResponse toReponse({List<int>? bytes, CborObject? object}) {
    return GlobalSignResponse.deserialize(bytes: bytes, object: object);
  }

  @override
  Duration get processTimeout => Duration(seconds: 60);
}

final class CosmosSigningRequest extends SignRequest<GlobalSignResponse> {
  final List<int> digest;
  final CosmosKeysAlgs alg;
  final DerivableIndex index;
  CosmosSigningRequest._({
    required List<int> digest,
    required super.signingMode,
    required this.index,
    required this.alg,
  }) : digest = digest.asImmutableBytes;
  factory CosmosSigningRequest({
    required List<int> digest,
    required DerivableIndex index,
    required CosmosKeysAlgs alg,
  }) {
    if (!CosmosKeysAlgs.supportedAlgs.contains(alg)) {
      throw AppInternalError.internalError("CosmosSigningRequest");
    }
    if (alg.coin(ChainType.mainnet).conf.type != index.currencyCoin.conf.type) {
      throw AppInternalError.internalError("CosmosSigningRequest");
    }
    return CosmosSigningRequest._(
        digest: digest, signingMode: SigningRequestMode.cosmos, index: index, alg: alg);
  }
  factory CosmosSigningRequest.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: SigningRequestMode.cosmos.tag);
    final index = DerivableIndex.deserialize(object: values.objectAt<CborTagValue>(0));
    final List<int> digest = values.rawValueAt(1);
    final CosmosKeysAlgs alg = CosmosKeysAlgs.fromValue(values.rawValueAt(2));
    return CosmosSigningRequest(digest: digest, index: index, alg: alg);
  }

  @override
  SerializationIdentifier get serializationIdentifier => signingMode.tag;

  @override
  List<CborObject?> get serializationItems =>
      [index.toCbor(), digest.toCborBytes(), alg.value.toCbor()];

  @override
  List<DerivableIndex> get indexes => [index];

  @override
  GlobalSignResponse toReponse({List<int>? bytes, CborObject? object}) {
    return GlobalSignResponse.deserialize(bytes: bytes, object: object);
  }

  @override
  Duration get processTimeout => Duration(seconds: 60);
}

final class MoneroSigningRequest extends SignRequest<GlobalSignResponse> {
  final List<MoneroTxDestination> destinations;
  final BigInt fee;
  final MoneroTxDestination? change;
  final List<SpendablePayment<MoneroLockedPayment>> utxos;
  final bool withProof;
  final DerivableIndex index;
  MoneroSigningRequest(
      {required List<MoneroTxDestination> destinations,
      required this.fee,
      this.change,
      required List<SpendablePayment<MoneroLockedPayment>> utxos,
      required this.index,
      this.withProof = false})
      : destinations = destinations.immutable,
        utxos = utxos.immutable,
        super(signingMode: SigningRequestMode.monero);
  factory MoneroSigningRequest.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: SigningRequestMode.monero.tag);

    return MoneroSigningRequest(
        index: Bip32DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
        destinations: values
            .listAt<CborBytesValue>(1)
            .map((e) => MoneroTxDestination.deserialize(e.value))
            .toList(),
        fee: values.rawValueAt(2),
        change: values.maybeObjectAt<MoneroTxDestination, CborBytesValue>(
            3, (e) => MoneroTxDestination.deserialize(e.value)),
        utxos: values
            .listAt<CborBytesValue>(4)
            .map((e) => SpendablePayment<MoneroLockedPayment>.deserialize(e.value))
            .toList()
            .cast(),
        withProof: values.rawValueAt(5));
  }

  List<MoneroSubIndex> getAccountsIndexes() {
    return utxos.map((e) => e.payment.output.accountIndex).toSet().toList();
  }

  @override
  SerializationIdentifier get serializationIdentifier => signingMode.tag;

  @override
  List<CborObject?> get serializationItems => [
        index.toCbor(),
        AppSerialization.listFromObjects(
            destinations.map((e) => CborBytesValue(e.serialize())).toList()),
        fee.toCbor(),
        change?.serialize().toCborBytes(),
        AppSerialization.listFromObjects(
            utxos.map((e) => CborBytesValue(e.serialize())).toList()),
        withProof.toCbor()
      ];

  @override
  List<DerivableIndex> get indexes => [index];

  @override
  GlobalSignResponse toReponse({List<int>? bytes, CborObject? object}) {
    return GlobalSignResponse.deserialize(bytes: bytes, object: object);
  }

  @override
  Duration get processTimeout {
    final totalUtxos = utxos.length * 20;
    final totalDestinations = destinations.length * 10;
    return Duration(seconds: totalUtxos + totalDestinations);
  }
}

final class ZcashSingningRequest extends SignRequest<ZcashSignResponse> {
  final TableStructAColums chainStateColumn;
  final int targetHeight;
  final List<ZcashUtxosWithAccountInfo> utxos;
  final List<ZcashTransactionOutput> outputs;
  final ZcashNetwork zcashNetwork;
  final DefaultAPIProvider provider;
  final BigInt fee;
  final bool verifyAutorization;
  @override
  final List<DerivableIndex> indexes;

  bool get hasSaplingSpend => utxos.any((e) => e.account.type.isSapling);
  bool get hasSaplingOutput => outputs.any((e) => e.protocol.isSapling);
  bool get hasOrchardSpend => utxos.any((e) => e.account.type.isOrchard);
  bool get hasOrchardOutput => outputs.any((e) => e.protocol.isOrchard);
  bool get hasOrchardAction => hasOrchardSpend || hasOrchardOutput;
  bool get hasTransparentSpend => utxos.any((e) => e.account.type.isTransparent);
  List<ZcashUtxo> get allUtxos =>
      utxos.expand((e) => e.utxos.map((e) => e.utxo)).toList();

  @override
  Duration get processTimeout {
    final saplingSpends = allUtxos.saplingUtxos.length * 20;
    final saplingOutputs = outputs.where((e) => e.protocol.isSapling).length * 10;
    final orchard = allUtxos.orchardUtxos.length * 10;
    final transparent = allUtxos.transparentUtxos.length * 15;
    return Duration(
        seconds:
            IntUtils.max(120, saplingSpends + saplingOutputs + orchard + transparent));
  }

  ZcashSingningRequest({
    required this.chainStateColumn,
    required this.targetHeight,
    required this.utxos,
    required this.outputs,
    required this.zcashNetwork,
    required this.fee,
    required this.provider,
    this.verifyAutorization = false,
  })  : indexes = utxos
            .expand((e) => e.account.accountDerivationIndexes(request: null))
            .followedBy(outputs.expand((e) => switch (e) {
                  ZcashTransactionOutputShielded sheild =>
                    sheild.change?.accountDerivationIndexes(request: null) ?? [],
                  ZcashTransactionOutputTransparent() => [],
                }))
            .toImutableList,
        super(signingMode: SigningRequestMode.zcash);

  factory ZcashSingningRequest.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: SigningRequestMode.zcash.tag);
    return ZcashSingningRequest(
        chainStateColumn: TableStructAColums.deserialize(obj: values.objectAt(0)),
        targetHeight: values.rawValueAt(1),
        utxos: values
            .listAt<CborTagValue>(2)
            .map((e) => ZcashUtxosWithAccountInfo.deserialize(object: e))
            .toList(),
        outputs: values
            .listAt<CborTagValue>(3)
            .map((e) => ZcashTransactionOutput.deserialize(object: e))
            .toList(),
        zcashNetwork: ZcashNetwork.fromValue(values.rawValueAt(4)),
        fee: values.rawValueAt(5),
        verifyAutorization: values.rawValueAt(6),
        provider: DefaultAPIProvider.deserialize(object: values.objectAt(7)));
  }

  @override
  SerializationIdentifier get serializationIdentifier => signingMode.tag;

  @override
  List<CborObject?> get serializationItems => [
        chainStateColumn.toCbor(),
        targetHeight.toCbor(),
        AppSerialization.listFromObjects(utxos.map((e) => e.toCbor()).toList()),
        AppSerialization.listFromObjects(outputs.map((e) => e.toCbor()).toList()),
        zcashNetwork.value.toCbor(),
        fee.toCbor(),
        verifyAutorization.toCbor(),
        provider.toCbor()
      ];

  @override
  ZcashSignResponse toReponse({List<int>? bytes, CborObject? object}) {
    return ZcashSignResponse.deserialize(bytes: bytes, object: object);
  }
}
