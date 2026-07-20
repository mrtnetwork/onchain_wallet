import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/stellar/transaction/widgets/stellar_operations/operations.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:stellar_dart/stellar_dart.dart';

import 'types.dart';

abstract class StellarTransactionOperation {
  Operation toOperation();
  BigInt get value;
  OperationType get type;
  StellarPickedIssueAsset? get asset;

  StellarWalletTransactionOutput toWalletTransactionOutput(WalletStellarNetwork network);
}

class StellarChangeTrustOperation implements StellarTransactionOperation {
  @override
  final StellarPickedIssueAsset asset;
  final IntegerBalance limit;

  StellarChangeTrustOperation({required this.asset, required IntegerBalance limit})
      : limit = IntegerBalance.token(limit.balance, limit.token, immutable: true);

  @override
  Operation<OperationBody> toOperation() {
    return Operation(
        body: ChangeTrustOperation(asset: asset.asset, limit: limit.balance));
  }

  @override
  BigInt get value => BigInt.zero;

  @override
  OperationType get type => OperationType.changeTrust;

  @override
  StellarWalletTransactionOutput toWalletTransactionOutput(WalletStellarNetwork network) {
    return StellarWalletTransactionOperationOutput(name: type.name);
  }
}

class StellarPaymentOperation implements StellarTransactionOperation {
  @override
  final StellarPickedIssueAsset asset;
  final ReceiptAddress<StellarAddress> destination;
  final IntegerBalance amount;

  bool get isNative => asset.asset.type.isNative;

  StellarPaymentOperation({
    required this.asset,
    required this.destination,
    required IntegerBalance amount,
  }) : amount = IntegerBalance.token(amount.balance, amount.token, immutable: true);
  @override
  Operation<OperationBody> toOperation() {
    return Operation(
        body: PaymentOperation(
            asset: asset.asset,
            amount: amount.balance,
            destination: destination.networkAddress.toMuxedAccount()));
  }

  @override
  BigInt get value => amount.balance;
  @override
  OperationType get type => OperationType.payment;

  @override
  StellarWalletTransactionOutput toWalletTransactionOutput(WalletStellarNetwork network) {
    return StellarWalletTransactionTransferOutput(
        to: destination.networkAddress,
        amount: WalletTransactionIntegerAmount(
            amount: value,
            network: network,
            token: isNative ? null : asset.token,
            tokenIdentifier: isNative ? null : asset.issuer));
  }
}

class StellarPathPaymentStrictReceiveOperation implements StellarTransactionOperation {
  @override
  final StellarPickedIssueAsset asset;
  final IntegerBalance sendAmount;
  final StellarPickedIssueAsset destAsset;
  final IntegerBalance destAmount;
  final ReceiptAddress<StellarAddress> destination;
  final List<StellarPickedIssueAsset> paths;

  bool get isNative => asset.asset.type.isNative;

  StellarPathPaymentStrictReceiveOperation({
    required this.asset,
    required this.destination,
    required IntegerBalance sendAmount,
    required this.destAsset,
    List<StellarPickedIssueAsset> paths = const [],
    required IntegerBalance destAmount,
  })  : sendAmount =
            IntegerBalance.token(sendAmount.balance, sendAmount.token, immutable: true),
        destAmount =
            IntegerBalance.token(destAmount.balance, destAmount.token, immutable: true),
        paths = paths.immutable;
  @override
  Operation<OperationBody> toOperation() {
    return Operation(
      body: PathPaymentStrictReceiveOperation(
          destAmount: destAmount.balance,
          destAsset: destAsset.asset,
          sendAsset: asset.asset,
          sendMax: sendAmount.balance,
          path: paths.map((e) => e.asset).toList(),
          destination: destination.networkAddress.toMuxedAccount()),
    );
  }

  @override
  BigInt get value => sendAmount.balance;
  @override
  OperationType get type => OperationType.pathPaymentStrictReceive;

  @override
  StellarWalletTransactionOutput toWalletTransactionOutput(WalletStellarNetwork network) {
    return StellarWalletTransactionOperationOutput(name: type.name);
  }
}

class StellarPathPaymentStrictSendOperation implements StellarTransactionOperation {
  @override
  final StellarPickedIssueAsset asset;
  final IntegerBalance sendAmount;
  final StellarPickedIssueAsset destAsset;
  final IntegerBalance destMin;
  final ReceiptAddress<StellarAddress> destination;
  final List<StellarPickedIssueAsset> paths;
  bool get isNative => asset.asset.type.isNative;

  StellarPathPaymentStrictSendOperation({
    required this.asset,
    required this.destination,
    required IntegerBalance sendAmount,
    required this.destAsset,
    List<StellarPickedIssueAsset> paths = const [],
    required IntegerBalance destMin,
  })  : sendAmount =
            IntegerBalance.token(sendAmount.balance, sendAmount.token, immutable: true),
        destMin = IntegerBalance.token(destMin.balance, destMin.token, immutable: true),
        paths = paths.immutable;
  @override
  Operation<OperationBody> toOperation() {
    return Operation(
      body: PathPaymentStrictSendOperation(
          destMin: destMin.balance,
          destAsset: destAsset.asset,
          sendAsset: asset.asset,
          sendAmount: sendAmount.balance,
          path: paths.map((e) => e.asset).toList(),
          destination: destination.networkAddress.toMuxedAccount()),
    );
  }

