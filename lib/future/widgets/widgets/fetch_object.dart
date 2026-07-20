import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

typedef ONFETCHOBJECTERROR = Widget Function(
    BuildContext context, Object error, String errorMessage);

class FetchObjectWidget<T extends Object?> extends StatelessWidget {
  final FetchObject<T> object;
  const FetchObjectWidget(
      {required this.object,
      required this.builder,
      required this.onError,
      this.onIdle,
      required this.onPending,
      super.key});
  final WidgetDataContext<T> builder;
  final ONFETCHOBJECTERROR onError;
  final WidgetContext onPending;
  final WidgetContext? onIdle;

  @override
  Widget build(BuildContext context) {
    return APPStreamBuilder(
      value: object.notifier,
      builder: (context, _) {
        return ContainerWithBorder(
          onRemove: object.status.isFailed
              ? () {
                  object.get();
                }
              : null,
          onRemoveWidget: APPAnimated(
              isActive: object.status.isFailed,
              onActive: (context) =>
                  Icon(Icons.refresh, color: context.colors.onPrimaryContainer)),
          child: APPAnimatedSwitcher<FetchObjectStatus>(enable: object.status, widgets: {
            FetchObjectStatus.idle: (context) =>
                onIdle?.call(context) ?? WidgetConstant.sizedBox,
            FetchObjectStatus.pending: (context) =>
                Shimmer(enable: false, onActive: (_, context) => onPending(context)),
            FetchObjectStatus.failed: (context) =>
                onError(context, object.error!, object.errorMessage!),
            FetchObjectStatus.success: (context) => builder(context, object.value as T),
          }),
        );
      },
    );
  }
}
