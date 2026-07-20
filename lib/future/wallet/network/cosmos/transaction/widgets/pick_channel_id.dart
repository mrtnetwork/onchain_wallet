import 'package:cosmos_sdk/proto_messages/ibc/core/channel/v1/src/channel.dart' as ibc;
import 'package:cosmos_sdk/sdk/provider/chain_registery/models/models/cosmos_sdk.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/cosmos/models/models.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

typedef ONSELECTCHANNELID = void Function(BuildContext, String);

class CosmosPickChannelIdView extends StatefulWidget {
  final ScrollController controller;
  final CosmosChain sourceChain;
  final CosmosChain destinationChain;
  final ONSELECTCHANNELID onSelectChannelId;
  const CosmosPickChannelIdView(
      {required this.controller,
      required this.sourceChain,
      required this.destinationChain,
      required this.onSelectChannelId,
      super.key});

  @override
  State<CosmosPickChannelIdView> createState() => _CosmosPickChannelIdViewState();
}

class _CosmosPickChannelIdViewState extends CosmosAccountState<CosmosPickChannelIdView> {
  final GlobalKey<FormState> formKey = GlobalKey();
  final StreamPageProgressController progressKey =
      StreamPageProgressController(initialStatus: StreamWidgetStatus.progress);
  bool checkConnection = true;
  CW20Token? sourceToken;
  CW20Token? destionationToken;
  CosmosChain get sourceChain => widget.sourceChain;
  CosmosChain get destinationChain => widget.destinationChain;
  final channelIdKey = GlobalKey<AppTextFieldState>();
  final portIdKey = GlobalKey<AppTextFieldState>();
  final _channelIdRegex = RegExp(CosmosConst.ibcChannelRegex);
  @override
  CosmosChain get account => widget.sourceChain;

  void onChangeCheckConnection(bool? _) {
    checkConnection = !checkConnection;
    updateState();
  }

  void onSelectChannel(CosmosIBCChannelId? channel) {
    if (channel == null) return;
    channelIdKey.currentState?.updateText(channel.channelId);
    portIdKey.currentState?.updateText(channel.port);
  }

  String channelId = '';
  void onChangeChannelId(String channelId) {
    this.channelId = channelId;
  }

  String port = CosmosConst.transferIbcPort;
  void onChangePort(String port) {
    this.port = port;
  }

  List<_IbcExistsChannel> existsChannels = [];

  Future<List<_IbcExistsChannel>> loadChains(CosmosNetworkClient client) async {
    final json = await appContext?.platformUtls.loadAssets(APPConst.cosmosChainRegistery);
    final result = json?.mapCatch((e) => CosmosSdkChainChains.deserialize(bytes: e));
    if (result == null) return [];
    return result.fold(
      onOk: (value) {
        final chain = value.getChain(sourceChain.network.coinParam.chainType,
            sourceChain.network.coinParam.chainId);
        if (chain == null) return [];
        final routes = chain.getRoutes(destinationChain.network.coinParam.chainId);
        return routes
            .map((e) => _IbcExistsChannel(
                channel:
                    CosmosIBCChannelId(channelId: e.localChannelId, port: e.localPortId),
                client: client))
            .toList();
      },
      onErr: (error) => [],
    );
  }

  Future<List<_IbcExistsChannel>> loadAccountChannels(CosmosNetworkClient client) async {
    final channelIds = await account.getIbcChannelIds();

    return channelIds.fold(
      onOk: (routes) {
        return routes.channelIds
            .map((e) => _IbcExistsChannel(channel: e, client: client))
            .toList();
      },
      onErr: (error) => [],
    );
  }

  Future<void> _init() async {
    final client = await sourceChain.client();
    client.mapErr((e) {
      progressKey.errorText(e.localizationError, backToIdle: false);
      return e.exception;
    }).mapAsync<void>((e) async {
      final ccChannels = await loadChains(e);
      final accountChannels = await loadAccountChannels(e);
      existsChannels = [...ccChannels, ...accountChannels];
      sourceToken = sourceChain.network.coinParam.nativeToken;
      destionationToken = destinationChain.network.coinParam.nativeToken;
      progressKey.backToIdle();
      for (final i in existsChannels) {
        i.checkStatus();
      }
    });
  }

  String? validateChannelId(String? channelId) {
    if (channelId == null || !_channelIdRegex.hasMatch(channelId)) {
      return "ibc_channel_validator".tr;
    }
    return null;
  }

  String? validatePortId(String? portId) {
    if (portId == null || portId.trim().isEmpty) {
      return "enter_a_valid_port_id".tr;
    }
    return null;
  }