  @override
  BigInt get value => sendAmount.balance;
  @override
  OperationType get type => OperationType.pathPaymentStrictSend;
  @override
  StellarWalletTransactionOutput toWalletTransactionOutput(WalletStellarNetwork network) {
    return StellarWalletTransactionOperationOutput(name: type.name);
  }
}

class StellarCreateAccountOperation implements StellarTransactionOperation {
  @override
  final StellarPickedIssueAsset asset;
  final ReceiptAddress<StellarAddress> destination;
  final IntegerBalance startingBalance;

  bool get isNative => asset.asset.type.isNative;

  StellarCreateAccountOperation({
    required this.asset,
    required this.destination,
    required IntegerBalance startingBalance,
  }) : startingBalance = IntegerBalance.token(
            startingBalance.balance, startingBalance.token,
            immutable: true);
  @override
  Operation<OperationBody> toOperation() {
    return Operation(
        body: CreateAccountOperation(
            startingBalance: startingBalance.balance,
            destination: destination.networkAddress.toPublicKey()));
  }

  @override
  BigInt get value => startingBalance.balance;
  @override
  OperationType get type => OperationType.createAccount;

  @override
  StellarWalletTransactionOutput toWalletTransactionOutput(WalletStellarNetwork network) {
    return StellarWalletTransactionTransferOutput(
        to: destination.networkAddress,
        amount: WalletTransactionIntegerAmount(amount: value, network: network));
  }
}

class StellarManageSellOfferOperation implements StellarTransactionOperation {
  @override
  final StellarPickedIssueAsset asset;
  final IntegerBalance amount;
  final StellarPickedIssueAsset buying;
  final StellarPrice price;
  late final String priceView = price.toPrice();
  final BigInt offerId;

  bool get isNative => asset.asset.type.isNative;

  StellarManageSellOfferOperation({
    required this.asset,
    required this.buying,
    required IntegerBalance amount,
    required this.offerId,
    required this.price,
  }) : amount = IntegerBalance.token(amount.balance, amount.token, immutable: true);
  @override
  Operation<OperationBody> toOperation() {
    return Operation(
      body: ManageSellOfferOperation(
          amount: amount.balance,
          buying: buying.asset,
          selling: asset.asset,
          offerId: offerId,
          price: price),
    );
  }

  @override
  BigInt get value => amount.balance;
  @override
  OperationType get type => OperationType.manageSellOffer;

  bool get isByOffer => type == OperationType.manageBuyOffer;
  @override
  StellarWalletTransactionOutput toWalletTransactionOutput(WalletStellarNetwork network) {
    return StellarWalletTransactionOperationOutput(name: type.name);
  }
}

class StellarManageBuyOfferOperation extends StellarManageSellOfferOperation {
  StellarManageBuyOfferOperation({
    required super.asset,
    required super.buying,
    required super.amount,
    required super.offerId,
    required super.price,
    required this.value,
  });

  @override
  Operation<OperationBody> toOperation() {
    return Operation(
      body: ManageBuyOfferOperation(
          buyAmount: amount.balance,
          buying: buying.asset,
          selling: asset.asset,
          offerId: offerId,
          price: price),
    );
  }

  @override
  final BigInt value;
  @override
  OperationType get type => OperationType.manageBuyOffer;
}

class StellarTransactionOperationDetails {
  final StellarTransactionOperation? operationInfo;
  final Map<String, dynamic> operationContent;
  final String operationContentStr;
  final Operation<OperationBody> operation;
  final ReceiptAddress<StellarAddress>? sourceAccount;

  OperationLevel get level => operation.body.level;
  const StellarTransactionOperationDetails._(
      {required this.operationInfo,
      required this.operationContent,
      required this.operationContentStr,
      required this.operation,
      this.sourceAccount});
  factory StellarTransactionOperationDetails(
      {required Operation<OperationBody> operation,
      StellarTransactionOperation? operationInfo,
      ReceiptAddress<StellarAddress>? sourceAccount}) {
    final content = operation.body.toJson().immutable;
    return StellarTransactionOperationDetails._(
        operation: operation,
        operationContent: content,
        operationContentStr:
            StringUtils.fromJson(content, indent: '  ', toStringEncodable: true),
        operationInfo: operationInfo,
        sourceAccount: sourceAccount);
  }
}

abstract class StellarTransactionOperationForm {
  StellarTransactionOperation toOperation();
  BigInt get value;
  List<LiveFormField<Object?, Object?>> get fields;
  final StellarTransactionStateController controller;
  final OperationType type;
  StellarTransactionOperationForm({required this.controller, required this.type});

  final StreamValue<TransactionStateStatus> status = StreamValue(
      TransactionStateStatus.error(),
      name: "StellarTransactionOperationForm");

