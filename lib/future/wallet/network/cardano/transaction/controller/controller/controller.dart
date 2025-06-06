import 'package:on_chain_wallet/future/wallet/network/cardano/transaction/controller/impl/certificate_impl.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/transaction/controller/impl/fee_impl.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/transaction/controller/impl/memo_impl.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/transaction/controller/impl/minting_impl.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/transaction/controller/impl/signer_impl.dart';
import 'package:on_chain_wallet/future/wallet/network/cardano/transaction/controller/impl/transaction.dart';

class CardanoTransactionStateController extends CardanoTransactionImpl
    with
        CardanoTransactionFeeImpl,
        CardanoSignerImpl,
        CardanoTransactionMemoImpl,
        CardanoMintingImpl,
        CardanoCertificateImpl {
  CardanoTransactionStateController({
    required super.walletProvider,
    required super.account,
    required super.apiProvider,
  });

  @override
  void buildAndBroadcastTransaction() {
    if (!trReady) return;
    super.buildAndBroadcastTransaction();
  }
}
