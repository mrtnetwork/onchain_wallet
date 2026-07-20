import 'dart:async' show StreamSubscription;
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/future/router/page_router.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/future/wallet/global/global.dart';
import 'package:on_chain_wallet/future/wallet/global/provider/types.dart';
import 'package:on_chain_wallet/future/widgets/custom_widgets.dart';
import 'package:on_chain_wallet/wallet/api/service/service.dart';
import 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

class ManageProviderView extends StatefulWidget {
  const ManageProviderView({super.key});
  @override
  State<ManageProviderView> createState() => _ManageProviderViewState();
}

class _ManageProviderViewState extends State<ManageProviderView>
    with SafeState<ManageProviderView> {
  final StreamPageProgressController progressKey =
      StreamPageProgressController(initialStatus: StreamWidgetStatus.progress);
  late WalletProvider wallet;
  late NetworkClientConfig config;
  late Chain chain;

  bool torSupported = false;
  bool everySelected = false;
  StreamSubscription<ChainEvent>? listener;
  bool get providerEnabled => config.enableProvider;

  List<ViewServiceProviders> serviceProviders = [];

  INetworkServiceNotify get status => chain.clientStatus;

  void onToggleProvider() {
    final connection = config.copyWith(
        enableProvider: !providerEnabled, autoConnect: false, runtimeAuto: false);
    wallet.setAccountProvider(provider: connection, account: chain).then((e) {
      e.watch(
        onErr: (error) => context.showAlert(error.localizationError),
      );
    });
  }

  Future<void> onSwitchProvider(
      ViewServiceProviders service, DefaultAPIProvider? provider) async {
    if (provider == null) return;
    service.selectProvider(provider);
    updateState();
    final selectedServices = serviceProviders.map((e) => e.selected).toList();
    if (selectedServices.every((e) => e != null)) {
      everySelected = true;
      final config = this.config.copyWith(
          providers: selectedServices.cast<DefaultAPIProvider>(), runtimeAuto: false);
      wallet.setAccountProvider(provider: config, account: chain).then((e) {
        e.watch(
          onErr: (error) => context.showAlert(error.localizationError),
        );
      });
    }
  }

  Future<void> onToggleTorFeature(
      ViewServiceProviders service, DefaultAPIProvider? provider) async {
    if (provider == null) return;
    provider = provider.updateMode(~provider.mode);
    chain.updateNetworkProvider(provider).then((e) {
      e.watch(
        onErr: (error) => context.showAlert(error.localizationError),
      );
    });
  }

  Future<void> init() async {
    final providers = await chain.getProviders();
    final result = await providers.andThenAsync((providers) async {
      final identifier = await chain.getServiceConfig();
      return identifier.map((config) => (providers: providers, config: config));
    });
    result.watch(
      onErr: (error) {
        progressKey.errorText(error.localizationError, backToIdle: false);
      },
      onOk: (result) {
        config = result.config;
        final clientRequirment = chain.clientRequiredServices;
        if (clientRequirment.requirementServices.isEmpty) {
          final providers = result.providers
              .where((e) => clientRequirment.allowServices.contains(e.service))
              .toList();
          serviceProviders = [
            ViewServiceProviders(
                service: null,
                providers: providers,
                selected: providers.firstWhereOrNull((e) => config.providers.contains(e)))
          ];
        } else {
          serviceProviders = clientRequirment.requirementServices.map((service) {
            final providers =
                result.providers.where((e) => e.service == service).toList();
            return ViewServiceProviders(
                service: service,
                providers: providers,
                selected:
                    providers.firstWhereOrNull((e) => config.providers.contains(e)));
          }).toList();
        }
        everySelected = serviceProviders.every((e) => e.selected != null);
        progressKey.backToIdle();
      },
    );
  }

  Future<void> onChainEvent(ChainEvent event) async {
    if (event.type == DefaultChainNotify.updateProvider) {
      await init();
      updateState();
      return;
    }
    final identifier = await chain.getServiceConfig();
    identifier.watch(
      onErr: (error) => context.showAlert(error.localizationError),
      onOk: (config) {
        this.config = config;
        serviceProviders = serviceProviders
            .map((e) => ViewServiceProviders(
                providers: e.providers,
                selected:
                    e.providers.firstWhereOrNull((e) => config.providers.contains(e))))
            .toList();
        everySelected = serviceProviders.every((e) => e.selected != null);
        updateState();
      },
    );
  }

  void tryCurrentProvider() {
    chain.client().then((e) {
      e.mapErr((e) {
        context.showAlert(e.localizationError);
        return e.exception;
      });
    });
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    wallet = context.wallet;
    chain = wallet.wallet.currentChain;
    torSupported = wallet.supportTorConnection;
    listener = chain.stream
        .where((e) =>
            e.type == DefaultChainNotify.client ||
            e.type == DefaultChainNotify.updateProvider)
        .listen(onChainEvent);
    init();
  }

  @override
  void safeDispose() {
    super.safeDispose();
    listener?.cancel();
    listener = null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamPageProgress(
      controller: progressKey,
      builder: (context) {
        return ChainStreamBuilder(
            allowNotify: [DefaultChainNotify.client],
            builder: (context, latestEvent) {
              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    title: Text("service_provider".tr),
                    actions: [
                      IconButton(
                          onPressed: () {
                            context.openSliverDialog(
                                label: "provider_settings".tr,
                                sliver: (context) => _ProviderSettingsView(config));
                          },
                          icon: Icon(Icons.settings)),
                      WidgetConstant.width8,
                    ],
                  ),
                  SliverConstraintsBoxView(
                      padding: WidgetConstant.padding20,
                      sliver: MultiSliver(children: [
                        SliverOpacity(
                          opacity: providerEnabled
                              ? APPConst.defaultOpacity
                              : APPConst.disabledOpacity,
                          sliver: SliverList.builder(
                            itemCount: serviceProviders.length,
                            itemBuilder: (context, index) {
                              final service = serviceProviders[index];
                              return ServiceProvidersView(
                                service: service,
                                everySelected: everySelected,
                                onTry: tryCurrentProvider,
                                networkType: chain.network.type,
                                onToggleTorFeature: (provider) async {
                                  onToggleTorFeature(service, provider);
                                },
                                torSupported: torSupported,
                                status: status,
                                onSelectProvider: (provider) async {
                                  onSwitchProvider(service, provider);
                                },
                              );
                            },
                          ),
                        )
                      ]))
                ],
              );
            },
            account: chain);
      },
    );
  }
}