  TransactionStateStatus getStateStatus() {
    for (final i in fields) {
      if (!i.complete) return TransactionStateStatus.error();
    }
    for (final i in fields) {
      final error = i.validate;
      if (error != null) return TransactionStateStatus.error(error: error);
    }
    return TransactionStateStatus.ready();
  }

  Widget builder(BuildContext context);
  factory StellarTransactionOperationForm.create(
      {required StellarTransactionStateController controller,
      required OperationType type}) {
    return switch (type) {
      OperationType.changeTrust =>
        StellarChangeTrustOperationForm(controller: controller),
      OperationType.payment => StellarPaymentOperationForm(controller: controller),
      OperationType.pathPaymentStrictReceive =>
        StellarPathPaymentStrictReceiveOperationForm(controller: controller),
      OperationType.pathPaymentStrictSend =>
        StellarPathPaymentStrictSendOperationForm(controller: controller),
      OperationType.createAccount =>
        StellarCreateAccountOperationForm(controller: controller),
      OperationType.manageSellOffer =>
        StellarManageSellOfferOperationForm(controller: controller),
      OperationType.manageBuyOffer =>
        StellarManageBuyOfferOperationForm(controller: controller),
      _ => throw UnsupportedError("${type.name} not supported.")
    };
  }

  void dispose() {
    for (final i in fields) {
      i.dispose();
    }
    status.dispose();
  }

  void onStateUpdated() {
    status.value = getStateStatus();
  }
}

class StellarPaymentOperationForm extends StellarTransactionOperationForm {
  StellarPaymentOperationForm({required super.controller})
      : super(type: OperationType.payment);
  BigInt _getMaxInput() {
    final asset = this.asset.value;
    if (asset == null) return BigInt.zero;
    if (asset.asset.type.isNative) {
      final total =
          controller.operations.value.fold(BigInt.zero, (p, c) => p + c.operation.value);
      final balance = controller.address.addressData.currencyBalance;
      return balance - total - controller.txFee.fee.fee.balance;
    }
    final tokenBalance = asset.tokenBalance;
    if (tokenBalance == null) {
      return StellarConst.maxIssueAmount;
    }
    final payments = controller.operations.value
        .map((e) => e.operation)
        .whereType<StellarPaymentOperation>()
        .where((e) => e.asset.asset == asset.asset);
    final total = payments.fold(BigInt.zero, (p, c) => p + c.amount.balance);
    final remain = tokenBalance.balance - total;
    return remain;
  }

  BigInt getMaxInput() {
    final remain = _getMaxInput();
    if (remain.isNegative) return BigInt.zero;
    return remain;
  }

  final LiveFormField<StellarPickedIssueAsset?, StellarPickedIssueAsset> asset =
      LiveFormField(
    title: "asset".tr,
    subtitle: "select_stellar_payment_assets_desc".tr,
    value: null,
  );
  final LiveFormField<TransactionResourceRequirementStellarAccountActivity?,
          TransactionResourceRequirementStellarAccountActivity> recipient =
      LiveFormField(title: "recipient".tr, value: null);

  late final LiveFormField<IntegerBalance, IntegerBalance> amount = LiveFormField(
    title: "transfer_amount".tr,
    value: IntegerBalance.zero(controller.network.token),
    onValidateError: (field, value) {
      if (value.largerThanZero) return null;
      return "field_is_required".tr.replaceOne(field.title);
    },
  );

  void onUpdateAmount(BigInt amount) {
    this.amount.value.updateBalance(amount);
    this.amount.notify();
    onStateUpdated();
  }

  void onUpdateAsset(StellarPickedIssueAsset? asset) {
    if (asset == null || asset.asset == this.asset.value?.asset) return;
    amount.setValue(IntegerBalance.zero(asset.token, allowNegative: false));
    this.asset.setValue(asset);
    onStateUpdated();
  }

  void onUpdateRecipient(ReceiptAddress<StellarAddress>? recipient) {
    if (recipient == null ||
        recipient.networkAddress == this.recipient.value?.address.networkAddress) {
      return;
    }
    final currentDestination = this.recipient.value;
    final destination = TransactionResourceRequirementStellarAccountActivity(recipient);
    this.recipient.setValue(destination);
    controller.trackAccountActivity(destination);
    currentDestination?.dispose();
    onStateUpdated();
  }

  @override
  StellarTransactionOperation toOperation() {
    return StellarPaymentOperation(
        asset: asset.output,
        destination: recipient.output.address,
        amount: amount.output);
  }

  String? _checkTrustPathLimit(
      {required StellarPickedIssueAsset asset,
      required TransactionResourceRequirementStellarAccountActivity destination,
      required BigInt amount}) {
    if (asset.asset.type.isNative) {
      return null;
    }
    if (destination.status.isPending || destination.status.isError) {
      return null;
    }
    final receiverAsset = destination.value?.getAsset(asset.asset);
    if (receiverAsset == null) return "stellar_destination_lacks_trust_path".tr;
    final limit = receiverAsset.limitAsBigint() - receiverAsset.unlockedBalance;
    if (limit < amount) return "stellar_asset_trust_path_limit_exceeded".tr;
    return null;
  }

