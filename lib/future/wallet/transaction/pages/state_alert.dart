import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';

class TransactionStateAlert extends StatelessWidget {
  final StreamValue<TransactionStateStatus?> status;
  const TransactionStateAlert({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return APPStreamBuilder(
        value: status,
        builder: (context, value) => ErrorTextContainer(error: value?.error));
  }
}
