import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/transaction/widgets/initialize_mint.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';

class SolanaTransactionInitializeMintOperation
    extends SolanaTransactionStateController {
  SolanaTransactionInitializeMintOperation(
      {required super.walletProvider,
      required super.account,
      required super.address});

  final LiveFormField<ReceiptAddress<SolAddress>, ReceiptAddress<SolAddress>>
      programId = LiveFormField(
          title: "program_id".tr,
          subtitle: "solana_program_id_desc".tr,
          value: ReceiptAddress<SolAddress>(
              view: SPLTokenProgramConst.tokenProgramId.address,
              type: null,
              networkAddress: SPLTokenProgramConst.tokenProgramId),
          optional: false);
  final LiveFormField<ReceiptAddress<SolAddress>?, ReceiptAddress<SolAddress>>
      mint = LiveFormField(
          title: "mint".tr,
          subtitle: "mint_address_to_initialize".tr,
          optional: false,
          value: null);
  final LiveFormField<ReceiptAddress<SolAddress>?, ReceiptAddress<SolAddress>>
      mintAuthority = LiveFormField(
    title: "mint_authority".tr,
    value: null,
    optional: false,
    subtitle: "mint_authority_desc".tr,
  );
  final LiveFormField<BigRational?, BigRational> decimals = LiveFormField(
      title: "decimals".tr,
      subtitle: "solana_mint_decimal_desc".tr,
      optional: false,
      onUpdateValue: (previous, current) {
        if (current != null &&
            (current.isNegative ||
                current > SolanaConst.maxSPLTokenDecimalPlaces)) {
          return false;
        }
        return true;
      },
      value: null);

  final LiveFormField<ReceiptAddress<SolAddress>?, ReceiptAddress<SolAddress>>
      freezAuthority = LiveFormField(
          title: "freeze_authority".tr,
          subtitle: "freeze_authority_desc".tr,
          value: null,
          optional: true);

  void onUpdateProgramId(ReceiptAddress<SolAddress>? address) {
    if (address == null) return;
    programId.setValue(address);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateMint(ReceiptAddress<SolAddress>? address) {
    if (address == null) return;
    mint.setValue(address);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateMintAuthority(ReceiptAddress<SolAddress>? address) {
    if (address == null) return;
    mintAuthority.setValue(address);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateFreezeAuthority(ReceiptAddress<SolAddress>? address) {
    freezAuthority.setValue(address);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateDecimals(BigRational decimals) {
    this.decimals.setValue(decimals);
    onStateUpdated();
    estimateFee();
  }

  @override
  Future<ISolanaTransactionData> buildTransactionData(
      {bool simulate = false}) async {
    final blockhash = await getTransactionBlockHash(simulate: simulate);
    return ISolanaTransactionData(
        fee: txFee.fee,
        memo: memo.value,
        instructions: [
          SPLTokenProgram.initializeMint2(
              layout: SPLTokenInitializeMint2Layout(
                  decimals: decimals.value!.toBigInt().toInt(),
                  mintAuthority: mintAuthority.value!.networkAddress,
                  freezeAuthority: freezAuthority.value?.networkAddress),
              mint: mint.value!.networkAddress,
              programId: programId.value.networkAddress)
        ],
        blockHash: blockhash);
  }

  @override
  Future<TransactionStateController> cloneController(
      ISolanaAddress address) async {
    return SolanaTransactionInitializeMintOperation(
        walletProvider: walletProvider, account: account, address: address);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return SolanaTransactionInitializeMintWidget(form: this);
  }

  @override
  TransactionOperations get operation =>
      SolanaTransactionOperations.initializeMint;

  @override
  List<LiveFormField<Object?, Object>> get fields => [
        programId,
        mint,
        mintAuthority,
        decimals,
        freezAuthority,
      ];
}