  @override
  BigInt get value => amount.value.balance;

  StellarWalletTransactionOutput toWalletTransactionOutput(WalletStellarNetwork network) {
    final asset = this.asset.output;
    final isNative = asset.asset.type.isNative;
    return StellarWalletTransactionTransferOutput(
        to: recipient.value!.address.networkAddress,
        amount: WalletTransactionIntegerAmount(
            amount: value,
            network: network,
            token: isNative ? null : asset.token,
            tokenIdentifier: isNative ? null : asset.issuer));
  }

  @override
  TransactionStateStatus getStateStatus() {
    final state = super.getStateStatus();
    if (!state.isReady) return state;
    final recipient = this.recipient.output;
    if (recipient.status.isInactive) {
      return TransactionStateStatus.error(error: "stellar_account_inactive_desc".tr);
    }
    final remain = _getMaxInput();
    if (remain.isNegative) {
      return TransactionStateStatus.insufficient(
          IntegerBalance.token(remain, asset.output.token));
    }
    final pathError = _checkTrustPathLimit(
        asset: asset.output, destination: recipient, amount: amount.output.balance);
    if (pathError != null) {
      return TransactionStateStatus.error(error: pathError);
    }

    return TransactionStateStatus.ready();
  }

  @override
  Widget builder(BuildContext context) {
    return StellarTransactionPaymentWidget(form: this);
  }

  @override
  List<LiveFormField<Object?, Object?>> get fields => [asset, recipient, amount];

  @override
  void dispose() {
    recipient.value?.dispose();
    super.dispose();
  }
}

class StellarChangeTrustOperationForm extends StellarTransactionOperationForm {
  StellarChangeTrustOperationForm({required super.controller})
      : super(type: OperationType.changeTrust);
  BigInt getMaxInput() => StellarConst.maxIssueAmount;

  final LiveFormField<StellarPickedIssueAsset?, StellarPickedIssueAsset> asset =
      LiveFormField(
          title: "asset".tr,
          subtitle: "modify_trust_line_desc".tr,
          optional: false,
          value: null);

  late final LiveFormField<IntegerBalance, IntegerBalance> limit = LiveFormField(
    title: "limit".tr,
    subtitle: "change_trust_limit".tr,
    optional: false,
    value: IntegerBalance.zero(controller.network.token, allowNegative: false),
    onValidateError: (field, value) {
      if (value.token == controller.network.token) {
        return "field_filled_incorrectly".tr.replaceOne(field.title);
      }
      return null;
    },
  );

  void onUpdateAsset(StellarPickedIssueAsset? asset) {
    if (asset == null ||
        asset.asset.type.isNative ||
        asset.asset == this.asset.value?.asset) {
      return;
    }
    this.asset.setValue(asset);
    limit.setValue(IntegerBalance.zero(asset.token, allowNegative: false));
    onStateUpdated();
  }

  void onUpdateLimit(BigInt amount) {
    if (amount > getMaxInput()) return;
    limit.output.updateBalance(amount);
    limit.notify();
    onStateUpdated();
  }

  @override
  StellarChangeTrustOperation toOperation() {
    return StellarChangeTrustOperation(asset: asset.output, limit: limit.output);
  }

  @override
  BigInt get value => BigInt.zero;

  StellarWalletTransactionOutput toWalletTransactionOutput(WalletStellarNetwork network) {
    return StellarWalletTransactionOperationOutput(name: type.name);
  }

  @override
  List<LiveFormField<Object?, Object?>> get fields => [asset, limit];

  @override
  Widget builder(BuildContext context) {
    return StellarTransactionChangeTrustOperationWidget(form: this);
  }
}

