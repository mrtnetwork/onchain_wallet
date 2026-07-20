import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network.dart';
import 'package:on_chain_wallet/wallet/models/networks/ton/ton.dart';
import 'package:ton_dart/ton_dart.dart';

class TonRquestGetFee extends TonApiRequest<TonTransactionFeeDetails, dynamic> {
  final Message message;
  final TonAddress address;
  final TonApiType api;
  final WalletTonNetwork network;
  final List<OutActionSendMsg> messages;
  TonRquestGetFee(
      {required this.message,
      required this.address,
      required this.api,
      required this.network,
      required this.messages});
  TonApiRequest? _request;
  TonApiRequest _getRequest() {
    if (!api.isTonCenter) {
      return TonApiEmulateMessageToTrace(
          boc: beginCell().store(message).endCell().toBase64(),
          ignoreSignatureCheck: true);
    }
    return TonCenterEstimateFee(
        address: address.address,
        body: message.body.toBase64(),
        initCode: message.init?.code?.toBase64() ?? "",
        initData: message.init?.data?.toBase64() ?? "");
  }

  @override
  TonRequestDetails buildRequest(int v) {
    _request = _getRequest();
    return _request!.buildRequest(v);
  }

  @override
  String get method => throw UnimplementedError();

  @override
  TonTransactionFeeDetails onResonse(result) {
    if (api.isTonCenter) {
      final r = (_request as TonCenterEstimateFee).onResonse(result);
      return TonTransactionFeeDetails(
          actionPhase: r.sourceFees.inFwdFee + r.sourceFees.fwdFee,
          storageFee: r.sourceFees.storageFee,
          gasFee: r.sourceFees.gasFee,
          success: true,
          network: network);
    }
    final r = (_request as TonApiEmulateMessageToTrace).onResonse(result);
    final messages = r.children.expand(emulateMessages);
    final succes = r.transaction.success && messages.every((e) => e.success);
    final error = r.transaction.actionPhase?.resultCodeDescription ??
        messages
            .firstWhereNullable(
                (e) => !e.success && e.resultDescription != null)
            ?.resultDescription;
    return TonTransactionFeeDetails(
        actionPhase: r.transaction.actionPhase?.totalFees ?? BigInt.zero,
        gasFee: r.transaction.computePhase?.gasFees ?? BigInt.zero,
        storageFee: r.transaction.storagePhase?.feesCollected ?? BigInt.zero,
        success: succes,
        network: network,
        resultDescription: error,
        internalMessages: messages.toList());
  }

  List<TonEmulatedMessage> emulateMessages(TraceResponse e) {
    final computePhase = e.transaction.computePhase?.success ?? true;
    final actionPhase = e.transaction.actionPhase?.success ?? true;
    final tx = e.transaction.success;

    final bool success = computePhase && actionPhase && tx;
    String? errorMessage;
    if (!success) {
      if (!computePhase) {
        errorMessage = e.transaction.computePhase?.exitCodeDescription ??
            e.transaction.computePhase?.exitCode?.toString();
      } else if (!actionPhase) {
        errorMessage = e.transaction.actionPhase?.resultCodeDescription;
      }
    }
    final msg = TonEmulatedMessage(
        destination: e.transaction.inMsg?.destination?.address,
        actionPhase: e.transaction.actionPhase?.fwdFees ?? BigInt.zero,
        gasFee: e.transaction.computePhase?.gasFees ?? BigInt.zero,
        storageFee: e.transaction.storagePhase?.feesCollected ?? BigInt.zero,
        success: success,
        resultDescription: errorMessage,
        network: network);
    return [msg, ...e.children.expand((e) => emulateMessages(e))];
  }
}
