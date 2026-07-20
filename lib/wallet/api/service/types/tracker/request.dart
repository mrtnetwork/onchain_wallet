import 'package:on_chain_wallet/app/core.dart';

class ApiRequest {
  ApiRequest({this.error, required this.uri, required this.identifier})
      : time = DateTime.now().toLocal();
  final String identifier;
  final String uri;
  final APIError? error;
  bool get hasError => error != null;
  final DateTime time;
}
