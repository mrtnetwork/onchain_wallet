import 'dart:async';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

typedef CHAINSTREAMBUILER<T extends APPCHAIN> = Widget Function(
    BuildContext context, ChainEvent? latestEvent);

class ChainStreamBuilder<T extends APPCHAIN> extends StatefulWidget {
  final T account;
  final List<ChainNotify>? allowNotify;
  final CHAINSTREAMBUILER builder;
  final String? debugName;
  final Duration? progressEventDelay;
  const ChainStreamBuilder(
      {required this.builder,
      required this.account,
      this.progressEventDelay,
      this.debugName,
      this.allowNotify,
      super.key});

  @override
  State<ChainStreamBuilder> createState() => _ChainStreamBuilderState<T>();
}

class _ChainStreamBuilderState<T extends APPCHAIN> extends State<ChainStreamBuilder<T>>
    with SafeState<ChainStreamBuilder<T>> {
  ChainEvent? latestEvent;
  late T account = widget.account;
  StreamSubscription<ChainEvent>? _subscription;
  final _lock = SafeAtomicLock();
  void onChainNotify(ChainEvent event) {
    _lock.run(() async {
      if (widget.allowNotify?.contains(event.type) ?? true) {
        latestEvent = event;
        updateState();
        if (event.status.isProgress) {
          final delay = widget.progressEventDelay;
          if (delay != null) await Future.delayed(delay);
        }
      }
    });
  }

  void diposeStream() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    _subscription = account.stream.listen(onChainNotify);
  }

  @override
  void safeDispose() {
    super.safeDispose();
    diposeStream();
  }

  @override
  void didUpdateWidget(covariant ChainStreamBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (account != widget.account) {
      account = widget.account;
      diposeStream();
      _subscription = account.stream.listen(onChainNotify);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, latestEvent);
  }
}
