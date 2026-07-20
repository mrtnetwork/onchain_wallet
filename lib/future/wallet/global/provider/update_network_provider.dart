import 'package:blockchain_utils/networks/types/address.dart';
import 'package:blockchain_utils/service/models/params.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/api/types/types.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';

mixin UpdateNetworkProviderState<
    W extends StatefulWidget,
    NETWORKADDRESS extends IAddress,
    ADDRESS extends ACCOUNTADDRESS<NETWORKADDRESS>,
    CL extends NetworkClient,
    T extends TokenCore,
    N extends NFTCore,
    CHAIN extends APPCHAIN> on SafeState<W> {
  final StreamPageProgressController progressKey =
      StreamPageProgressController(initialStatus: StreamWidgetStatus.progress);
  ProviderAuthenticated? authentication;
  late final List<APIProviderServices> services;
  late APIProviderServices service;
  String? get serviceDescription => null;
  CHAIN get chain;
  WalletNetwork get network => chain.network;
  List<ShimmerAction<DefaultAPIProvider>> providers = [];
  List<ServiceProtocol> supportedProtocol = [];
  String? protocolTitle;
  String? protocolHint;
  ServiceProtocol? protocol;
  ServiceUrlInfo? uriData;
  String rpcUrl = "";
  bool supportAuthentication = false;
  final GlobalKey<FormState> formKey = GlobalKey();
  final GlobalKey<AppTextFieldState> uriFieldKey = GlobalKey();
  bool supportTorService = false;

  void onChangeService(APIProviderServices? service) {
    if (service == null || !services.contains(service)) return;
    this.service = service;
    supportedProtocol = service.supportProtocols;
    supportTorService = context.wallet.supportTorConnection;
    authentication = null;
    protocol = null;
    uriData = null;
    supportAuthentication = false;
    protocolTitle = buildProtocolHelperTitle();
    protocolHint = buildProtocolHelperHint();
    uriFieldKey.currentState?.clear();
    updateState();
  }

  Future<DefaultAPIProvider> validate(DefaultAPIProvider provider);

  DefaultAPIProvider createProvider(
      {required String url,
      required ServiceProtocol protocol,
      required APIProviderServices service,
      ProviderAuthenticated? auth}) {
    return DefaultAPIProvider.create(
      url: url,
      auth: auth,
      service: service,
      network: network.type,
      protocol: protocol,
    );
  }

  void onPasteUri(String v) {
    uriFieldKey.currentState?.updateText(v);
  }

  void onChageUrl(String v) {
    rpcUrl = v;
    final urlDetails = uriData = APIUtils.getUrlDetails(v);
    if (urlDetails != null) {
      final newProtocol = detectSupportedProtocol(urlDetails);
      final protocol = this.protocol;
      if (newProtocol != protocol) {
        this.protocol = newProtocol;
        supportAuthentication = false;
        authentication = null;
        if (newProtocol != null) {
          final supportedAuth = ProviderAuthType.byProtocol(newProtocol);
          supportAuthentication = supportedAuth.isNotEmpty;
        }
        updateState();
      }
    }
  }

  Future<void> onChangeAuthenticated(bool? v) async {
    final protocol = this.protocol;
    final uriData = this.uriData;
    if (protocol == null || uriData == null) return;
    final result = await context
        .openMaxExtendSliverBottomSheet<(bool, ProviderAuthenticated?)>(
            "authenticated".tr,
            centerContent: false,
            slivers: [
          CreateProtocolAuthenticationView(
            protocol: protocol,
            url: uriData.url,
            authentication: authentication,
          )
        ]);
    if (result == null) return;
    authentication = result.$2;
    updateState();
  }

  String? validateKey(String? v) {
    if (v?.trim().isEmpty ?? true) {
      return "authenticated_key_validator".tr;
    }
    if (v!.length > APPConst.maximumHeaderValue) {
      return "value_is_to_large".tr;
    }
    return null;
  }

  String? validateValue(String? v) {
    if (v?.trim().isEmpty ?? true) {
      return "authenticated_value_validator".tr;
    }
    if (v!.length > APPConst.maximumHeaderValue) {
      return "value_is_to_large".tr;
    }
    return null;
  }

  void addProvider(DefaultAPIProvider provider) {
    providers.add(ShimmerAction(object: provider));
    rpcUrl = '';
    updateState();
  }

  bool canChangeProvider(DefaultAPIProvider provider) {
    return !provider.isDefaultProvider;
  }

  ServiceProtocol? detectSupportedProtocol(ServiceUrlInfo info) {
    for (final i in supportedProtocol) {
      if (info.protocols.contains(i)) {
        return i;
      }
    }
    return null;
  }

  String? validateRpcUrl(String? url) {
    if (url == null) return "invalid_protocol_url".tr;
    final uriData = this.uriData;
    if (uriData == null) {
      return "invalid_protocol_url".tr;
    }
    final protocol = this.protocol;
    if (protocol == null) {
      return "unsupported_protocol_by_selected_service".tr;
    }
    if (uriData.mode.isTor && !supportTorService) {
      return "tor_not_supported_on_this_platform".tr;
    }
    return null;
  }

  String buildProtocolHelperTitle() {
    bool hasHttp = supportedProtocol.contains(ServiceProtocol.http) ||
        supportedProtocol.contains(ServiceProtocol.grpc);
    bool hasRawSocket = supportedProtocol.contains(ServiceProtocol.ssl) ||
        supportedProtocol.contains(ServiceProtocol.tcp);
    bool hasWs = supportedProtocol.contains(ServiceProtocol.websocket);
    if (hasHttp && hasWs) {
      return "network_title_http_wss_url".tr;
    }
    if (hasWs && hasRawSocket) {
      return "network_title_socket_url".tr;
    }
    assert(hasHttp && (!hasRawSocket && !hasWs), "Unexpected service.");
    return "network_title_http_url".tr;
  }

  String buildProtocolHelperHint() {
    bool hasHttp = supportedProtocol.contains(ServiceProtocol.http) ||
        supportedProtocol.contains(ServiceProtocol.grpc);
    bool hasRawSocket = supportedProtocol.contains(ServiceProtocol.ssl) ||
        supportedProtocol.contains(ServiceProtocol.tcp);
    bool hasWs = supportedProtocol.contains(ServiceProtocol.websocket);

    if (hasHttp && hasWs) return "https://example.com:8080, wss://example.com:8443";
    if (hasWs && hasRawSocket) return "wss://example.com:8443, tls://example.com:9000";
    if (hasHttp) return "https://example.com:8080";
    if (hasWs) return "wss://example.com:8443";
    if (hasRawSocket) return "tls://example.com:9000";

    return "https://example.com:8080";
  }

  Future<void> deleteProvider(ShimmerAction<DefaultAPIProvider>? provider) async {
    if (provider == null || provider.object.isDefaultProvider) return;
    provider.setAction(true);
    updateState();
    final result = await chain.removeNetworkProvider(provider.object);
    result.watch(
      onErr: (error) => context.showAlert(error.localizationError),
      onOk: (_) {
        providers.remove(provider);
        provider.setAction(false);
        updateState();
      },
    );
  }

  Future<void> updateNetworkProviders() async {
    if (!formKey.ready()) return;
    progressKey.progressText("network_waiting_for_response".tr);
    final result = await IResult.call(() async {
      final info = uriData;
      if (info == null) {
        throw AppException("invalid_protocol_url");
      }
      final protocol = detectSupportedProtocol(info);
      if (protocol == null) {
        throw AppException("unsupported_protocol_by_selected_service");
      }
      if (info.mode.isTor && !supportTorService) {
        throw AppException("tor_not_supported_on_this_platform");
      }
      // final auth = createAuth();
      DefaultAPIProvider provider = createProvider(
          url: rpcUrl, service: service, auth: authentication, protocol: protocol);
      return validate(provider);
    });
    result.mapErr((e) {
      progressKey.errorText(e.localizationError, showBackButton: true, backToIdle: false);
      return e.exception;
    }).mapAsync(
      (provider) async {
        progressKey.progressText("updating_network".tr);
        final import = await chain.updateNetworkProvider(provider);
        import.watch(
          onErr: (error) => progressKey.errorText(error.localizationError,
              backToIdle: false, showBackButton: true),
          onOk: (_) {
            addProvider(provider);
            progressKey.successText("network_updated_successfully".tr);
          },
        );
      },
    );
  }

  Future<void> init() async {
    final providers = await chain.getProviders();
    providers.watch(
      onErr: (error) => progressKey.errorText(error.localizationError, backToIdle: false),
      onOk: (providers) {
        this.providers = providers.map((e) => ShimmerAction(object: e)).toList();
        APIProviderServices;
        services = APIProviderServices.byNetwork(chain.network.type);
        service = services.first;
        supportedProtocol = service.supportProtocols;
        supportTorService = context.wallet.supportTorConnection;
        protocolTitle = buildProtocolHelperTitle();
        protocolHint = buildProtocolHelperHint();
        progressKey.backToIdle();
      },
    );
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    init();
  }

  @override
  void safeDispose() {
    super.safeDispose();
    progressKey.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPageView(
      appBar: AppBar(title: Text("network_update_node_provider".tr)),
      child: StreamPageProgress(
        controller: progressKey,
        builder: (c) => UnfocusableChild(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: ConstraintsBoxView(
                    padding: WidgetConstant.padding20,
                    child: Form(
                      key: formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PageTitleSubtitle(
                              title: "securely_add_providers".tr,
                              body: LargeTextView([
                                "network_security_desc".tr,
                                "network_change_detect_desc".tr
                              ])),
                          Text("network".tr, style: context.textTheme.titleMedium),
                          WidgetConstant.height8,
                          ContainerWithBorder(
                              child: Text(
                            network.coinParam.token.name,
                            style: context.onPrimaryTextTheme.bodyMedium,
                          )),
                          AnimatedSize(
                              duration: APPConst.animationDuraion,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (providers.isNotEmpty) ...[
                                    WidgetConstant.height20,
                                    Text("providers".tr,
                                        style: context.textTheme.titleMedium),
                                    Text("available_network_providers".tr),
                                    WidgetConstant.height8,
                                    ...List.generate(providers.length, (index) {
                                      final action = providers[index];
                                      final provider = action.object;
                                      final bool isDefault = provider.isDefaultProvider;
                                      return Shimmer(
                                          onActive: (e, context) => ContainerWithBorder(
                                              onRemove: isDefault ? null : () {},
                                              enableTap: false,
                                              onRemoveWidget: IconButton(
                                                  onPressed: () {
                                                    deleteProvider(action);
                                                  },
                                                  icon: Icon(Icons.remove_circle,
                                                      color: context
                                                          .colors.onPrimaryContainer)),
                                              child: CopyableTextWidget(
                                                  text: provider.url,
                                                  widget: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Text(provider.protocol.value,
                                                          style: context
                                                              .onPrimaryTextTheme
                                                              .labelLarge),
                                                      Text(provider.url,
                                                          style: context
                                                              .onPrimaryTextTheme
                                                              .bodyMedium),
                                                    ],
                                                  ),
                                                  color:
                                                      context.colors.onPrimaryContainer)),
                                          enable: !action.action);
                                    }),
                                  ],
                                  WidgetConstant.height20,
                                  Text("service_provider".tr,
                                      style: context.textTheme.titleMedium),
                                  if (serviceDescription != null)
                                    Text(serviceDescription!),
                                  WidgetConstant.height8,
                                  AppDropDownBottomWithBorder(
                                      key: ValueKey(service),
                                      label: "service_provider".tr,
                                      isExpanded: true,
                                      items: {
                                        for (final i in services)
                                          i: Text(i.name,
                                              style:
                                                  context.onPrimaryTextTheme.bodyMedium)
                                      },
                                      selectedItemBuilder: {
                                        for (final i in services) i: Text(i.name)
                                      },
                                      labelStyle: context.onPrimaryTextTheme.labelLarge,
                                      value: service,
                                      onChanged: onChangeService),
                                  WidgetConstant.height20,
                                  Text("api_url".tr,
                                      style: context.textTheme.titleMedium),
                                  APPAnimated(
                                      onActive: (context) => ConditionalWidgetWithValue(
                                          key: ValueKey(protocolTitle),
                                          value: protocolTitle,
                                          onValue: (context, v) => Text(v))),
                                  WidgetConstant.height8,
                                  AppTextField(
                                      key: uriFieldKey,
                                      initialValue: rpcUrl,
                                      onChanged: onChageUrl,
                                      validator: validateRpcUrl,
                                      suffixIcon: PasteTextIcon(
                                        onPaste: onPasteUri,
                                        isSensitive: false,
                                      ),
                                      label: "api_url".tr,
                                      hint: protocolHint),
                                  DisabledWidget(
                                      ignoring: true,
                                      disabled: !supportAuthentication,
                                      onActive: (context, enable) => AppSwitchListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title: Text("authenticated".tr),
                                            subtitle:
                                                Text("add_provider_authenticated".tr),
                                            value: authentication != null,
                                            onChanged: onChangeAuthenticated,
                                          )),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      FixedElevatedButton(
                                        padding: WidgetConstant.paddingVertical40,
                                        onPressed: updateNetworkProviders,
                                        child: Text("import_provider".tr),
                                      ),
                                    ],
                                  )
                                ],
                              ))
                        ],
                      ),
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
typedef ONCHANGEAUTHMODE = void Function(ProviderAuthType? auth);