class StellarPathPaymentStrictReceiveOperationForm
    extends StellarTransactionOperationForm {
  StellarPathPaymentStrictReceiveOperationForm({required super.controller})
      : super(type: OperationType.pathPaymentStrictReceive);
  bool get allowAddPaths => paths.value.length < 5;
  final LiveFormField<StellarPickedIssueAsset?, StellarPickedIssueAsset> asset =
      LiveFormField(
          title: "send_asset".tr,
          subtitle: "stellar_path_receive_send_asset_desc".tr,
          optional: false,
          value: null);

  late final LiveFormField<IntegerBalance, IntegerBalance> sendMax = LiveFormField(
    title: "send_max".tr,
    subtitle: "stellar_path_receive_send_max_desc".tr,
    value: IntegerBalance.zero(controller.network.token, allowNegative: false),
    onValidateError: (field, value) {
      if (value.largerThanZero) return null;
      return "field_is_required".tr.replaceOne(field.title);
    },
  );

  final LiveFormField<StellarPickedIssueAsset?, StellarPickedIssueAsset> destAsset =
      LiveFormField(
    title: "destination_asset".tr,
    subtitle: "stellar_path_receive_dest_asset_desc".tr,
    optional: false,
    value: null,
  );

  final LiveFormField<TransactionResourceRequirementStellarAccountActivity?,
      TransactionResourceRequirementStellarAccountActivity> destination = LiveFormField(
    title: "destination".tr,
    subtitle: "stellar_path_receive_destination_desc".tr,
    optional: false,
    value: null,
  );

  late final LiveFormField<IntegerBalance, IntegerBalance> destAmount = LiveFormField(
    title: "destination_amount".tr,
    subtitle: "stellar_path_receive_dest_amount_desc".tr,
    value: IntegerBalance.zero(controller.network.token, allowNegative: false),
    onValidateError: (field, value) {
      if (value.largerThanZero) return null;
      return "field_is_required".tr.replaceOne(field.title);
    },
  );

  final LiveFormFields<StellarPickedIssueAsset> paths = LiveFormFields(
      title: "path".tr,
      subtitle: "stellar_path_receive_path_desc".tr,
      optional: true,
      maxLength: 5);

  void onUpdatePath(StellarPickedIssueAsset? path, {DynamicVoid? onPathExists}) {
    if (path == null) return;
    final exists = paths.value.any((e) => e.asset == path.asset);
    if (exists) {
      if (onPathExists != null) onPathExists();
      return;
    }

    paths.addValue(path);
    onStateUpdated();
  }

  void onRemovePath(StellarPickedIssueAsset path) {
    paths.removeValue(path);
    onStateUpdated();
  }

  void onUpdateDestAmount(BigInt amount) {
    destAmount.value.updateBalance(amount);
    destAmount.notify();
    onStateUpdated();
  }

  void onUpdateDestination(ReceiptAddress<StellarAddress>? address) {
    if (address == null ||
        address.networkAddress == this.destination.value?.address.networkAddress) {
      return;
    }
    this.destination.value?.dispose();
    final destination = TransactionResourceRequirementStellarAccountActivity(address);
    this.destination.setValue(destination);
    controller.trackAccountActivity(destination);
    onStateUpdated();
  }

  void onUpdateAsset(StellarPickedIssueAsset? asset) {
    if (asset == null || asset.asset == this.asset.value?.asset) return;
    sendMax.setValue(IntegerBalance.zero(asset.token, allowNegative: false));
    this.asset.setValue(asset);
    destAsset.setValue(null);
    onStateUpdated();
  }

  void onUpdateSendMax(BigInt amount) {
    sendMax.value.updateBalance(amount);
    sendMax.notify();
    onStateUpdated();
  }

  void onUpdateDestAsset(StellarPickedIssueAsset? asset) {
    if (asset == null || asset.asset == destAsset.value?.asset) return;
    destAmount.setValue(IntegerBalance.zero(asset.token, allowNegative: false));
    destAsset.setValue(asset);
    onStateUpdated();
  }

  @override
  StellarTransactionOperation toOperation() {
    return StellarPathPaymentStrictReceiveOperation(
        asset: asset.output,
        destination: destination.output.address,
        sendAmount: sendMax.output,
        destAsset: destAsset.output,
        destAmount: destAmount.output);
  }

  @override
  BigInt get value => sendMax.value.balance;

  StellarWalletTransactionOutput toWalletTransactionOutput(WalletStellarNetwork network) {
    return StellarWalletTransactionOperationOutput(name: type.name);
  }

  @override
  List<LiveFormField<Object?, Object?>> get fields =>
      [asset, sendMax, destAsset, destination, destAmount, paths];

  @override
  Widget builder(BuildContext context) {
    return StellarTransactionPathPaymentStrictReceiveWidget(form: this);
  }
}

class StellarPathPaymentStrictSendOperationForm extends StellarTransactionOperationForm {
  bool get allowAddPaths => paths.value.length < 5;

  StellarPathPaymentStrictSendOperationForm({required super.controller})
      : super(type: OperationType.pathPaymentStrictSend);
  final LiveFormField<StellarPickedIssueAsset?, StellarPickedIssueAsset> sendAsset =
      LiveFormField(
    title: "send_asset".tr,
    subtitle: "stellar_path_send_send_asset_desc".tr,
    value: null,
  );
  late final LiveFormField<IntegerBalance, IntegerBalance> sendAmount = LiveFormField(
    title: "send_amount".tr,
    subtitle: "stellar_path_receive_send_amount_desc".tr,
    value: IntegerBalance.zero(controller.network.token, allowNegative: false),
    onValidateError: (field, value) {
      if (value.largerThanZero) return null;
      return "field_is_required".tr.replaceOne(field.title);
    },
  );
  final LiveFormField<StellarPickedIssueAsset?, StellarPickedIssueAsset> destAsset =
      LiveFormField(
          title: "destination_asset".tr,
          subtitle: "stellar_path_send_dest_asset_desc".tr,
          value: null);

