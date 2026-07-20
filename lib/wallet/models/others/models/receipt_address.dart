import 'package:blockchain_utils/networks/types/address.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/contact/contact.dart';

class ReceiptAddress<NETWORKADDRESS extends IAddress> with Equality {
  ReceiptAddress(
      {required this.view,
      this.type,
      this.contact,
      this.account,
      required this.networkAddress});
  final NetworkContact<NETWORKADDRESS>? contact;
  final ACCOUNTADDRESS<NETWORKADDRESS>? account;
  final NETWORKADDRESS networkAddress;
  final String view;
  final String? type;
  bool get hasContact => contact != null;
  bool get isAccount => account != null;

  ReceiptAddress<NETWORKADDRESS> copyWith({
    String? view,
    NETWORKADDRESS? networkAddress,
    NetworkContact<NETWORKADDRESS>? contact,
    ACCOUNTADDRESS<NETWORKADDRESS>? account,
    String? type,
  }) {
    return ReceiptAddress(
        view: view ?? this.view,
        networkAddress: networkAddress ?? this.networkAddress,
        account: account ?? this.account,
        contact: contact ?? this.contact,
        type: type ?? this.type);
  }

  @override
  List get variables => [view];

  @override
  String toString() {
    return view;
  }
}
