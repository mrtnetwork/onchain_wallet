import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain_swap/on_chain_swap.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/networks/ripple/ripple.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/controllers/provider.dart';
import 'package:on_chain_wallet/wallet/api/api.dart';
import 'package:on_chain_wallet/wallet/chain/chain/chain.dart';
import 'package:xrpl_dart/xrpl_dart.dart';

class XRPSwapClinet extends BaseSwapXRPClient
    with DisposableMixin, XRPTransactionApiController {
  @override
  final XRPNetworkClient client;
  final List<IXRPAddress> addresses;
  final XRPChain account;
  XRPSwapClinet({required this.client, required this.account, required this.addresses});

  @override
  Future<BigInt> getAccountBalance(XRPBaseAddress address) {
    return client.getAccountBalance(address);
  }

  @override
  Future<BigInt?> getBlockHeight() async {
    return null;
  }

  @override
  Future<bool> initSwapClient() {
    return client.initSwapClient();
  }

  @override
  Future<SubmittableTransaction> simulateTransactionFee(
      SubmittableTransaction transaction) async {
    final fee = await client.getFeeData();

    final source = XRPBaseAddress(transaction.account);
    final account = addresses.firstWhere(
      (e) => e.networkAddress == source,
      orElse: () => throw WalletExceptionConst.accountDoesNotFound,
    );
    int multiSigner = 0;
    if (account.multiSigAccount) {
      final IXRPMultisigAddress multiSigAddress = account as IXRPMultisigAddress;
      if (!multiSigAddress.multiSignatureAccount.isRegular) {
        multiSigner = multiSigAddress.multiSignatureAccount.signers.length;
      }
    }
    String? fillment;
    if (transaction case EscrowFinish(:var fulfillment)) {
      fillment = fulfillment;
    }
    final f = RippleUtils.calculateFee(
        fee.getFeeType(type: XrplFeeType.open), transaction.transactionType,
        fulfillment: fillment, multiSigners: multiSigner);
    transaction.setFee(f);
    final result = await client.simulateTx(transaction);
    if (!result.isSuccess) {
      throw APIError.fromException(message: RPCError(message: result.engineResult));
    }
    return transaction;
  }

  @override
  bool get closed => false;
}