class CreateProtocolAuthenticationView extends StatefulWidget {
  final ServiceProtocol protocol;
  final String url;
  final ProviderAuthenticated? authentication;
  const CreateProtocolAuthenticationView(
      {required this.protocol,
      required this.url,
      super.key,
      required this.authentication});

  @override
  State<CreateProtocolAuthenticationView> createState() =>
      _CreateProtocolAuthenticationViewState();
}

class _CreateProtocolAuthenticationViewState
    extends State<CreateProtocolAuthenticationView>
    with SafeState<CreateProtocolAuthenticationView> {
  final formKey = GlobalKey<FormState>();
  ProviderAuthType auth = ProviderAuthType.header;
  List<ProviderAuthType> supportedAuths = [];
  bool authSupported = false;
  bool useAuthenticated = false;
  String keyLabel = "";
  String valueLabel = "";
  String? keyHint;
  String? valueHint;
  String authKey = "";
  String authValue = "";

  void onChangeAuthenticated(bool? v) {
    useAuthenticated = !useAuthenticated;

    updateState();
  }

  void onChangeAuthMode(ProviderAuthType? auth) {
    this.auth = auth ?? this.auth;
    updateLabes();
    updateState();
  }

  void onChangeKey(String v) {
    authKey = v;
  }

  void onChangeValue(String v) {
    authValue = v;
  }

  String? validateKey(String? v) {
    if (v?.trim().isEmpty ?? true) {
      return "authenticated_key_validator".tr;
    }
    if (v!.length > APPConst.maximumHeaderValue) {
      return "value_is_to_large".tr;
    }
    return null;
  }

  String? validateValue(String? v) {
    if (v?.trim().isEmpty ?? true) {
      return "authenticated_value_validator".tr;
    }
    if (v!.length > APPConst.maximumHeaderValue) {
      return "value_is_to_large".tr;
    }
    return null;
  }

  void updateLabes() {
    switch (auth) {
      case ProviderAuthType.header:
      case ProviderAuthType.query:
        keyLabel = "authenticated_key".tr;
        valueLabel = "authenticated_value".tr;
        keyHint = "example_value".tr.replaceOne(auth.isHeader
            ? APPConst.exampleAuthenticatedHeader
            : APPConst.exampleAuthenticatedQuery);
        valueHint = "example_value".tr.replaceOne(auth.isHeader
            ? APPConst.exampleAuthenticatedHeaderValue
            : APPConst.exampleBase58);
        break;
      case ProviderAuthType.digest:
        keyLabel = "username".tr;
        valueLabel = "password".tr;
        keyHint = "example_value".tr.replaceOne(auth.isHeader
            ? APPConst.exampleAuthenticatedHeader
            : APPConst.exampleAuthenticatedQuery);
        valueHint = "example_value".tr.replaceOne(auth.isHeader
            ? APPConst.exampleAuthenticatedHeaderValue
            : APPConst.exampleBase58);
        break;
    }
  }

  void updateAuth() {
    if (!formKey.ready()) return;

    if (useAuthenticated) {
      final type = this.auth;
      final key = authKey;
      final value = authValue;
      final auth = switch (type) {
        ProviderAuthType.header ||
        ProviderAuthType.query =>
          BasicProviderAuthenticated(key: key, value: value, type: type),
        ProviderAuthType.digest =>
          DigestProviderAuthenticated(password: value, username: key),
      };
      context.pop((true, auth));
      return;
    }
    context.pop((false, null));
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    supportedAuths = ProviderAuthType.byProtocol(widget.protocol);
    if (supportedAuths.isNotEmpty) {
      authSupported = true;
      this.auth = supportedAuths.first;
      final auth = widget.authentication;
      if (auth != null && supportedAuths.contains(auth.type)) {
        this.auth = auth.type;
        switch (auth) {
          case BasicProviderAuthenticated(:final key, :final value):
            authKey = key;
            authValue = value;
            break;
          case DigestProviderAuthenticated(:final username, :final password):
            authKey = username;
            authValue = password;
            break;
        }
        useAuthenticated = true;
      }
      updateLabes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return EmptyItemSliverWidgetView(
      isEmpty: !authSupported,
      onEmpty: (context) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, size: APPConst.largeIconSize),
            WidgetConstant.height8,
            Text("unsupported_authentication_by_protocol".tr)
          ],
        );
      },
      itemBuilder: (context) {
        return SliverConstraintsBoxView(
            padding: WidgetConstant.padding20,
            sliver: MultiSliver(children: [
              SliverToBoxAdapter(
                child: Form(
                  key: formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("provider_url".tr, style: context.textTheme.titleMedium),
                      WidgetConstant.height8,
                      CustomizedContainer(
                        child: Text(widget.url,
                            style: context.onPrimaryTextTheme.bodyMedium),
                      ),
                      WidgetConstant.height20,
                      AppSwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text("authenticated".tr),
                        subtitle: Text("add_provider_authenticated".tr),
                        value: useAuthenticated,
                        onChanged: onChangeAuthenticated,
                      ),
                      APPAnimatedSize(
                          isActive: useAuthenticated,
                          onActive: (context) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  WidgetConstant.height8,
                                  AppDropDownBottom(
                                    items: {
                                      for (final i in supportedAuths)
                                        i: Text(i.name.camelCase)
                                    },
                                    onChanged: onChangeAuthMode,
                                    value: auth,
                                  ),
                                  WidgetConstant.height20,
                                  AppTextField(
                                    label: keyLabel,
                                    pasteIcon: true,
                                    initialValue: authKey,
                                    hint: keyHint,
                                    onChanged: onChangeKey,
                                    validator: validateKey,
                                  ),
                                  AppTextField(
                                      pasteIcon: true,
                                      label: valueLabel,
                                      initialValue: authValue,
                                      hint: valueHint,
                                      onChanged: onChangeValue,
                                      validator: validateValue),
                                ],
                              ),
                          onDeactive: (c) => WidgetConstant.sizedBox),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        FixedElevatedButton(
                            padding: WidgetConstant.paddingVertical40,
                            onPressed: updateAuth,
                            child: Text("update_authentication".tr))
                      ]),
                    ],
                  ),
                ),
              )
            ]));
      },
    );
  }
}