  Future<IbcChannelStatus?> _checkChannelConnection(
      {required CosmosChain chain,
      required String channelId,
      String prot = CosmosConst.transferIbcPort}) async {
    progressKey.progressText(
        "checking_chain_channel_id_connection".tr.replaceOne(chain.network.networkName));
    final client = await chain.client();
    final result = await client.mapCatchAsync((client) async {
      final result = await client.getIbcChannelStatus(channelId, prot: prot);
      return result;
    });
    return result.fold(
      onErr: (error) {
        progressKey.errorText(error.localizationError,
            backToIdle: false, showBackButton: true);
        return null;
      },
      onOk: (value) {
        // value.
        if (value == null) {
          progressKey.errorText("channel_not_found".tr,
              backToIdle: false, showBackButton: true);
          return null;
        }
        if (value.channel.state != ibc.State.stateOpen || !value.clientStatus.isActive) {
          progressKey.errorText("ibc_channel_incorrect_state".tr,
              backToIdle: false, showBackButton: true);
          return null;
        }
        return value;
      },
    );
  }

  Future<void> checkChannelConnection() async {
    if (!formKey.ready()) return;
    final channelId = this.channelId;
    final port = this.port;
    if (checkConnection) {
      final source = await _checkChannelConnection(
          chain: widget.sourceChain, channelId: channelId, prot: port);
      if (source == null) return;
      final destination = await _checkChannelConnection(
          chain: widget.destinationChain,
          channelId: source.counterpartyChannelId,
          prot: source.counterpartyPort);
      if (destination == null) return;
      if (source.channel.version != destination.channel.version) {
        progressKey.errorText("ibc_source_destination_version_mismatch".tr,
            backToIdle: false, showBackButton: true);
        return;
      }
    }
    final allChannels = existsChannels.map((e) => e.channel).toList();
    final channel = CosmosIBCChannelId(channelId: channelId, port: port);
    if (!allChannels.contains(channel)) {
      final result = await context.openSliverDialog<bool>(
        widget: (context) => DialogTextView(
          text: "save_channel_desc".tr,
          buttonWidget: DialogDoubleButtonView(
            firstButtonLabel: "save".tr,
          ),
        ),
        label: "save_channel".tr,
      );
      if (result ?? false) {
        final save = await account.addNewIbcChannel(channel);
        if (save.isErr) {
          progressKey.errorText(save.unwrapErr().localizationError,
              backToIdle: false, showBackButton: true);
          return;
        }
      }
    }
    progressKey.success();
    widget.onSelectChannelId(context, channelId);
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    MethodUtils.executeAfterDelay(() => _init(), duration: APPConst.animationDuraion);
  }

  @override
  void safeDispose() {
    super.safeDispose();
    progressKey.dispose();

    sourceToken?.streamBalance.dispose();
    destionationToken?.streamBalance.dispose();
    sourceToken = null;
    destionationToken = null;
    for (final i in existsChannels) {
      i.dispose();
    }
    existsChannels = [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("pick_channel".tr)),
      body: Form(
        key: formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: StreamPageProgress(
          controller: progressKey,
          builder: (context) {
            return CustomScrollView(
              controller: widget.controller,
              slivers: [
                SliverConstraintsBoxView(
                    padding: WidgetConstant.paddingHorizontal20,
                    sliver: SliverToBoxAdapter(
                      child:
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text("route".tr, style: context.textTheme.titleMedium),
                        WidgetConstant.height8,
                        ContainerWithBorder(
                          child: Row(
                            children: [
                              Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  CircleTokenImageView(sourceToken!.token,
                                      radius: APPConst.circleRadius25),
                                  Container(
                                    padding:
                                        EdgeInsets.only(left: APPConst.circleRadius25),
                                    child: CircleTokenImageView(destionationToken!.token,
                                        radius: APPConst.circleRadius25),
                                  ),
                                ],
                              ),
                              WidgetConstant.width8,
                              Expanded(
                                  child: Text(
                                "forward_symbol"
                                    .tr
                                    .replaceOne(sourceChain.network.networkName)
                                    .replaceTwo(destinationChain.network.networkName),
                                style: context.onPrimaryTextTheme.titleMedium,
                              ))
                            ],
                          ),
                        ),
                        WidgetConstant.height20,
                        Text("channel_id".tr, style: context.textTheme.titleMedium),
                        Text('ibc_channel_desc'.tr),
                        WidgetConstant.height8,
                        AppTextField(
                          key: channelIdKey,
                          label: 'channel_id'.tr,
                          hint: 'example_s'.tr.replaceOne(APPConst.exampleChannelId),
                          validator: validateChannelId,
                          onChanged: onChangeChannelId,
                          initialValue: channelId,
                          pasteIcon: true,
                        ),
                        WidgetConstant.height20,
                        Text("port_id".tr, style: context.textTheme.titleMedium),
                        WidgetConstant.height8,
                        AppTextField(
                          key: portIdKey,
                          label: 'port_id'.tr,
                          hint: 'example_s'.tr.replaceOne(CosmosConst.transferIbcPort),
                          validator: validatePortId,
                          onChanged: onChangePort,
                          initialValue: port,
                          pasteIcon: true,
                        ),
                        WidgetConstant.height20,
                        DisabledWidget(
                            disabled: existsChannels.isEmpty,
                            ignoring: true,
                            onActive: (context, _) => AppListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text("channels".tr),
                                  trailing: Icon(
                                    Icons.open_in_new,
                                  ),
                                  subtitle: switch (existsChannels.isEmpty) {
                                    true => Text("no_channel_found".tr),
                                    false => Text("tap_to_choose_channel".tr),
                                  },
                                  onTap: () {
                                    context
                                        .openSliverDialog<CosmosIBCChannelId>(
                                            label: "channels".tr,
                                            sliver: (context) =>
                                                _IbcChannelsView(existsChannels))
                                        .then(onSelectChannel);
                                  },
                                )),
                        WidgetConstant.height20,
                        AppCheckListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text("check_channel_connection".tr),
                            subtitle: Text("check_channel_connection_desc".tr),
                            value: checkConnection,
                            onChanged: onChangeCheckConnection),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FixedElevatedButton(
                                padding: WidgetConstant.paddingVertical40,
                                onPressed: checkChannelConnection,
                                child: Text("pick_channel".tr))
                          ],
                        )
                      ]),
                    ))
              ],
            );
          },
        ),
      ),
    );
  }
}

