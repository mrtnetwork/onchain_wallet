import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';

final class NoneEncryptedRequestFakeMoneroTx
    extends CryptoRequest<AppSerializationBigInt> {
  final List<MoneroTxDestination> destinations;
  final BigInt fee;
  final MoneroTxDestination? change;
  final List<MoneroUnLockedPayment> fakePayments;
  NoneEncryptedRequestFakeMoneroTx(
      {required List<MoneroTxDestination> destinations,
      required this.fee,
      required this.change,
      required List<MoneroUnLockedPayment> fakePayments})
      : destinations = destinations.immutable,
        fakePayments = fakePayments.immutable;
  factory NoneEncryptedRequestFakeMoneroTx.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: CryptoRequestMethod.moneroFakeTx.tag);

    return NoneEncryptedRequestFakeMoneroTx(
        destinations: values
            .listAt<CborBytesValue>(0)
            .map((e) => MoneroTxDestination.deserialize(e.value))
            .toList(),
        fee: values.rawValueAt(1),
        change: values.maybeObjectAt<MoneroTxDestination, CborBytesValue>(
            2, (e) => MoneroTxDestination.deserialize(e.value)),
        fakePayments: values
            .listAt<CborBytesValue>(3)
            .map((e) => MoneroPayment.deserialize(e.value))
            .toList()
            .cast());
  }

  @override
  AppSerializationBigInt parsResult(MessageArgsComplete result) {
    return AppSerializationBigInt.deserialize(obj: result.result);
  }

  @override
  CryptoRequestMethod get method => CryptoRequestMethod.moneroFakeTx;

  @override
  Future<AppSerializationBigInt> result(AppContext context,
      {List<int>? encryptedPart}) async {
    final List<SpendablePayment<MoneroUnLockedPayment<MoneroUnlockedOutput>>>
        spendablePayment =
        MoneroTransactionHelper.generateFakePaymentOuts(payments: fakePayments);
    final MoneroRctTxBuilder tx = MoneroRctTxBuilder(
        account: MoneroAccountKeys(
            account: MoneroAccount.fromSeed(RCT.identity(clone: false)),
            network: MoneroNetwork.mainnet),
        destinations: destinations,
        sources: spendablePayment,
        fee: fee,
        fakeTx: true,
        change: change);

    return AppSerializationBigInt(tx.weight());
  }

  @override
  SerializationIdentifier get serializationIdentifier => method.tag;

  @override
  List<CborObject?> get serializationItems => [
        AppSerialization.listFromObjects(
            destinations.map((e) => CborBytesValue(e.serialize())).toList()),
        fee.toCbor(),
        change?.serialize().toCborBytes(),
        AppSerialization.listFromObjects(
            fakePayments.map((e) => CborBytesValue(e.toVariantSerialize())).toList()),
      ];
}
