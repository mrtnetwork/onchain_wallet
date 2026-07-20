import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/monero_ring_output_response.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/monero/monero.dart';
import 'package:on_chain_wallet/wallet/api/service/types/provider.dart';
import 'package:on_chain_wallet/wallet/constant/networks/monero.dart';
import 'package:on_chain_wallet/wallet/models/networks/monero/monero.dart';

final class NoneEncryptedRequestGenerateRingOutput
    extends CryptoRequest<MoneroGenerateRingOutResponse> {
  final List<MoneroLockedPayment> payments;
  int get fakeOutsLength => MoneroConst.fakeOutputsLength;
  final BigInt maxGlobalIndex;
  final DefaultAPIProvider provider;
  NoneEncryptedRequestGenerateRingOutput({
    required List<MoneroLockedPayment> payments,
    required this.provider,
    required this.maxGlobalIndex,
  }) : payments = payments.immutable;
  factory NoneEncryptedRequestGenerateRingOutput.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: CryptoRequestMethod.generateRingOutput.tag);

    return NoneEncryptedRequestGenerateRingOutput(
        provider: DefaultAPIProvider.deserialize(object: values.objectAt(0)),
        payments: values
            .listAt<CborBytesValue>(1)
            .map((e) => MoneroLockedPayment.deserialize(e.value))
            .toList()
            .cast(),
        maxGlobalIndex: values.rawValueAt(2));
  }

  @override
  MoneroGenerateRingOutResponse parsResult(MessageArgsComplete result) {
    return MoneroGenerateRingOutResponse.deserialize(object: result.result);
  }

  @override
  CryptoRequestMethod get method => CryptoRequestMethod.generateRingOutput;

  Future<List<BigInt>> getAbsoluteDistribution(MoneroClient client) async {
    final distributions = await client.getBinaryAbsoluteDistribution();
    if (distributions.distributions.length != 1) {
      throw APIErrorConst.serverUnexpectedResponse;
    }
    final List<BigInt> offsets =
        List<BigInt>.from(distributions.distributions[0].distribution);
    for (int i = 1; i < offsets.length; i++) {
      offsets[i] = offsets[i] + offsets[i - 1];
    }
    if (offsets.length < MoneroNetworkConst.cryptonoteDefaultTxSpendableAge ||
        offsets.last < maxGlobalIndex) {
      throw AppInternalError.internalError(
          "NoneEncryptedRequestGenerateRingOutput.getAbsoluteDistribution",
          reason: "Not enough distributions.",
          message: "generate_rct_faild");
    }
    return offsets;
  }

  Future<MoneroRingOutput> generateRing(MoneroClient client) async {
    final rctOffsets = await getAbsoluteDistribution(client);
    final int baseRequestCount = ((fakeOutsLength + 1) * 1.5 + 1).ceil();
    final List<BigInt> outKeysRequestOrder = [];
    List<BigInt> outKeysRequests = [];
    void addOuts(BigInt out) {
      outKeysRequestOrder.add(out);
      outKeysRequests.add(out);
    }

    final gamma = Gamma(rctOffsets: rctOffsets);
    for (final i in payments) {
      final Set<BigInt> indices = {};
      const defaultOutCount = MoneroNetworkConst.cryptonoteMinedMoneyUnlockWindow -
          MoneroNetworkConst.cryptonoteDefaultTxSpendableAge;
      final int outputsCount = baseRequestCount + defaultOutCount;
      final int start = outKeysRequests.length;
      final BigInt numOuts = gamma.numRctOuts;
      BigInt numFound = BigInt.zero;
      if (numOuts <= BigInt.from(outputsCount)) {
        for (BigInt i = BigInt.zero; i < numOuts; i += BigInt.one) {
          addOuts(i);
        }
        for (BigInt i = numOuts; i < BigInt.from(outputsCount); i += BigInt.one) {
          addOuts(i);
        }
      } else {
        if (numFound == BigInt.zero) {
          numFound = BigInt.one;
          indices.add(i.globalIndex);
          addOuts(i.globalIndex);
        }
        BigInt usableOuts = numOuts;
        bool blackballed = false;
        while (numFound < BigInt.from(outputsCount)) {
          if (BigInt.from(indices.length) == usableOuts) {
            if (blackballed) break;
            blackballed = true;
            usableOuts = numOuts;
          }
          BigInt i;
          do {
            i = gamma.pick();
          } while (i >= numOuts);
          if (indices.contains(i)) {
            continue;
          }
          indices.add(i);
          addOuts(i);
          numFound += BigInt.one;
        }
        while (numFound < BigInt.from(outputsCount)) {
          addOuts(BigInt.zero);
          numFound += BigInt.one;
        }
      }
      final lastPart = outKeysRequests.sublist(start)..sort((a, b) => a.compareTo(b));
      outKeysRequests = [...outKeysRequests.sublist(0, start), ...lastPart];
    }
    return MoneroRingOutput(
        orderedIndexes: outKeysRequestOrder, indexes: outKeysRequests);
  }

  Future<List<SpendablePayment<MoneroLockedPayment>>> generatePaymentOutputsRings(
      {required List<MoneroLockedPayment> payments,
      required List<BigInt> outKeysRequestOrder,
      required List<BigInt> outKeysRequests,
      required MoneroClient client}) async {
    final List<List<OutsEntery>> outs = [];
    final int baseRequestCount = ((fakeOutsLength + 1) * 1.5 + 1).ceil();
    final List<OutKeyResponse> outKeysResponse = [];
    int offset = 0;
    while (offset < outKeysRequests.length) {
      const int size = 1000;
      final int outChunSize = IntUtils.min(outKeysRequests.length - offset, size);
      final List<DaemonGetOutRequestParams> chunkRequest = List.generate(
          outChunSize,
          (i) => DaemonGetOutRequestParams(
              amount: BigInt.zero, index: outKeysRequests[offset + i]));
      offset += size;
      final outs = await client.getOuts(chunkRequest);
      outKeysResponse.addAll(outs.outs);
    }
    int base = 0;
    for (final payment in payments) {
      const defaultOutCount = MoneroNetworkConst.cryptonoteMinedMoneyUnlockWindow -
          MoneroNetworkConst.cryptonoteDefaultTxSpendableAge;
      final int outputsCount = baseRequestCount + defaultOutCount;
      final List<OutsEntery> out = [];
      final mask =
          RCT.commitVar(xmrAmount: payment.output.amount, mask: payment.output.mask);
      bool hasRealOut = false;
      for (int n = 0; n < outputsCount; ++n) {
        final int i = base + n;
        if (outKeysRequests[i] == payment.globalIndex) {
          if (BytesUtils.bytesEqual(
              outKeysResponse[i].key, payment.output.outputPublicKey)) {
            if (BytesUtils.bytesEqual(outKeysResponse[i].mask, mask)) {
              if (outKeysResponse[i].unlocked) {
                hasRealOut = true;
              }
            }
          }
        }
      }
      if (!hasRealOut) {
        throw APIErrorConst.serverUnexpectedResponse;
      }
      out.add(OutsEntery(
          index: payment.globalIndex,
          key: CtKey(dest: payment.output.outputPublicKey, mask: mask)));

      for (int idx = base;
          idx < base + outputsCount && out.length < fakeOutsLength + 1;
          ++idx) {
        final attemptedOutput = outKeysRequestOrder[idx];
        int i;
        for (i = base; i < base + outputsCount; ++i) {
          if (outKeysRequests[i] == attemptedOutput) {
            break;
          }
        }
        if (i == base + outputsCount) {
          throw AppInternalError.internalError(
              "NoneEncryptedRequestGenerateRingOutput.generatePaymentOutputsRings",
              reason: "Could not find index of picked output in requested outputs.",
              message: "generate_rct_faild");
        }
        final fakeOutResponse = outKeysResponse[i];
        final fakeOutRequest = outKeysRequests[i];
        final fakeEntry = OutsEntery(
            index: fakeOutRequest,
            key: CtKey(dest: fakeOutResponse.key, mask: fakeOutResponse.mask));
        if (fakeOutResponse.unlocked &&
            fakeOutRequest != payment.globalIndex &&
            !out.contains(fakeEntry)) {
          out.add(fakeEntry);
        }
      }
      out.sort((a, b) => a.index.compareTo(b.index));
      outs.add(out);
      if (out.length < fakeOutsLength + 1) {
        throw AppInternalError.internalError(
            "NoneEncryptedRequestGenerateRingOutput.generatePaymentOutputsRings",
            reason: "not enough outs to mix.",
            message: "generate_rct_faild");
      }

      base += outputsCount;
    }
    return List.generate(payments.length, (i) {
      final payment = payments[i];
      final sourceOuts = outs[i];
      final index = sourceOuts.indexWhere((e) => e.index == payment.globalIndex);
      if (index.isNegative) {
        throw AppInternalError.internalError(
            "NoneEncryptedRequestGenerateRingOutput.generatePaymentOutputsRings",
            reason: "Unable to found output global index.",
            message: "generate_rct_faild");
      }
      return SpendablePayment<MoneroLockedPayment>(
          payment: payment, outs: sourceOuts, realOutIndex: index);
    });
  }

  @override
  Future<MoneroGenerateRingOutResponse> result(AppContext context,
      {List<int>? encryptedPart}) async {
    final client = MoneroClient.fromProviders(provider: provider, netApi: context.netApi);
    try {
      final ringOutput = await generateRing(client);
      final payments = await generatePaymentOutputsRings(
          payments: this.payments,
          outKeysRequestOrder: ringOutput.orderedIndexes,
          outKeysRequests: ringOutput.indexes,
          client: client);
      return MoneroGenerateRingOutResponse(payments);
    } finally {
      client.dispose();
    }
  }

  @override
  SerializationIdentifier get serializationIdentifier => method.tag;

  @override
  List<CborObject?> get serializationItems => [
        provider.toCbor(),
        AppSerialization.listFromObjects(
            payments.map((e) => CborBytesValue(e.serialize())).toList()),
        maxGlobalIndex.toCbor(),
      ];
}
