import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/router/page_router.dart';
import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/transaction.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

class RippleNFTokenView extends StatelessWidget {
  const RippleNFTokenView(
      {required this.nft, required this.address, required this.account, super.key});
  final RippleNFToken nft;
  final IXRPAddress address;
  final XRPChain account;
  @override
  Widget build(BuildContext context) {
    return ContainerWithBorder(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("nfts_id".tr, style: context.onPrimaryTextTheme.titleMedium),
          WidgetConstant.height8,
          ContainerWithBorder(
            backgroundColor: context.onPrimaryContainer,
            child:
                CopyableTextWidget(text: nft.nftokenId, color: context.primaryContainer),
          ),
          if (nft.uri != null) ...[
            Text("uri".tr, style: context.onPrimaryTextTheme.titleMedium),
            WidgetConstant.height8,
            ContainerWithBorder(
              backgroundColor: context.onPrimaryContainer,
              child: CopyableTextWidget(
                  text: nft.uri ?? "", color: context.primaryContainer),
            ),
          ],
          Divider(color: context.onPrimaryContainer),
          ContainerWithBorder(
            backgroundColor: context.colors.onPrimaryContainer,
            onRemoveIcon: Icon(
              Icons.open_in_new,
              color: context.colors.primaryContainer,
            ),
            onRemove: () {
              final operation = RippleTransactionNFTokenBurnOperation(
                  address: account.addressSync,
                  account: account,
                  walletProvider: context.wallet,
                  nftId: nft.nftokenId);
              context.to(PageRouter.transaction, argruments: operation);
            },
            child: Text("NFTokenBurn", style: context.primaryTextTheme.bodyMedium),
          ),
          ContainerWithBorder(
            backgroundColor: context.colors.onPrimaryContainer,
            onRemoveIcon: Icon(
              Icons.open_in_new,
              color: context.colors.primaryContainer,
            ),
            onRemove: () {
              final feild = RippleTransactionNFTokenCreateOfferOperation(
                  address: account.addressSync,
                  account: account,
                  walletProvider: context.wallet,
                  nftId: nft.nftokenId);
              context.to(PageRouter.transaction, argruments: feild);
            },
            child: Text("NFTokenCreateOffer", style: context.primaryTextTheme.bodyMedium),
          ),
          ContainerWithBorder(
            backgroundColor: context.colors.onPrimaryContainer,
            onRemoveIcon: Icon(
              Icons.open_in_new,
              color: context.colors.primaryContainer,
            ),
            onRemove: () {
              final feild = RippleTransactionNFTokenCancelOfferOperation(
                  address: address,
                  account: account,
                  walletProvider: context.wallet,
                  nftId: nft.nftokenId);
              context.to(PageRouter.transaction, argruments: feild);
            },
            child: Text("NFTokenCancelOffer", style: context.primaryTextTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
