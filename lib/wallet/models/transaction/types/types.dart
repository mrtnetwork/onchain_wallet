import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/networks/types/address.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/others/models/receipt_address.dart';
import 'package:on_chain_wallet/wallet/models/transaction/core/transaction.dart';

abstract class TransferOutputDetails<NETWORKADDRESS extends IAddress>
    with DisposableMixin, StreamStateController, Equality {
  final IntegerBalance amount;
  final bool recipientUpdateble;
  ReceiptAddress<NETWORKADDRESS> _recipient;
  ReceiptAddress<NETWORKADDRESS> get recipient => _recipient;
  bool get hasAmount => amount.largerThanZero;
  bool get isReady => hasAmount;
  TransferOutputDetails({
    required this.amount,
    required ReceiptAddress<NETWORKADDRESS> recipient,
    this.recipientUpdateble = false,
  }) : _recipient = recipient;

  void updateBalance(BigInt amount) {
    assert(!amount.isNegative, "Invalid transfer amount.");
    if (amount.isNegative) return;
    this.amount.updateBalance(amount);
    notify();
  }

  void updateRecipientAddress(ReceiptAddress<NETWORKADDRESS> address) {
    assert(recipientUpdateble);
    if (!recipientUpdateble) return;
    _recipient = address;
    notify();
  }

  @override
  List get variables => [_recipient];
}

class TrackTransactionRequest<T extends ChainTransaction, A extends ChainAccount> {
  final List<T> transactions;
  final A account;
  TrackTransactionRequest({required List<T> transactions, required this.account})
      : transactions = transactions.immutable;
}