  late final LiveFormField<IntegerBalance, IntegerBalance> destMin = LiveFormField(
    title: "minimum_destination_amount".tr,
    subtitle: "stellar_path_send_dest_min_desc".tr,
    value: IntegerBalance.zero(controller.network.token, allowNegative: false),
    onValidateError: (field, value) {
      if (value.largerThanZero) return null;
      return "field_is_required".tr.replaceOne(field.title);
    },
  );
  final LiveFormField<TransactionResourceRequirementStellarAccountActivity?,
          TransactionResourceRequirementStellarAccountActivity> destination =
      LiveFormField(
          title: "destination".tr,
          subtitle: "stellar_path_send_destination_desc".tr,
          value: null);
  final LiveFormFields<StellarPickedIssueAsset> paths = LiveFormFields(
      title: "path".tr,
      subtitle: "stellar_path_send_path_desc".tr,
      optional: true,
      maxLength: 5);
  void onUpdatePath(StellarPickedIssueAsset? path, {DynamicVoid? onPathExists}) {
    if (path == null) return;
    final exists = paths.value.any((e) => e.asset == path.asset);
    if (exists) {
      if (onPathExists != null) onPathExists();
      return;
    }
    paths.addValue(path);
    onStateUpdated();
  }

  void onRemovePath(StellarPickedIssueAsset path) {
    paths.removeValue(path);
  }

  void onUpdateDestination(ReceiptAddress<StellarAddress>? address) {
    if (address == null ||
        address.networkAddress == this.destination.value?.address.networkAddress) {
      return;
    }
    this.destination.value?.dispose();
    final destination = TransactionResourceRequirementStellarAccountActivity(address);
    this.destination.setValue(destination);
    controller.trackAccountActivity(destination);
    onStateUpdated();
  }

  void onUpdateDestAsset(StellarPickedIssueAsset? asset) {
    if (asset == null || asset.asset == destAsset.value?.asset) return;
    destMin.setValue(IntegerBalance.zero(asset.token, allowNegative: false));
    destAsset.setValue(asset);
    onStateUpdated();
  }

  void onUpdateSendAsset(StellarPickedIssueAsset? asset) {
    if (asset == null || asset.asset == sendAsset.value?.asset) return;
    sendAmount.setValue(IntegerBalance.zero(asset.token, allowNegative: false));
    sendAsset.setValue(asset);
    destAsset.setValue(null);
    onStateUpdated();
  }

  void onUpdateDestMin(BigInt amount) {
    destMin.value.updateBalance(amount);
    destMin.notify();
    onStateUpdated();
  }

  void onUpdateSendAmount(BigInt amount) {
    sendAmount.value.updateBalance(amount);
    sendAmount.notify();
    onStateUpdated();
  }

  @override
  StellarTransactionOperation toOperation() {
    return StellarPathPaymentStrictSendOperation(
        asset: sendAsset.output,
        destination: destination.output.address,
        sendAmount: sendAmount.output,
        destAsset: destAsset.output,
        destMin: destMin.output);
  }

  @override
  BigInt get value => sendAmount.value.balance;
  @override
  OperationType get type => OperationType.pathPaymentStrictSend;
  StellarWalletTransactionOutput toWalletTransactionOutput(WalletStellarNetwork network) {
    return StellarWalletTransactionOperationOutput(name: type.name);
  }

  @override
  List<LiveFormField<Object?, Object?>> get fields =>
      [sendAsset, sendAmount, destAsset, destination, paths];

  @override
  Widget builder(BuildContext context) {
    return StellarTransactionPathPaymentStrictSendWidget(form: this);
  }
}

class StellarCreateAccountOperationForm extends StellarTransactionOperationForm {
  StellarCreateAccountOperationForm({required super.controller})
      : super(type: OperationType.createAccount);
  BigInt getMinInput() {
    return controller.noneActiveAccountRequiredAmount.balance;
  }

  BigInt getMaxInput() {
    return controller.address.addressData.currencyBalance;
  }

  late final LiveFormField<IntegerBalance, IntegerBalance> startingBalance =
      LiveFormField(
    title: "starting_balance".tr,
    subtitle: "stellar_create_account_starting_balance_desc".tr,
    value: IntegerBalance.zero(controller.network.token),
    onValidateError: (f, current) {
      if (current.balance < controller.noneActiveAccountRequiredAmount.balance) {
        return "stellar_starting_balance_desc"
            .tr
            .replaceOne(controller.noneActiveAccountRequiredAmount.price);
      }
      return null;
    },
  );

  final LiveFormField<TransactionResourceRequirementStellarAccountActivity?,
      TransactionResourceRequirementStellarAccountActivity> destination = LiveFormField(
    title: "recipient".tr,
    optional: false,
    value: null,
    onValidateError: (field, value) {
      if (value == null) return null;
      if (value.status.isActive) {
        return "account_is_active".tr;
      }
      return null;
    },
  );

  void onUpdateStartingBalance(BigInt amount) {
    startingBalance.value.updateBalance(amount);
    startingBalance.notify();
    onStateUpdated();
  }

