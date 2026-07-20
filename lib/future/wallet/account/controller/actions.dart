import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/networks/types/address.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/controller/controller.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';

sealed class NetworkViewAction<
    NETWORKADDRESS extends IAddress,
    NETWORK extends WalletNetwork,
    CHAINACCOUNT extends ACCOUNADDRESSNETWORK<NETWORKADDRESS, NETWORK>,
    CL extends CLIENTNADDRESSNETWORK<NETWORKADDRESS, NETWORK>,
    CHAIN extends APPCHAINADDRESSNETWORKACCOUNTCLIENT<NETWORKADDRESS, NETWORK,
        CHAINACCOUNT, CL>,
    RESPONSE extends NetworkViewActionResponse<NETWORKADDRESS, NETWORK, CHAINACCOUNT, CL,
        CHAIN>> {
  final CHAIN? chain;
  const NetworkViewAction({required this.chain});
  Future<IResult<RESPONSE>> getResponse(WalletProvider provider);

  Future<IResult<CHAIN>> getCurrentChain(WalletProvider provider) async {
    CHAIN? chain = this.chain;
    if (chain == null) {
      final currentChain = provider.wallet.currentChain;
      if (currentChain is! CHAIN) {
        return ResultErr.fromException(AppException("requested_chain_differs"));
      }
      chain = currentChain;
    }
    final addresses = await chain.getAccountAddresses();
    return addresses.map((_) => chain!);
  }
}

class NetworkViewActionChain<
    NETWORKADDRESS extends IAddress,
    NETWORK extends WalletNetwork,
    CHAINACCOUNT extends ACCOUNADDRESSNETWORK<NETWORKADDRESS, NETWORK>,
    CL extends CLIENTNADDRESSNETWORK<NETWORKADDRESS, NETWORK>,
    CHAIN extends APPCHAINADDRESSNETWORKACCOUNTCLIENT<NETWORKADDRESS, NETWORK,
        CHAINACCOUNT, CL>> extends NetworkViewAction<
    NETWORKADDRESS,
    NETWORK,
    CHAINACCOUNT,
    CL,
    CHAIN,
    NetworkViewActionResponseChain<NETWORKADDRESS, NETWORK, CHAINACCOUNT, CL, CHAIN>> {
  const NetworkViewActionChain({super.chain});

  @override
  Future<
      IResult<
          NetworkViewActionResponseChain<NETWORKADDRESS, NETWORK, CHAINACCOUNT, CL,
              CHAIN>>> getResponse(WalletProvider provider) async {
    final chain = await getCurrentChain(provider);
    return chain
        .map((chain) => NetworkViewActionResponseChain(provider: provider, chain: chain));
  }
}

class NetworkViewActionAccount<
    NETWORKADDRESS extends IAddress,
    NETWORK extends WalletNetwork,
    CHAINACCOUNT extends ACCOUNADDRESSNETWORK<NETWORKADDRESS, NETWORK>,
    CL extends CLIENTNADDRESSNETWORK<NETWORKADDRESS, NETWORK>,
    CHAIN extends APPCHAINADDRESSNETWORKACCOUNTCLIENT<NETWORKADDRESS, NETWORK,
        CHAINACCOUNT, CL>> extends NetworkViewAction<
    NETWORKADDRESS,
    NETWORK,
    CHAINACCOUNT,
    CL,
    CHAIN,
    NetworkViewActionResponseAccount<NETWORKADDRESS, NETWORK, CHAINACCOUNT, CL, CHAIN>> {
  final bool onlyMultisig;
  const NetworkViewActionAccount({super.chain, this.onlyMultisig = false});

  @override
  Future<
      IResult<
          NetworkViewActionResponseAccount<NETWORKADDRESS, NETWORK, CHAINACCOUNT, CL,
              CHAIN>>> getResponse(WalletProvider provider) async {
    final chain = await getCurrentChain(provider);
    return chain.andThenAsync((chain) async {
      final address = chain.addressSyncOrNull;
      if (address == null) {
        return ResultErr.fromException(AppException("page_required_address"));
      }
      if (onlyMultisig && !address.multiSigAccount) {
        return ResultErr.fromException(AppException("page_required_multisig_address"));
      }
      return ResultOk(NetworkViewActionResponseAccount(
          provider: provider, chain: chain, address: address));
    });
  }
}

class NetworkViewActionAccountAndClient<
    NETWORKADDRESS extends IAddress,
    NETWORK extends WalletNetwork,
    CHAINACCOUNT extends ACCOUNADDRESSNETWORK<NETWORKADDRESS, NETWORK>,
    CL extends CLIENTNADDRESSNETWORK<NETWORKADDRESS, NETWORK>,
    CHAIN extends APPCHAINADDRESSNETWORKACCOUNTCLIENT<NETWORKADDRESS, NETWORK,
        CHAINACCOUNT, CL>> extends NetworkViewAction<
    NETWORKADDRESS,
    NETWORK,
    CHAINACCOUNT,
    CL,
    CHAIN,
    NetworkViewActionResponseAccountAndClient<NETWORKADDRESS, NETWORK, CHAINACCOUNT, CL,
        CHAIN>> {
  final bool onlyMultisig;
  const NetworkViewActionAccountAndClient({super.chain, this.onlyMultisig = false});

  @override
  Future<
      IResult<
          NetworkViewActionResponseAccountAndClient<NETWORKADDRESS, NETWORK, CHAINACCOUNT,
              CL, CHAIN>>> getResponse(WalletProvider provider) async {
    final chain = await getCurrentChain(provider);
    return chain.andThenAsync((chain) async {
      final address = chain.addressSyncOrNull;
      if (address == null) {
        return ResultErr.fromException(AppException("page_required_address"));
      }
      if (onlyMultisig && !address.multiSigAccount) {
        return ResultErr.fromException(AppException("page_required_multisig_address"));
      }
      final client = await chain.client();
      return client.map((client) => NetworkViewActionResponseAccountAndClient(
          provider: provider, chain: chain, address: address, client: client));
    });
  }
}