class ServiceProvidersView extends StatelessWidget {
  final ViewServiceProviders service;
  final ONTAPPROVIDER onToggleTorFeature;
  final ONTAPPROVIDER onSelectProvider;
  final bool torSupported;
  final INetworkServiceNotify status;
  final NetworkType networkType;
  final bool everySelected;
  final DynamicVoid onTry;
  const ServiceProvidersView(
      {required this.service,
      required this.onToggleTorFeature,
      required this.torSupported,
      required this.status,
      required this.onSelectProvider,
      required this.networkType,
      required this.everySelected,
      required this.onTry,
      super.key});

  @override
  Widget build(BuildContext context) {
    return CustomizedContainer(
      validate: service.selected != null,
      // padding: EdgeInsets.zero,
      child: APPExpansionListTile(
        initiallyExpanded: true,
        title: Text(service.service?.name ?? "providers".tr),
        subtitle: Text("select_provider_to_use".tr),
        // tilePadding: WidgetConstant.padding10,
        children: [
          AppGroupRadioBuilder<DefaultAPIProvider?>(
            groupValue: service.selected,
            onChanged: (value) => onSelectProvider(value),
            builder: (context) {
              return ListView.builder(
                physics: WidgetConstant.noScrollPhysics,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final provider = service.providers.elementAt(index);
                  final bool isSelected = provider == service.selected;

                  bool enable = true;
                  if (isSelected && status.status.isPending) {
                    enable = false;
                  }
                  return Shimmer(
                      onActive: (enable, context) {
                        return SelectedProviderInfo(
                          provider: provider,
                          isSelected: isSelected,
                          status: status,
                          everySelected: everySelected,
                          onTry: onTry,
                          torSupported: torSupported,
                          onToggleTorFeature: onToggleTorFeature,
                        );
                      },
                      enable: enable);
                },
                itemCount: service.providers.length,
              );
            },
          ),
          ContainerWithBorder(
            backgroundColor: context.colors.surface,
            onRemove: () {
              context.to(PageRouter.updateProvider(networkType));
            },
            onRemoveIcon: Icon(Icons.add_box, color: context.colors.onSurface),
            child: Text("network_add_provider".tr, style: context.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

typedef ONTAPPROVIDER = Future<void> Function(DefaultAPIProvider? provider);

// typedef ONENABLETORFEATURE<T extends APIProvider> =
class SelectedProviderInfo extends StatelessWidget {
  const SelectedProviderInfo({
    super.key,
    required this.provider,
    required this.isSelected,
    required this.status,
    required this.torSupported,
    required this.onToggleTorFeature,
    required this.everySelected,
    required this.onTry,
  });
  final bool isSelected;
  final INetworkServiceNotify status;
  final DefaultAPIProvider provider;
  final bool torSupported;
  final ONTAPPROVIDER onToggleTorFeature;
  final bool everySelected;
  final DynamicVoid onTry;

  @override
  Widget build(BuildContext context) {
    final bool disabled = provider.mode.isTor && !torSupported;

    return Opacity(
      opacity: disabled ? APPConst.disabledOpacity : APPConst.defaultOpacity,
      child: IgnorePointer(
        ignoring: disabled,
        child: CustomizedContainer(
          onStackIcon: Icons.open_in_full,
          validate: !isSelected || !status.status.isError,
          backgroundColor: context.colors.surface,
          onRemoveWidget: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConditionalWidget(
                enable: isSelected && status.status.isError,
                onActive: (context) {
                  return ToolTipView(
                    message: status.error?.localizationError ??
                        "connection_attempt_unsuccessful".tr,
                    child: Icon(
                      Icons.error,
                      color: context.colors.error,
                    ),
                  );
                },
              ),
              ConditionalWidget(
                enable: torSupported,
                onActive: (context) {
                  final bool isTor = provider.mode.isTor;
                  return IconButton(
                    onPressed: () => onToggleTorFeature(provider),
                    icon: Icon(
                      CustomIcons.tor,
                      color: context.colors.primary.disabled,
                    ),
                    isSelected: isTor,
                    selectedIcon: Icon(
                      CustomIcons.tor,
                      color: context.colors.primary,
                    ),
                    tooltip: switch (isTor) {
                      false => "enable_tor_feature".tr,
                      true => "disable_tor_feature".tr
                    },
                  );
                },
              ),
              Radio<DefaultAPIProvider?>(
                value: provider,
              ),
            ],
          ),
          onRemove: () {
            onTry();
          },
          enableTap: isSelected && status.status.isError,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(provider.protocol.value.tr,
                          style: context.textTheme.labelLarge),
                      Text(provider.url,
                          style: context.textTheme.bodyMedium, maxLines: 2),
                    ],
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProviderStatusView extends StatelessWidget {
  final INetworkServiceNotify status;
  const ProviderStatusView(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: switch (status.status) {
        NetworkServiceStatus.connected => "connected".tr,
        NetworkServiceStatus.pending => "node_connectiong_please_wait".tr,
        NetworkServiceStatus.pendingTor => "tor_connecting_please_wait".tr,
        NetworkServiceStatus.error =>
          status.error?.localizationError ?? "connection_attempt_unsuccessful".tr,
      },
      onPressed: () {
        context.openDialogPage("service_provider".tr,
            child: (ctx) => ManageProviderView());
      },
      icon: BlinkingIcon(
          builder: (context) {
            return Icon(
              switch (status.status) {
                NetworkServiceStatus.pendingTor => CustomIcons.tor,
                _ => Icons.wifi
              },
              color: switch (status.status) {
                NetworkServiceStatus.error => context.colors.error,
                _ => context.colors.primary
              },
            );
          },
          blinking: status.status.isPending),
    );
  }
}

class _ProviderSettingsView extends StatefulWidget {
  final NetworkClientConfig config;
  const _ProviderSettingsView(this.config);

  @override
  State<_ProviderSettingsView> createState() => _ProviderSettingsViewState();
}

class _ProviderSettingsViewState extends State<_ProviderSettingsView>
    with SafeState<_ProviderSettingsView> {
  late WalletProvider wallet;
  late NetworkClientConfig config;
  StreamSubscription<ChainEvent>? listener;
  Chain get chain => wallet.wallet.currentChain;
  bool get providerEnabled => config.enableProvider;
  bool get autoConnect => config.auto;
  void onToggleProvider() {
    final connection = config.copyWith(enableProvider: !providerEnabled);
    wallet.setAccountProvider(provider: connection, account: chain).then((e) {
      e.watch(
        onErr: (error) => context.showAlert(error.localizationError),
      );
    });
  }

  void onToggleAuto() {
    final connection = config.copyWith(autoConnect: !autoConnect);
    wallet.setAccountProvider(provider: connection, account: chain).then((e) {
      e.watch(
        onErr: (error) => context.showAlert(error.localizationError),
      );
    });
  }

  Future<void> onChainEvent(ChainEvent event) async {
    final identifier = await chain.getServiceConfig();
    identifier.watch(
      onErr: (error) => context.showAlert(error.localizationError),
      onOk: (config) {
        this.config = config;
        updateState();
      },
    );
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    wallet = context.wallet;
    config = widget.config;
    listener = chain.stream
        .where((e) => e.type == DefaultChainNotify.client)
        .listen(onChainEvent);
  }

  @override
  void safeDispose() {
    super.safeDispose();
    listener?.cancel();
    listener = null;
  }

  @override
  Widget build(BuildContext context) {
    return SliverConstraintsBoxView(
      padding: WidgetConstant.padding20,
      sliver: SliverToBoxAdapter(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AppCheckListTile(
          value: providerEnabled,
          contentPadding: EdgeInsets.zero,
          title: Text("service_provider".tr, style: context.textTheme.titleMedium),
          subtitle: Text("enable_disable_service_provider_desc".tr),
          onChanged: (s) {
            onToggleProvider();
          },
        ),
        AppCheckListTile(
          value: autoConnect,
          contentPadding: EdgeInsets.zero,
          title: Text("auto_connection".tr, style: context.textTheme.titleMedium),
          subtitle: Text("auto_service_connection_desc".tr),
          onChanged: (s) {
            onToggleAuto();
          },
        ),
      ])),
    );
  }
}