  void onUpdateDestination(ReceiptAddress<StellarAddress>? address) {
    if (address == null ||
        address.networkAddress == this.destination.value?.address.networkAddress) {
      return;
    }
    this.destination.value?.dispose();
    final destination = TransactionResourceRequirementStellarAccountActivity(address);
    this.destination.setValue(destination);
    controller.trackAccountActivity(destination);
    onStateUpdated();
  }

  @override
  StellarTransactionOperation toOperation() {
    return StellarCreateAccountOperation(
        asset: StellarPickedIssueAsset(
            asset: StellarAssetNative(), network: controller.network, issueToken: null),
        destination: destination.output.address,
        startingBalance: startingBalance.output);
  }

  @override
  BigInt get value => startingBalance.value.balance;
  @override
  OperationType get type => OperationType.createAccount;

  StellarWalletTransactionOutput toWalletTransactionOutput(WalletStellarNetwork network) {
    return StellarWalletTransactionTransferOutput(
        to: destination.output.address.networkAddress,
        amount: WalletTransactionIntegerAmount(amount: value, network: network));
  }

  @override
  List<LiveFormField<Object?, Object?>> get fields => [startingBalance, destination];

  @override
  Widget builder(BuildContext context) {
    return StellarTransactionCreateAccountOperationWidget(form: this);
  }
}

class StellarManageSellOfferOperationForm extends StellarTransactionOperationForm {
  String? _priceMessage;
  String? get priceMessage => _priceMessage;
  StellarManageSellOfferOperationForm({required super.controller})
      : super(type: OperationType.manageSellOffer);
  final LiveFormField<StellarPickedIssueAsset?, StellarPickedIssueAsset> selling =
      LiveFormField(
    title: "selling".tr,
    subtitle: "stellar_manage_sell_offer_selling".tr,
    optional: false,
    value: null,
  );

  late final LiveFormField<IntegerBalance, IntegerBalance> amount = LiveFormField(
    title: "amount".tr,
    subtitle: "stellar_manage_sell_offer_amount".tr,
    value: IntegerBalance.zero(controller.network.token, allowNegative: false),
  );

  late final LiveFormField<StellarPickedIssueAsset?, StellarPickedIssueAsset> buying =
      LiveFormField(
    title: "buying".tr,
    subtitle: "stellar_manage_sell_offer_buying".tr,
    optional: false,
    value: null,
    onValidateError: (field, value) {
      if (value != null && value.asset == selling.value?.asset) {
        return "different_selling_from_buying_validator_desc".tr;
      }
      return null;
    },
  );

  final LiveFormField<BigRational?, BigRational> price = LiveFormField(
      title: "price".tr, subtitle: "stellar_manage_sell_offer_price".tr, value: null);

  final LiveFormField<BigInt?, BigInt> offerId = LiveFormField(
      title: "offer_id".tr,
      subtitle: "stellar_manage_sell_offer_offer_id".tr,
      value: BigInt.zero);
  void onUpdateOfferId(BigRational? offerId) {
    if (offerId == null || offerId.isDecimal || offerId.isNegative) return;
    this.offerId.setValue(offerId.toBigInt());
    onStateUpdated();
  }

  void onUpdateSelling(StellarPickedIssueAsset? asset) {
    if (asset == null || asset.asset == selling.value?.asset) return;
    selling.setValue(asset);
    amount.setValue(IntegerBalance.token(BigInt.zero, asset.token, allowNegative: true));
    price.setValue(null);
    onStateUpdated();
  }

  void onUpdateAmount(BigInt amount) {
    this.amount.output.updateBalance(amount);
    this.amount.notify();
    onStateUpdated();
  }

  void onUpdateBuying(StellarPickedIssueAsset? asset) {
    if (asset == null || asset.asset == buying.value?.asset) return;
    buying.setValue(asset);
    price.setValue(null);
    onStateUpdated();
  }

  void onUpdatePrice(BigRational? price) {
    if (price == null) return;
    _priceMessage = "exchange_entred_price_buy_desc"
        .tr
        .replaceOne(
            PriceUtils.priceWithCoinName(price.toDecimal(), buying.output.token.symbol))
        .replaceTwo(selling.output.token.symbol);
    this.price.setValue(price);
    onStateUpdated();
  }

  @override
  StellarTransactionOperation toOperation() {
    return StellarManageSellOfferOperation(
        asset: selling.output,
        buying: buying.output,
        amount: amount.output,
        offerId: offerId.output,
        price: StellarPrice.fromDecimal(price.output.toDecimal()));
  }

  @override
  BigInt get value => amount.value.balance;
  @override
  OperationType get type => OperationType.manageSellOffer;

  bool get isByOffer => type == OperationType.manageBuyOffer;

  StellarWalletTransactionOutput toWalletTransactionOutput(WalletStellarNetwork network) {
    return StellarWalletTransactionOperationOutput(name: type.name);
  }

  @override
  TransactionStateStatus getStateStatus() {
    final status = super.getStateStatus();
    if (!status.isReady) return status;
    if (selling.output.asset == buying.output.asset) {
      return TransactionStateStatus.error(
          error: "different_selling_from_buying_validator_desc".tr);
    }
    return TransactionStateStatus.ready();
  }

