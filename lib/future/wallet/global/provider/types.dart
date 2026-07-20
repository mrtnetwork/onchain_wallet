import 'package:on_chain_wallet/wallet/api/service/types/provider.dart';
import 'package:on_chain_wallet/wallet/api/types/types.dart';

class ViewServiceProviders {
  final APIProviderServices? service;
  final List<DefaultAPIProvider> providers;
  DefaultAPIProvider? selected;
  ViewServiceProviders({this.service, required this.providers, required this.selected});

  void selectProvider(DefaultAPIProvider provider) {
    if (providers.contains(provider)) {
      selected = provider;
    }
  }
}