class NetworkViewActionContacts<
    NETWORKADDRESS extends IAddress,
    NETWORK extends WalletNetwork,
    CHAINACCOUNT extends ACCOUNADDRESSNETWORK<NETWORKADDRESS, NETWORK>,
    CL extends CLIENTNADDRESSNETWORK<NETWORKADDRESS, NETWORK>,
    CHAIN extends APPCHAINADDRESSNETWORKACCOUNTCLIENT<NETWORKADDRESS, NETWORK,
        CHAINACCOUNT, CL>> extends NetworkViewAction<
    NETWORKADDRESS,
    NETWORK,
    CHAINACCOUNT,
    CL,
    CHAIN,
    NetworkViewActionResponseContacts<NETWORKADDRESS, NETWORK, CHAINACCOUNT, CL, CHAIN>> {
  const NetworkViewActionContacts({super.chain});

  @override
  Future<
      IResult<
          NetworkViewActionResponseContacts<NETWORKADDRESS, NETWORK, CHAINACCOUNT, CL,
              CHAIN>>> getResponse(WalletProvider provider) async {
    final chain = await getCurrentChain(provider);
    return chain.andThenAsync((chain) async {
      final contacts = await chain.getAccountContacts();
      return contacts.map((contacts) => NetworkViewActionResponseContacts(
          provider: provider, chain: chain, contacts: contacts));
    });
  }
}

sealed class NetworkViewActionResponse<
    NETWORKADDRESS extends IAddress,
    NETWORK extends WalletNetwork,
    CHAINACCOUNT extends ACCOUNADDRESSNETWORK<NETWORKADDRESS, NETWORK>,
    CL extends CLIENTNADDRESSNETWORK<NETWORKADDRESS, NETWORK>,
    CHAIN extends APPCHAINADDRESSNETWORKACCOUNTCLIENT<NETWORKADDRESS, NETWORK,
        CHAINACCOUNT, CL>> {
  final CHAIN chain;
  final WalletProvider provider;
  const NetworkViewActionResponse({required this.provider, required this.chain});
}

class NetworkViewActionResponseChain<
        NETWORKADDRESS extends IAddress,
        NETWORK extends WalletNetwork,
        CHAINACCOUNT extends ACCOUNADDRESSNETWORK<NETWORKADDRESS, NETWORK>,
        CL extends CLIENTNADDRESSNETWORK<NETWORKADDRESS, NETWORK>,
        CHAIN extends APPCHAINADDRESSNETWORKACCOUNTCLIENT<NETWORKADDRESS, NETWORK,
            CHAINACCOUNT, CL>>
    extends NetworkViewActionResponse<NETWORKADDRESS, NETWORK, CHAINACCOUNT, CL, CHAIN> {
  final CHAINACCOUNT? address;
  const NetworkViewActionResponseChain(
      {required super.provider, required super.chain, this.address});
}

class NetworkViewActionResponseAccount<
        NETWORKADDRESS extends IAddress,
        NETWORK extends WalletNetwork,
        CHAINACCOUNT extends ACCOUNADDRESSNETWORK<NETWORKADDRESS, NETWORK>,
        CL extends CLIENTNADDRESSNETWORK<NETWORKADDRESS, NETWORK>,
        CHAIN extends APPCHAINADDRESSNETWORKACCOUNTCLIENT<NETWORKADDRESS, NETWORK,
            CHAINACCOUNT, CL>>
    extends NetworkViewActionResponse<NETWORKADDRESS, NETWORK, CHAINACCOUNT, CL, CHAIN> {
  final CHAINACCOUNT address;
  const NetworkViewActionResponseAccount(
      {required super.provider, required super.chain, required this.address});
}

class NetworkViewActionResponseAccountAndClient<
        NETWORKADDRESS extends IAddress,
        NETWORK extends WalletNetwork,
        CHAINACCOUNT extends ACCOUNADDRESSNETWORK<NETWORKADDRESS, NETWORK>,
        CL extends CLIENTNADDRESSNETWORK<NETWORKADDRESS, NETWORK>,
        CHAIN extends APPCHAINADDRESSNETWORKACCOUNTCLIENT<NETWORKADDRESS, NETWORK,
            CHAINACCOUNT, CL>>
    extends NetworkViewActionResponse<NETWORKADDRESS, NETWORK, CHAINACCOUNT, CL, CHAIN> {
  final CHAINACCOUNT address;
  final CL client;
  const NetworkViewActionResponseAccountAndClient(
      {required super.provider,
      required super.chain,
      required this.address,
      required this.client});
}

class NetworkViewActionResponseContacts<
        NETWORKADDRESS extends IAddress,
        NETWORK extends WalletNetwork,
        CHAINACCOUNT extends ACCOUNADDRESSNETWORK<NETWORKADDRESS, NETWORK>,
        CL extends CLIENTNADDRESSNETWORK<NETWORKADDRESS, NETWORK>,
        CHAIN extends APPCHAINADDRESSNETWORKACCOUNTCLIENT<NETWORKADDRESS, NETWORK,
            CHAINACCOUNT, CL>>
    extends NetworkViewActionResponse<NETWORKADDRESS, NETWORK, CHAINACCOUNT, CL, CHAIN> {
  final List<NetworkContact<NETWORKADDRESS>> contacts;
  NetworkViewActionResponseContacts({
    required super.provider,
    required super.chain,
    required List<NetworkContact<NETWORKADDRESS>> contacts,
  }) : contacts = contacts.immutable;
}