class _IbcChannelsView extends StatelessWidget {
  final List<_IbcExistsChannel> channels;
  const _IbcChannelsView(this.channels);

  @override
  Widget build(BuildContext context) {
    return SliverConstraintsBoxView(
      padding: WidgetConstant.padding20,
      sliver: SliverList.builder(
        itemBuilder: (context, index) {
          final channel = channels[index];
          return APPStreamBuilder(
            value: channel.status,
            builder: (context, status) => Shimmer(
              enable: !status.isPending,
              onActive: (_, context) => ContainerWithBorder(
                onRemove: () {},
                enableTap: false,
                onRemoveWidget: Row(
                  children: [
                    IconButton(
                      onPressed: null,
                      icon: status.icon(context),
                      tooltip: status.message(),
                    ),
                    IconButton(
                        onPressed: () {
                          context.pop(channel.channel);
                        },
                        icon: Icon(
                          Icons.chevron_right,
                          color: context.onPrimaryContainer,
                        ))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OneLineTextWidget(
                      channel.channel.channelId,
                      style: context.onPrimaryTextTheme.bodyMedium,
                    ),
                    OneLineTextWidget(
                      channel.channel.port,
                      style: context.onPrimaryTextTheme.bodySmall,
                    )
                  ],
                ),
              ),
            ),
          );
        },
        itemCount: channels.length,
      ),
    );
  }
}

sealed class _IbcChannelStatus {
  const _IbcChannelStatus();
  bool get isPending => false;
  Icon icon(BuildContext context) => switch (this) {
        _IbcChannelPending() => Icon(
            Icons.sync,
            color: context.onPrimaryContainer,
          ),
        _IbcChannelError() => Icon(
            Icons.error,
            color: context.colors.error,
          ),
        _IbcChannelOk(:final status) => switch (status?.isActive) {
            true => Icon(
                Icons.check_circle,
                color: context.onPrimaryContainer,
              ),
            _ => Icon(
                Icons.error,
                color: context.colors.error,
              )
          }
      };

  String? message() => switch (this) {
        _IbcChannelPending() => "pending".tr,
        _IbcChannelError(:final err) => err,
        _IbcChannelOk(:final status) => switch (status?.isActive) {
            true => null,
            null => "channel_not_found".tr,
            _ => switch (status?.channelIsOpen) {
                true => status?.clientStatus.name,
                _ => "ibc_channel_incorrect_state".tr
              }
          }
      };
}

class _IbcChannelPending extends _IbcChannelStatus {
  @override
  bool get isPending => true;
}

class _IbcChannelError extends _IbcChannelStatus {
  final String err;
  const _IbcChannelError(this.err);
}

class _IbcChannelOk extends _IbcChannelStatus {
  final IbcChannelStatus? status;
  const _IbcChannelOk(this.status);
}

// abstract class _IbcChannelWithStatus {

// }

class _IbcExistsChannel {
  final CosmosIBCChannelId channel;

  StreamValue<_IbcChannelStatus> status =
      StreamValue(_IbcChannelPending(), name: '_IbcExistsChannel');
  final CosmosNetworkClient client;
  _IbcExistsChannel({required this.channel, required this.client});

  Future<void> checkStatus() async {
    if (status.value case _IbcChannelOk()) return;
    final result = await IResult.call(() async {
      return await client.getIbcChannelStatus(channel.channelId, prot: channel.port);
    });
    result.map((e) {
      status.value = _IbcChannelOk(e);
    }).mapErr((e) {
      status.value = _IbcChannelError(e.localizationError);
      return e.exception;
    });
  }

  void dispose() {
    status.dispose();
  }
}
