import 'package:blockchain_utils/utils/atomic/atomic.dart';
import 'package:flutter/material.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/transaction/widgets/mint_to.dart';
import 'package:on_chain_wallet/future/wallet/transaction/core/controller.dart';
import 'package:on_chain_wallet/future/wallet/transaction/fields/fields.dart';
import 'package:on_chain_wallet/future/wallet/transaction/types/types.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class SolanaTransactionMintToOperation extends SolanaTransactionStateController {
  final _lock = SafeAtomicLock();
  final Cancelable _cancelable = Cancelable();
  SolanaTransactionMintToOperation(
      {required super.walletProvider, required super.account, required super.address});

  final LiveFormField<ReceiptAddress<SolAddress>, ReceiptAddress<SolAddress>> programId =
      LiveFormField(
          title: "program_id".tr,
          subtitle: "solana_program_id_desc".tr,
          value: ReceiptAddress<SolAddress>(
              view: SPLTokenProgramConst.tokenProgramId.address,
              type: null,
              networkAddress: SPLTokenProgramConst.tokenProgramId),
          optional: false);
  final LiveFormField<TransactionResourceRequirementMintAccount?,
      TransactionResourceRequirementMintAccount> mint = LiveFormField(
    title: "mint".tr,
    subtitle: "mint_address_mint_desc".tr,
    optional: false,
    value: null,
    onValidateError: (field, value) {
      if (value?.status.isSuccess ?? false) {
        return null;
      }
      return "mint_account_not_found".tr;
    },
  );
  final LiveFormField<ReceiptAddress<SolAddress>?, ReceiptAddress<SolAddress>> authority =
      LiveFormField(
    title: "authority".tr,
    value: null,
    optional: false,
    subtitle: "mint_to_authority_desc".tr,
  );
  final LiveFormField<ReceiptAddress<SolAddress>?, ReceiptAddress<SolAddress>>
      destination = LiveFormField(
          title: "destination".tr,
          subtitle: "use_owner_account_instead_pda_desc".tr,
          value: null);
  late final LiveFormField<IntegerBalance, IntegerBalance> amount = LiveFormField(
    title: "amount".tr,
    subtitle: "mint_to_amount_desc".tr,
    value: IntegerBalance.zero(network.token),
    onValidateError: (field, value) {
      if (value.largerThanZero) return null;
      return "field_is_required".tr.replaceOne(field.title.tr);
    },
  );

  Future<void> getMintTokenData() async {
    _cancelable.cancel();
    final value = mint.value;
    if (value == null) return;
    await _lock.run(() async {
      if (value.status.isSuccess) return;
      mint.setValue(TransactionResourceRequirementMintAccount(
          value: value.value, status: TransactionResourceRequirementFetchStatus.pending));
      final mintAccountData = await IResult.call(() async {
        return getMintAccount(value.value.networkAddress);
      }, cancelable: _cancelable);
      if (mintAccountData.err()?.canceled() ?? false) return;
      if (mintAccountData.isErr || mintAccountData.ok() == null) {
        mint.setValue(TransactionResourceRequirementMintAccount(
            value: value.value,
            status: TransactionResourceRequirementFetchStatus.failed,
            error:
                mintAccountData.err()?.localizationError ?? "mint_account_not_found".tr));
        return;
      }
      final mintAccount = mintAccountData.unwrap()!;
      mint.setValue(TransactionResourceRequirementMintAccount(
          value: value.value,
          token: Token(
              name: mintAccount.address.address,
              symbol: mintAccount.address.address,
              decimal: mintAccount.decimals),
          status: TransactionResourceRequirementFetchStatus.success));
      estimateFee();
    });
  }

  void onUpdateProgramId(ReceiptAddress<SolAddress>? address) {
    if (address == null) return;
    programId.setValue(address);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateMint(ReceiptAddress<SolAddress> address) {
    mint.setValue(TransactionResourceRequirementMintAccount(
        value: address, status: TransactionResourceRequirementFetchStatus.pending));
    getMintTokenData();
    onUpdateAmount(BigInt.zero);
  }

  void onUpdateAuthority(ReceiptAddress<SolAddress>? address) {
    authority.setValue(address);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateDestination(ReceiptAddress<SolAddress>? address) {
    if (address == null) return;
    destination.setValue(address);
    onStateUpdated();
    estimateFee();
  }

  void onUpdateAmount(BigInt amount) {
    final token = mint.value?.token;
    if (token == null) return;
    this.amount.setValue(IntegerBalance.token(amount, token));
    onStateUpdated();
    estimateFee();
  }

  @override
  Future<ISolanaTransactionData> buildTransactionData({bool simulate = false}) async {
    final blockhash = await getTransactionBlockHash(simulate: simulate);
    final pda = AssociatedTokenAccountProgramUtils.associatedTokenAccount(
        mint: mint.value!.value.networkAddress, owner: destination.value!.networkAddress);
    final mintTo = SPLTokenProgram.mintTo(
        layout: SPLTokenMintToLayout(amount: amount.value.balance),
        mint: mint.value!.value.networkAddress,
        destination: pda.address,
        authority: authority.value!.networkAddress);
    final info = await getAccountInfo(pda.address);
    AssociatedTokenAccountProgram? associatedTokenAccountProgram;
    if (info == null) {
      associatedTokenAccountProgram =
          AssociatedTokenAccountProgram.associatedTokenAccount(
              payer: address.networkAddress,
              associatedToken: pda.address,
              owner: destination.value!.networkAddress,
              mint: mint.value!.value.networkAddress,
              tokenProgramId: programId.value.networkAddress);
    }
    return ISolanaTransactionData(
        fee: txFee.fee,
        memo: memo.value,
        instructions: [
          if (associatedTokenAccountProgram != null) associatedTokenAccountProgram,
          mintTo,
        ],
        blockHash: blockhash);
  }

  @override
  Future<TransactionStateController> cloneController(ISolanaAddress address) async {
    return SolanaTransactionMintToOperation(
        walletProvider: walletProvider, account: account, address: address);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return SolanaTransactionMintToWidget(form: this);
  }

  @override
  TransactionOperations get operation => SolanaTransactionOperations.mintTo;

  @override
  List<LiveFormField<Object?, Object>> get fields =>
      [programId, mint, authority, destination, amount];

  @override
  void dispose() {
    _cancelable.cancel();
    super.dispose();
  }
}
