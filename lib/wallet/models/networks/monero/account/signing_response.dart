import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';

import 'package:on_chain_wallet/crypto/networks/utils.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class MoneroViewTxDestinationWithProof with AppSerialization {
  final MoneroTxDestination destination;
  final String? proof;
  const MoneroViewTxDestinationWithProof({required this.destination, this.proof});
  factory MoneroViewTxDestinationWithProof.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.moneroTxDestinationWithProof);
    return MoneroViewTxDestinationWithProof(
        destination: MoneroTxDestination.deserialize(values.rawValueAt(0)),
        proof: values.rawValueAt(1));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.moneroTxDestinationWithProof;

  @override
  List<CborObject?> get serializationItems =>
      [CborBytesValue(destination.serialize()), proof?.toCbor()];
}

class MoneroSignedTxData with AppSerialization {
  final String txID;
  final List<MoneroPrivateKey> txKeys;
  final List<MoneroSubIndex> indexes;
  MoneroSignedTxData(
      {required String txID,
      required List<MoneroPrivateKey> txKeys,
      required List<MoneroSubIndex> indexes})
      : txID = QuickCryptoValidator.asValidHexBytes(txID,
            lengthInBytes: MoneroConst.txHashLength),
        txKeys = txKeys.immutable,
        indexes = indexes.immutable;
  factory MoneroSignedTxData.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.moneroSignedTxData);
    return MoneroSignedTxData(
        txID: String.fromCharCodes(values.rawValueAt(0)),
        txKeys: values
            .listAt<CborBytesValue>(1)
            .map((e) => MoneroPrivateKey.fromBytes(e.value))
            .toList(),
        indexes: values
            .listAt<CborBytesValue>(2)
            .map((e) => MoneroSubIndex.deserialize(e.value))
            .toList());
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.moneroSignedTxData;

  @override
  List<CborObject?> get serializationItems => [
        CborBytesValue(txID.codeUnits),
        AppSerialization.listFromObjects(
            txKeys.map((e) => CborBytesValue(e.key)).toList()),
        AppSerialization.listFromObjects(
            indexes.map((e) => CborBytesValue(e.serialize())).toList()),
      ];
}

class MoneroSigningTxResponse with AppSerialization {
  final MoneroSignedTxData txData;
  final List<MoneroViewTxDestinationWithProof> destinations;
  final String txBytes;
  MoneroSigningTxResponse({
    required this.txData,
    required List<MoneroViewTxDestinationWithProof> destinations,
    required String txHex,
  })  : destinations = destinations.immutable,
        txBytes = QuickCryptoValidator.asValidHexBytes(txHex);
  factory MoneroSigningTxResponse.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: AppSerializationIdentifier.moneroSigningTxResponse);
    return MoneroSigningTxResponse(
        txData: MoneroSignedTxData.deserialize(object: values.objectAt<CborTagValue>(0)),
        destinations: values
            .listAt<CborTagValue>(1)
            .map((e) => MoneroViewTxDestinationWithProof.deserialize(object: e))
            .toList(),
        txHex: String.fromCharCodes(values.rawValueAt(2)));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.moneroSigningTxResponse;

  @override
  List<CborObject?> get serializationItems => [
        txData.toCbor(),
        AppSerialization.listFromObjects(destinations.map((e) => e.toCbor()).toList()),
        CborBytesValue(txBytes.codeUnits)
      ];
}
