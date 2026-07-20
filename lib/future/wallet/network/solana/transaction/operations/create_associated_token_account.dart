import 'package:flutter/material.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/transaction/controllers/controller.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/solana/transaction/widgets/create_associated_token_account.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/future/wallet/transaction/transaction.dart';

class SolanaTransactionCreateAssociatedTokenAccountOperation
    extends SolanaTransactionStateController {
  SolanaTransactionCreateAssociatedTokenAccountOperation(
      {required super.walletProvider,
      required super.account,
      required super.address});

  final LiveFormField<ReceiptAddress<SolAddress>?, ReceiptAddress<SolAddress>>
      ownerAddress = LiveFormField(
    title: "owner_address".tr,
    subtitle: "owner_of_account".tr,
    optional: false,
    value: null,
  );
  final LiveFormField<ReceiptAddress<SolAddress>?, ReceiptAddress<SolAddress>>
      mintAddress = LiveFormField(
          title: "mint_address".tr,
          subtitle: "mint_address_desc".tr,
          optional: false,
          value: null);
  final LiveFormField<ReceiptAddress<SolAddress>, ReceiptAddress<SolAddress>>
      tokenProgram = LiveFormField(
          subtitle: "program_address_desc".tr,
          title: "program_address".tr,
          optional: false,
          value: ReceiptAddress<SolAddress>(
              view: SPLTokenProgramConst.tokenProgramId.address,
              type: null,
              networkAddress: SPLTokenProgramConst.tokenProgramId));

  final LiveFormField<ReceiptAddress<SolAddress>?, ReceiptAddress<SolAddress>>
      assosicatedAddress =
      LiveFormField(title: "associated_token_address".tr, value: null);

  void onUpdateMintAddress(ReceiptAddress<SolAddress>? address) {
    if (address == null) return;
    mintAddress.setValue(address);
    _onFieldsReady();
  }

  void onUpdateOwnerAddress(ReceiptAddress<SolAddress>? address) {
    if (address == null) return;
    ownerAddress.setValue(address);
    _onFieldsReady();
  }

  void onUpdateTokenProgramAddress(ReceiptAddress<SolAddress>? address) {
    if (address == null) return;
    tokenProgram.setValue(address);
    _onFieldsReady();
  }

  void _onFieldsReady() {
    final mint = mintAddress.value?.networkAddress;
    final owner = ownerAddress.value?.networkAddress;
    if (mint == null || owner == null) {
      assosicatedAddress.setValue(null);
    } else {
      final address = AssociatedTokenAccountProgramUtils.associatedTokenAccount(
              mint: mint,
              owner: owner,
              tokenProgramId: tokenProgram.value.networkAddress)
          .address;
      final addr =
          account.getOrCreateReceiptFromNetworkAddressSync(address: address);
      assosicatedAddress.setValue(addr);
    }
    onStateUpdated();
    estimateFee();
  }

  @override
  Future<TransactionStateController> cloneController(
      ISolanaAddress address) async {
    return SolanaTransactionCreateAssociatedTokenAccountOperation(
        walletProvider: walletProvider, account: account, address: address);
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return SolanaTransactionCreateAssociatedTokenAccountWidget(form: this);
  }

  @override
  Future<ISolanaTransactionData> buildTransactionData(
      {bool simulate = false}) async {
    final blockhash = await getTransactionBlockHash(simulate: simulate);
    return ISolanaTransactionData(
        fee: txFee.fee,
        memo: memo.value,
        instructions: [
          AssociatedTokenAccountProgram.associatedTokenAccount(
              payer: address.networkAddress,
              tokenProgramId: tokenProgram.value.networkAddress,
              associatedToken:
                  AssociatedTokenAccountProgramUtils.associatedTokenAccount(
                          mint: mintAddress.value!.networkAddress,
                          owner: ownerAddress.value!.networkAddress,
                          tokenProgramId: tokenProgram.value.networkAddress)
                      .address,
              owner: ownerAddress.value!.networkAddress,
              mint: mintAddress.value!.networkAddress)
        ],
        blockHash: blockhash);
  }

  @override
  List<LiveFormField<Object?, Object>> get fields =>
      [ownerAddress, mintAddress, tokenProgram, assosicatedAddress];

  @override
  TransactionOperations get operation =>
      SolanaTransactionOperations.createAssociatedTokenAccount;
}