  @override
  List<LiveFormField<Object?, Object?>> get fields =>
      [selling, amount, buying, price, offerId];

  @override
  Widget builder(BuildContext context) {
    return StellarTransactionManageSellOfferWidget(form: this);
  }
}

class StellarManageBuyOfferOperationForm extends StellarTransactionOperationForm {
  StellarManageBuyOfferOperationForm({required super.controller})
      : super(type: OperationType.manageBuyOffer);
  String? _priceMessage;
  String? get priceMessage => _priceMessage;
  final LiveFormField<StellarPickedIssueAsset?, StellarPickedIssueAsset> selling =
      LiveFormField(
    title: "selling".tr,
    subtitle: "stellar_manage_buy_offer_selling".tr,
    optional: false,
    value: null,
  );

  late final LiveFormField<IntegerBalance, IntegerBalance> amount = LiveFormField(
    title: "amount".tr,
    subtitle: "stellar_manage_buy_offer_buy_amount".tr,
    value: IntegerBalance.zero(controller.network.token, allowNegative: false),
  );

  final LiveFormField<StellarPickedIssueAsset?, StellarPickedIssueAsset> buying =
      LiveFormField(
    title: "buying".tr,
    subtitle: "stellar_manage_buy_offer_buying".tr,
    optional: false,
    value: null,
  );

  final LiveFormField<BigRational?, BigRational> price = LiveFormField(
      title: "price".tr, subtitle: "stellar_manage_buy_offer_price".tr, value: null);

  final LiveFormField<BigInt?, BigInt> offerId = LiveFormField(
    title: "offer_id".tr,
    subtitle: "stellar_manage_sell_offer_offer_id".tr,
    value: BigInt.zero,
  );
  void onUpdateOfferId(BigRational? offerId) {
    if (offerId == null || offerId.isDecimal || offerId.isNegative) return;
    this.offerId.setValue(offerId.toBigInt());
    onStateUpdated();
  }

  void onUpdateSelling(StellarPickedIssueAsset? asset) {
    if (asset == null) return;
    selling.setValue(asset);
    _priceMessage = null;
    price.setValue(null);
    onStateUpdated();
  }

  void onUpdateBuying(StellarPickedIssueAsset? asset) {
    if (asset == null || asset.asset == buying.value?.asset) return;
    amount.setValue(IntegerBalance.token(BigInt.zero, asset.token, allowNegative: false));
    buying.setValue(asset);
    _priceMessage = null;
    price.setValue(null);
    onStateUpdated();
  }

  void onUpdateAmount(BigInt amount) {
    this.amount.output.updateBalance(amount);
    this.amount.notify();
    onStateUpdated();
  }

  void onUpdatePrice(BigRational? price) {
    if (price == null) return;
    _priceMessage = "exchange_entred_price_buy_desc"
        .tr
        .replaceOne(
            PriceUtils.priceWithCoinName(price.toDecimal(), selling.output.token.symbol))
        .replaceTwo(buying.output.token.symbol);
    this.price.setValue(price);
    onStateUpdated();
  }

  @override
  StellarTransactionOperation toOperation() {
    return StellarManageBuyOfferOperation(
        asset: selling.output,
        buying: buying.output,
        amount: amount.output,
        offerId: offerId.output,
        price: StellarPrice.fromDecimal(price.output.toDecimal()),
        value: value);
  }

  @override
  OperationType get type => OperationType.manageBuyOffer;

  @override
  BigInt get value => amount.value.balance;

  @override
  List<LiveFormField<Object?, Object?>> get fields =>
      [selling, amount, buying, price, offerId];
  @override
  TransactionStateStatus getStateStatus() {
    final status = super.getStateStatus();
    if (!status.isReady) return status;
    if (selling.output.asset == buying.output.asset) {
      return TransactionStateStatus.error(
          error: "different_selling_from_buying_validator_desc".tr);
    }
    return TransactionStateStatus.ready();
  }

  @override
  Widget builder(BuildContext context) {
    return StellarTransactionManageBuyOfferWidget(form: this);
  }
}

class TransactionResourceRequirementStellarAccountActivity
    with DisposableMixin, StreamStateController {
  final lock = SafeAtomicLock();
  final ReceiptAddress<StellarAddress> address;
  TransactionResourceRequirementStellarAccountActivity(this.address);
  AccountReceivementStatus _status = AccountReceivementStatus.idle;
  AccountReceivementStatus get status => _status;
  StellarAccountResponse? _value;
  StellarAccountResponse? get value => _value;

  void setResource(StellarAccountResponse? value) {
    assert(_status == AccountReceivementStatus.pending);
    _value = value;
    _status = value != null
        ? AccountReceivementStatus.active
        : AccountReceivementStatus.inactive;
    notify();
  }

  void setError({String? error}) {
    assert(_status == AccountReceivementStatus.pending);
    _status = AccountReceivementStatus.error;
    notify();
  }

  void setPendig() {
    assert(_status.canTry);
    _status = AccountReceivementStatus.pending;
    notify();
  }
}
