import 'package:blockchain_utils/service/models/params.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/api/service/types/auth.dart';
import 'package:on_chain_wallet/network/net_api/api.dart';

class HTTPServiceProviderFields extends StatefulWidget {
  const HTTPServiceProviderFields(
      {this.error,
      this.exclude = const [],
      super.key,
      this.initialUrl,
      this.hint,
      this.enableAuth = true,
      required this.protocols,
      this.onChangeUrl});
  final String? error;
  final List<String> exclude;
  final RPCURL? initialUrl;
  final String? hint;
  final bool enableAuth;
  final List<ServiceProtocol> protocols;
  final StringVoid? onChangeUrl;

  @override
  State<HTTPServiceProviderFields> createState() => HTTPServiceProviderFieldsState();
}

class HTTPServiceProviderFieldsState extends State<HTTPServiceProviderFields>
    with SafeState {
  bool useAuthenticated = false;
  RPCURL? initialUrl;
  ProviderAuthType auth = ProviderAuthType.header;
  final GlobalKey<AppTextFieldState> urlKey = GlobalKey();
  String authKey = "";
  String authValue = "";
  String? authError;
  String rpcURL = '';

  GlobalKey<FormState> formKey =
      GlobalKey(debugLabel: "HTTPServiceProviderFieldsState_formstate");

  void onChangeAuthMode(ProviderAuthType? auth) {
    this.auth = auth ?? this.auth;
    updateState();
    checkAtuthError();
  }

  void onChangeAuthenticated(bool? v) {
    useAuthenticated = !useAuthenticated;
    updateState();
    checkAtuthError();
  }

  String get authKeyLabe {
    return auth.isDigest ? "username".tr : "authenticated_key".tr;
  }

  String get authValueLabe {
    return auth.isDigest ? "password".tr : "authenticated_value".tr;
  }

  String get authKeyExample {
    switch (auth) {
      case ProviderAuthType.digest:
        return "username".tr;
      default:
        return "example_value".tr.replaceOne(auth.isHeader
            ? APPConst.exampleAuthenticatedHeader
            : APPConst.exampleAuthenticatedQuery);
    }
  }

  String get authValueExample {
    switch (auth) {
      case ProviderAuthType.digest:
        return "password".tr;
      default:
        return "example_value".tr.replaceOne(auth.isHeader
            ? APPConst.exampleAuthenticatedHeaderValue
            : APPConst.exampleBase58);
    }
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

  void onChageUrl(String v) {
    rpcURL = v;
    widget.onChangeUrl?.call(v);
    checkAtuthError();
  }

  void checkAtuthError() {
    String? err;
    if (useAuthenticated &&
        auth != ProviderAuthType.query &&
        rpcURL.toLowerCase().startsWith("ws")) {
      err = "websocket_authenticated_unsuported_desc".tr;
    }
    if (authError != err) {
      authError = err;
      updateState();
    }
  }

  String? _validateRpcUrl(String? v) {
    if (v == null) return null;
    if (widget.protocols.contains(ServiceProtocol.websocket)) {
      return StrUtils.validateUri(v, schame: ['http', 'https', 'wss', 'ws']);
    }
    return StrUtils.validateUri(v, schame: ['http', 'https']);
  }

  String? validateRpcUrl(String? v) {
    final path = _validateRpcUrl(v);
    if (path == null) return "invalid_url".tr;
    if (widget.exclude.contains(path)) {
      return "rpc_url_already_exists".tr;
    }
    return null;
  }

  RPCURL? getEndpoint() {
    if (authError != null || !formKey.ready()) {
      return null;
    }
    ProviderAuthenticated? authenticated;
    if (useAuthenticated) {
      if (auth.isDigest) {
        authenticated =
            DigestProviderAuthenticated(password: authValue, username: authKey);
      } else {
        authenticated =
            BasicProviderAuthenticated(type: auth, key: authKey, value: authValue);
      }
    }
    return RPCURL(url: rpcURL, auth: authenticated);
  }

  void init() {
    final initialUrl = this.initialUrl;
    if (initialUrl != null) {
      rpcURL = initialUrl.url;
      urlKey.currentState?.updateText(rpcURL);
      final auth = initialUrl.auth;
      if (widget.enableAuth && auth != null) {
        useAuthenticated = true;
        this.auth = auth.type;
        switch (auth.type) {
          case ProviderAuthType.header:
          case ProviderAuthType.query:
            final basicAuth = auth.cast<BasicProviderAuthenticated>();
            authKey = basicAuth.key;
            authValue = basicAuth.value;
            break;
          case ProviderAuthType.digest:
            final basicAuth = auth.cast<DigestProviderAuthenticated>();
            authKey = basicAuth.username;
            authValue = basicAuth.password;
            break;
        }
      }
    }
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    initialUrl = widget.initialUrl;
    init();
  }

  @override
  void didUpdateWidget(covariant HTTPServiceProviderFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget != widget && initialUrl != widget.initialUrl) {
      initialUrl = widget.initialUrl;
      init();
      updateState();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          AppTextField(
            key: urlKey,
            label: "endpoint_url".tr,
            pasteIcon: true,
            prefixIcon: const Icon(Icons.link),
            validator: validateRpcUrl,
            onChanged: onChageUrl,
            initialValue: rpcURL,
            maxLines: 2,
            minlines: 1,
            hint: widget.hint,
          ),
          // WidgetConstant.height20,
          if (widget.enableAuth)
            AppSwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text("authenticated".tr),
              subtitle: Text("add_provider_authenticated".tr),
              value: useAuthenticated,
              onChanged: onChangeAuthenticated,
            ),
          APPAnimatedSize(
              isActive: useAuthenticated,
              onActive: (c) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      WidgetConstant.height8,
                      AppDropDownBottom(
                        items: {
                          for (final i in ProviderAuthType.values)
                            i: Text(i.name.camelCase)
                        },
                        hint: "authenticated_type".tr,
                        onChanged: onChangeAuthMode,
                        value: auth,
                      ),
                      WidgetConstant.height20,
                      AppTextField(
                        label: authKeyLabe,
                        pasteIcon: true,
                        initialValue: authKey,
                        hint: authKeyExample,
                        onChanged: onChangeKey,
                        validator: validateKey,
                      ),
                      AppTextField(
                          pasteIcon: true,
                          label: authValueLabe,
                          initialValue: authValue,
                          hint: authValueExample,
                          onChanged: onChangeValue,
                          validator: validateValue),
                      ErrorTextContainer(
                          error: authError,
                          verticalMargin: WidgetConstant.paddingVertical10),
                    ],
                  ),
              onDeactive: (c) => WidgetConstant.sizedBox),
        ],
      ),
    );
  }
}
