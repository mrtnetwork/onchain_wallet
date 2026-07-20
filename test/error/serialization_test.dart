import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:cosmos_sdk/cosmos_sdk.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_bridge/database/exception/exception.dart';
import 'package:on_chain_bridge/exception/exception.dart';
import 'package:on_chain_bridge/models/barcode/exception/exception.dart';
import 'package:on_chain_bridge/net_sdk/exception/exception.dart';
import 'package:on_chain_bridge/net_sdk/transport/authenticated/exception.dart';
import 'package:on_chain_bridge/net_sdk/types/status.dart';
import 'package:on_chain_bridge/serialization/src/exception.dart';
import 'package:on_chain_swap/on_chain_swap.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/network/bridge/exception/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/exception/exception.dart';
import 'package:on_chain_wallet/web3/web3/networks/bitcoin/constant/constants/exception.dart';
import 'package:polkadot_dart/polkadot_dart.dart';
import 'package:stellar_dart/stellar_dart.dart';
import 'package:test/test.dart';
import 'package:ton_dart/ton_dart.dart';
import 'package:xrpl_dart/xrpl_dart.dart';
import 'package:zcash_dart/zcash.dart';

void main() {
  test('serialization error', () {
    {
      final error = AppExceptionConst.failedToReadFileContent;
      final decode = IExceptionUtils.deserialize(bytes: error.toCbor().encode());
      expect(error, decode);
    }
    {
      final error = APIError.fromException(
          message: RPCError(message: "msg", details: {"error": "e"}, errorCode: 12),
          url: "example.com");
      final decode = IExceptionUtils.deserialize(bytes: error.toCbor().encode());
      expect(error, decode);
    }
    {
      final error = WalletExceptionConst.accountDoesNotFound;
      final decode = IExceptionUtils.deserialize(bytes: error.toCbor().encode());
      expect(error, decode);
    }
    {
      final error = BridgeExceptionConst.badPublishMessageStatus;
      final decode = IExceptionUtils.deserialize(bytes: error.toCbor().encode());
      expect(error, decode);
    }
    {
      final error = AppInternalError.internalError("w");
      final decode = IExceptionUtils.deserialize(bytes: error.toCbor().encode());
      expect(error, decode);
    }
    {
      final error = Web3RequestClosed.instance;
      final decode = IExceptionUtils.deserialize(bytes: error.toCbor().encode());
      expect(error, decode);
    }
    {
      final error = Web3BitcoinExceptionConstant.emptyOutput;
      final decode = IExceptionUtils.deserialize(bytes: error.toCbor().encode());
      expect(error, decode);
    }
    {
      final error = IDatabaseException.onDatabaseBlockError;
      final decode = IExceptionUtils.deserialize(bytes: error.toCbor().encode());
      expect(error, decode);
    }
    {
      final error = NetSdkException(NetResultStatus.closed);
      final decode = IExceptionUtils.deserialize(bytes: error.toCbor().encode());
      expect(error, decode);
    }
    {
      final error = BarcodeException.serviceAlreadyRunnig;
      final decode = IExceptionUtils.deserialize(bytes: error.toCbor().encode());
      expect(error, decode);
    }
    {
      final error = HttpDigestAuthenticatedError.invalidOrUnsuportedDigestAuth;
      final decode = IExceptionUtils.deserialize(bytes: error.toCbor().encode());
      expect(error, decode);
    }
    {
      final error = OnChainSerializationException();
      final decode = IExceptionUtils.deserialize(bytes: error.toCbor().encode());
      expect(error, decode);
    }

    {
      final error = OnChainBridgeException.unexpectedError;
      final decode = IExceptionUtils.deserialize(bytes: error.toCbor().encode());
      expect(error, decode);
    }

    {
      final error = DartOnChainSwapPluginException("error");
      final decode = IExceptionUtils.deserialize(bytes: error.toCbor().encode());
      expect(error, decode);
    }
    {
      final error = ETHPluginException("error");
      final decode = OnChainPluginException.deserialize(
        cborBytes: error.toCbor().encode(),
      );
      expect(decode, error);
    }
    {
      final error = EIP4631Exception("error");
      final decode = OnChainPluginException.deserialize(
        cborBytes: error.toCbor().encode(),
      );
      expect(decode, error);
    }
    {
      final error = DartZcashPluginException("error");
      final decode = BaseDartZcashPluginException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(decode, error);
    }
    {
      final error = ZcashAddressException("error");
      final decode = BaseDartZcashPluginException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(decode, error);
    }
    {
      final error = ThorNodeApiException("error", details: {"length": "32"});
      final decode = BaseDartCosmosSdkPluginException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(decode, error);
    }
    {
      final error = DartBitcoinPluginException("error", details: {"length": "32"});
      final decode = DartBitcoinPluginException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(decode, error);
    }
    {
      final error = MoneroSerializationException("error", details: {"length": "32"});
      final decode = BaseDartMoneroPluginException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(decode, error);
    }
    {
      final error = TupleException("error", details: {"length": "32"});
      final decode = BaseTonDartPluginException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(decode, error);
    }
    {
      final error = XRPLAddressCodecException("error", details: {"length": "32"});
      final decode = BaseXRPLPluginException.deserialize(bytes: error.toCbor().encode());
      expect(decode, error);
    }
    {
      final error = DartSubstratePluginException("error", details: {"length": "32"});
      final decode = BaseDartSubstratePluginException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(decode, error);
    }
    {
      const error = DartStellarPlugingException("error", details: {"length": "32"});
      final decode = BaseDartStellarPlugingException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(decode, error);
    }
    {
      const error = StellarAddressException("error", details: {"length": "32"});
      final decode = BaseDartStellarPlugingException.deserialize(
        bytes: error.toCbor().encode(),
      );
      expect(decode, error);
    }
  });
}
