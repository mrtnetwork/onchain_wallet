import 'dart:async';

import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/service/models/params.dart';
import 'package:on_chain_wallet/app/stream/controller.dart';
import 'package:on_chain_wallet/network/bridge/onchain/types/actions.dart';

class BridgeClientRequestResponse {
  final WCMResultNetworkClientRequest response;
  final Stream<List<int>>? stream;
  const BridgeClientRequestResponse({required this.response, this.stream});
}

class ServiceSubscribtionResponse implements BaseServiceSubscribtionResponse {
  @override
  final BaseServiceResponse response;
  final Object? identifier;
  @override
  final Stream<BaseSubscribtionEvent> stream;

  const ServiceSubscribtionResponse({
    required this.response,
    required this.stream,
    this.identifier,
  });
}

class ServiceGrpcStreamResponse {
  final BaseServiceResponse response;
  final Stream<List<int>> stream;
  const ServiceGrpcStreamResponse({required this.response, required this.stream});
}

sealed class BridgeClientStreamEvent<EVENT extends Object> {
  final SafeStreamController<EVENT> controller;
  StreamSubscription? _listener;
  final String id;
  BridgeClientStreamEvent({required this.id, required this.controller});
  void add(List<int> bytes);
  void close() {
    _listener?.cancel();
    _listener = null;
    controller.close();
  }

  void error(IException error) {
    controller.addError(error);
  }
}

class BridgeClientStreamEventSubscribtion
    extends BridgeClientStreamEvent<BaseSubscribtionEvent> {
  final BaseServiceSubscribtionRequest request;

  BridgeClientStreamEventSubscribtion(
      {required super.id, required super.controller, required this.request});

  @override
  void add(List<int> bytes) {
    controller.addIfListener(request.deserializeEvent(bytes));
  }
}

class BridgeClientStreamEventGrpc extends BridgeClientStreamEvent<List<int>> {
  BridgeClientStreamEventGrpc({required super.id, required super.controller});

  @override
  void add(List<int> bytes) {
    controller.addIfListener(bytes);
  }
}
