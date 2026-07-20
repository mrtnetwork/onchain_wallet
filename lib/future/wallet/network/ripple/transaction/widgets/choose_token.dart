import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/wallet/network/ripple/transaction/types/types.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:xrpl_dart/xrpl_dart.dart';

class RipplePickToken extends StatefulWidget {
  final String? title;
  final XRPChain account;
  final IXRPAddress address;
  final CachedObject<List<RippleIssueToken>>? tokens;
  final bool allowNative;
  final bool allowCreate;
  final ScrollController controller;
  const RipplePickToken({
    required this.account,
    required this.address,
    required this.controller,
    this.title,
    this.allowNative = true,
    this.allowCreate = false,
    this.tokens,
    super.key,
  });

  @override
  State<RipplePickToken> createState() => _RipplePickTokenState();
}

class _RipplePickTokenState extends State<RipplePickToken>
    with SafeState<RipplePickToken> {
  final pageKey =
      StreamPageProgressController(initialStatus: PageProgressStatus.progress);
  bool hasToken = true;
  List<RippleIssueToken> tokens = [];

  void onPickNativeToken() {
    final asset = RipplePickedAsset.xrp();
    context.pop(asset);
  }

  void onPickAccountToken(RippleIssueToken token) {
    if (token.issuer == widget.address.networkAddress.classicAddress) {
      final asset = RipplePickedAsset.create(token);
      context.pop(asset);
      return;
    }
    final asset = RipplePickedAsset.account(token);
    context.pop(asset);
  }

  Future<void> onCreateToken() async {
    final RipplePickedAsset? token =
        await context.openMaxExtendSliverBottomSheet<RipplePickedAsset>(
      "choose_payment_currency".tr,
      bodyBuilder: (controller) =>
          CreateRippleTokenView(account: widget.account, controller: controller),
    );
    if (token == null) return;
    context.pop(token);
  }

  Future<void> getAccountTokens() async {
    final result = await IResult.block(() async {
      final cachedTokens = widget.tokens;
      if (cachedTokens != null) {
        final result = await cachedTokens.get(onFetch: () async {
          final client = await widget.account.client();
          return client.unwrap().accountTokens(widget.address);
        });
        return ResultOk(result);
      }
      final client = await widget.account.client();
      return client.mapAsync((client) async {
        return client.accountTokens(widget.address);
      });
    });
    result.watch(
      onErr: (error) => pageKey.errorText(error.localizationError, backToIdle: false),
      onOk: (tokens) {
        this.tokens = tokens;
        hasToken = widget.allowNative || tokens.isNotEmpty;
        pageKey.backToIdle();
      },
    );
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    getAccountTokens();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? "pick_token".tr),
        actions: [
          ConditionalWidget(
              enable: widget.allowCreate,
              onActive: (context) =>
                  IconButton(onPressed: onCreateToken, icon: Icon(Icons.add_box)))
        ],
      ),
      body: StreamPageProgress(
        controller: pageKey,
        initialWidget:
            ProgressWithTextView(text: "fetching_account_token_please_wait".tr),
        builder: (context) => CustomScrollView(controller: widget.controller, slivers: [
          EmptyItemSliverWidgetView(
              isEmpty: !hasToken,
              itemBuilder: (context) => SliverConstraintsBoxView(
                    padding: WidgetConstant.paddingHorizontal20,
                    sliver: MultiSliver(children: [
                      ConditionalWidget(
                          enable: widget.allowNative,
                          onActive: (context) => Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ContainerWithBorder(
                                      onRemove: onPickNativeToken,
                                      onRemoveIcon: WidgetConstant.sizedBox,
                                      child: AccountTokenDetailsWidget(
                                        token: widget
                                            .address.addressData.balance.value.token,
                                        liveBalance: widget.address.addressData.balance,
                                      ),
                                    )
                                  ])),
                      SliverList.separated(
                          itemCount: tokens.length,
                          itemBuilder: (context, index) {
                            final token = tokens[index];
                            return AccountTokenDetailsView(
                                token: token,
                                onSelect: () => onPickAccountToken(token),
                                onSelectIcon: WidgetConstant.sizedBox);
                          },
                          separatorBuilder: (context, index) => WidgetConstant.sizedBox)
                    ]),
                  ),
              icon: Icons.token),
        ]),
      ),
    );
  }
}

class CreateRippleTokenView extends StatefulWidget {
  final ScrollController controller;
  final XRPChain account;
  const CreateRippleTokenView(
      {required this.controller, required this.account, super.key});

  @override
  State<CreateRippleTokenView> createState() => _CreateRippleTokenViewState();
}

class _CreateRippleTokenViewState extends State<CreateRippleTokenView>
    with SafeState<CreateRippleTokenView> {
  ReceiptAddress<XRPBaseAddress>? issuer;
  String? currency;
  bool isReady = false;

  void onSelectIssuer(ReceiptAddress<XRPBaseAddress>? issue) {
    issuer = issue;
    _isReady();
  }

  void setCurrency(String? newCurrency) {
    currency = newCurrency;
    _isReady();
  }

  void _isReady() {
    isReady = issuer != null && currency != null;
    updateState();
  }

  void onSetupCreate() {
    final issuer = this.issuer?.networkAddress;
    final currency = this.currency;
    if (!isReady || issuer == null || currency == null) return;
    context.pop(RipplePickedAsset.create(RippleIssueToken.create(
        balance: '0',
        token: NonDecimalToken(name: currency, symbol: currency),
        issuer: issuer.classicAddress,
        assetCode: currency)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("create_token".tr),
      ),
      body: CustomScrollView(
        controller: widget.controller,
        slivers: [
          SliverConstraintsBoxView(
            padding: WidgetConstant.paddingHorizontal20,
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WidgetConstant.height20,
                  PageTitleSubtitle(
                      title: "create_token".tr, body: Text("xrp_create_token_desc".tr)),
                  ReceiptAddressView(
                    address: issuer,
                    title: "issuer",
                    subtitle: "token_issuer".tr,
                    onTap: () {
                      context
                          .selectAccount<XRPBaseAddress>(
                              account: widget.account, title: "issuer".tr)
                          .then((value) => onSelectIssuer(value?.firstOrNull));
                    },
                  ),
                  WidgetConstant.height20,
                  Text("currency".tr, style: context.textTheme.titleMedium),
                  Text("token_currency".tr),
                  WidgetConstant.height8,
                  ContainerWithBorder(
                    onRemove: () {
                      context
                          .openSliverBottomSheet<String>(
                            "token_amount".tr,
                            child: StringWriterView(
                              defaultValue: currency,
                              regExp: RippleConst.currencyCodeRegex,
                              minLines: 1,
                              title: PageTitleSubtitle(
                                  title: "currency".tr,
                                  body: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("token_currency".tr),
                                    ],
                                  )),
                              buttonText: "setup_input".tr,
                              label: "currency".tr,
                            ),
                          )
                          .then(setCurrency);
                    },
                    onRemoveIcon: currency != null
                        ? const Icon(Icons.edit)
                        : const Icon(Icons.add_box),
                    validate: currency != null,
                    child: Text(currency ?? "tap_to_enter_currency_code".tr),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FixedElevatedButton(
                        padding: WidgetConstant.paddingVertical40,
                        onPressed: isReady ? onSetupCreate : null,
                        child: Text("setup_currency_amount".tr),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
