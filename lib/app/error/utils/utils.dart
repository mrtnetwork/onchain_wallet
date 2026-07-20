import 'dart:async';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cosmos_sdk/cosmos_sdk.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain/exception/exception.dart';
import 'package:on_chain/serialization/cbor_serialization.dart';
import 'package:on_chain_bridge/exception/exception.dart';
import 'package:on_chain_bridge/net_sdk/exception/exception.dart';
import 'package:on_chain_bridge/net_sdk/types/status.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_bridge/serialization/src/tags.dart';
import 'package:on_chain_swap/on_chain_swap.dart'
    show OnChainSwapSerializationIdentifier, DartOnChainSwapPluginException;
import 'package:on_chain_wallet/app/error/exception/app_exception.dart';
import 'package:on_chain_wallet/app/error/exception/exception.dart';
import 'package:on_chain_wallet/app/error/exception/wallet_ex.dart';
import 'package:on_chain_wallet/app/serialization/serialization/tags.dart';
import 'package:on_chain_wallet/network/bridge/exception/exception.dart';
import 'package:on_chain_wallet/context/exception/exception.dart';
import 'package:on_chain_wallet/wallet/api/service/exception/bridge.dart';
import 'package:on_chain_wallet/web3/web3/core/exception/exception.dart';
import 'package:polkadot_dart/polkadot_dart.dart';
import 'package:stellar_dart/stellar_dart.dart';
import 'package:ton_dart/ton_dart.dart';
import 'package:zcash_dart/zcash.dart'
    show BaseDartZcashPluginException, ZcashSerializationIdentifier;
import 'package:xrpl_dart/xrpl_dart.dart';

class IExceptionUtils {
  static IException findError(Object? exception) {
    if (exception is BaseAppException) return exception;
    if (exception is NetSdkException) {
      return APIError.fromNetSdk(exception, url: null);
    }
    if (exception is RPCError) {
      return APIError.fromException(message: exception);
    }
    if (exception is NetResultStatus) {
      assert(!exception.isOk());
      return APIError.fromNetSdk(NetSdkException(exception), url: null);
    }
    if (exception is IException) {
      return AppInternalError(
        interalError: exception,
        where: exception.relatedNetwork?.name,
      );
    }

    final String? err = switch (exception) {
      FormatException _ => "format_exception",
      TimeoutException _ => "timeout_exception",
      RangeError _ => "range_error",
      ArgumentError _ => "argument_error",
      StateError _ => "state_error",
      UnimplementedError _ => "unimplemented_error",
      UnsupportedError _ => "unsupported_error",
      AssertionError _ => "assertion_error",
      TypeError _ => "type_error",
      _ => null
    };
    // assert(err != null, "Unexpected error type ${exception.runtimeType}");
    return AppInternalError(message: err, details: {
      "error": (() {
        try {
          return exception?.toString();
        } catch (_) {
          return null;
        }
      }())
    });
  }

  static IException deserialize({List<int>? bytes, CborObject? object}) {
    final decode = AppSerialization.decodeTaggedValueWithInfo<SerializationIdentifier>(
        cborBytes: bytes,
        cborObject: object,
        expectedTags: [
          AppSerializationIdentifier.apiError,
          AppSerializationIdentifier.appError,
          AppSerializationIdentifier.walletError,
          AppSerializationIdentifier.walletConnectError,
          AppSerializationIdentifier.appInternalError,
          AppSerializationIdentifier.appCryptoError,
          AppSerializationIdentifier.web3RequestClosed,
          AppSerializationIdentifier.web3RequestError,
          AppSerializationIdentifier.networkClientError,
          AppSerializationIdentifier.appContextError,
          ...BlockchainUtilsSerializationIdentifier.values,
          ...OnChainSerializationIdentifiers.values,
          ...MoneroSerializationIdentifiers.values,
          ...CosmosSerializationIdentifiers.values,
          ...TonSerializationIdentifiers.values,
          ...BitcoinSerializationIdentifiers.values,
          ...ZcashSerializationIdentifier.values,
          ...XRPLSerializationIdentifiers.values,
          ...OnChainBrdigeSerializationIdentifier.values,
          ...OnChainSwapSerializationIdentifier.values,
          ...PolkadotSerializationIdentifiers.values,
          ...StellarSerializationIdentifiers.values,
        ]);
    return switch (decode.identifier) {
      AppSerializationIdentifier.apiError => APIError.deserialize(object: decode.tag),
      AppSerializationIdentifier.appError => AppException.deserialize(object: decode.tag),
      AppSerializationIdentifier.networkClientError =>
        NetworkClientError.deserialize(object: decode.tag),
      AppSerializationIdentifier.walletError =>
        WalletException.deserialize(object: decode.tag),
      AppSerializationIdentifier.walletConnectError =>
        BridgeException.deserialize(object: decode.tag),
      AppSerializationIdentifier.appInternalError =>
        AppInternalError.deserialize(object: decode.tag),
      AppSerializationIdentifier.appCryptoError =>
        AppCryptoException.deserialize(object: decode.tag),
      AppSerializationIdentifier.web3RequestClosed =>
        Web3RequestClosed.deserialize(object: decode.tag),
      AppSerializationIdentifier.web3RequestError =>
        Web3RequestException.deserialize(object: decode.tag),
      BlockchainUtilsSerializationIdentifier _ =>
        IException.deserialize(object: decode.tag),
      OnChainSerializationIdentifiers _ =>
        OnChainPluginException.deserialize(obj: decode.tag),
      MoneroSerializationIdentifiers _ =>
        BaseDartMoneroPluginException.deserialize(obj: decode.tag),
      CosmosSerializationIdentifiers _ =>
        BaseDartCosmosSdkPluginException.deserialize(obj: decode.tag),
      TonSerializationIdentifiers _ =>
        BaseTonDartPluginException.deserialize(obj: decode.tag),
      BitcoinSerializationIdentifiers _ =>
        DartBitcoinPluginException.deserialize(object: decode.tag),
      ZcashSerializationIdentifier _ =>
        BaseDartZcashPluginException.deserialize(obj: decode.tag),
      XRPLSerializationIdentifiers _ =>
        BaseXRPLPluginException.deserialize(obj: decode.tag),
      OnChainBrdigeSerializationIdentifier _ =>
        BaseOnChainBridgeException.deserialize(obj: decode.tag),
      OnChainSwapSerializationIdentifier _ =>
        DartOnChainSwapPluginException.deserialize(obj: decode.tag),
      PolkadotSerializationIdentifiers _ =>
        BaseDartSubstratePluginException.deserialize(obj: decode.tag),
      StellarSerializationIdentifiers _ =>
        BaseDartStellarPlugingException.deserialize(obj: decode.tag),
      AppSerializationIdentifier.appContextError =>
        AppContextError.deserialize(object: decode.tag),
      _ => throw AppInternalError.internalError("IException.deserialize",
          details: {"tag": decode.tag.tags.join(",")})
    };
  }
}
