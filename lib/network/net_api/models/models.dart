import 'package:on_chain_wallet/network/net_api/models/stream.dart';

enum HTTPClientType {
  cached,
  single,
  perRequest;
}

typedef CbOnHttpStreamProgress = void Function(StreamProgress progress);
