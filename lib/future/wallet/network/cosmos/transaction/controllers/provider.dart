import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';
import 'package:cosmos_sdk/cosmos_sdk.dart';
import 'package:cosmos_sdk/proto_messages/cosmos/base/v1beta1/models.dart';
import 'package:cosmos_sdk/proto_messages/cosmos/tx/v1beta1/models.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/transaction/types/types.dart';
import 'package:on_chain_wallet/future/wallet/network/cosmos/web3/types/fee.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/networks.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/network/core/network.dart';
import 'package:on_chain_wallet/wallet/models/networks/cosmos/cosmos.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart';
import 'package:on_chain_wallet/wallet/models/token/token_core/networks/cw20.dart';

mixin CosmosTransactionApiController on DisposableMixin {
  CosmosNetworkClient get client;
  WalletCosmosNetwork get network;

  Future<CosmosTransactionRequirment> getTransactionRequirment({
    required ICosmosAddress owner,
    Fee? fee,
  }) async {
    CosmosBaseAddress payerAddress = owner.networkAddress;
    final payer = fee?.payer;
    if (payer != null) {
      payerAddress = CosmosBaseAddress(payer);
    }
    bool ownerIsPayer = owner.networkAddress == payerAddress;
    List<Coin> balances = [];
    final payerAccount = await client.tryGetAccount(payerAddress);
    BigInt? fixedFee;
    final averageGasPrice = network.coinParam.getFeeToken().getAverageGasPrice();
    if (network.coinParam.networkType == CosmosNetworkTypes.thorAndForked) {
      final fee = await IResult.call(() async {
        final networkConst = await client.getThorNodeConstants();
        return BigInt.from(networkConst.nativeTransactionFee);
      });

      assert(fee.isOk,
          "failed to fetch ${network.networkName} native trasaction fee: ${fee.err()?.localizationError}");
      fixedFee = fee.unwrapOr(
        (_) => averageGasPrice.balance,
      );
    }
    BigRational? ethermintTxFee;
    if (network.coinParam.networkType.isEthreum) {
      ethermintTxFee = BigRational.parseDecimal(averageGasPrice.price);
    }
    if (payerAccount != null) {
      balances = await client.getAddressCoins(payerAddress);
    }
    final tokens = (await owner.getAccountTokens()).unwrap();
    final List<CW20Token> feeTokens =
        List.generate(network.coinParam.feeTokens.length, (i) {
      final token = network.coinParam.feeTokens[i];
      CW20Token? feeToken;
      Token viewToken = token.token;
      if (ownerIsPayer) {
        viewToken =
            tokens.firstWhereOrNull((e) => e.denom == token.denom)?.token ?? viewToken;
      }

      return feeToken ??
          CW20Token.create(
              balance:
                  balances.firstWhereOrNull((e) => e.denom == token.denom)?.getAmount() ??
                      BigInt.zero,
              token: viewToken,
              denom: token.denom);
    });
    if (fee != null) {
      for (final i in fee.amount) {
        final token = feeTokens.firstWhereOrNull((e) => e.denom == i.denom);
        if (token == null) {
          try {
            final tokenMetadata = await client.getTokenMetadata(i.getDenom());
            if (tokenMetadata == null) {
              throw WalletExceptionConst.feeTokenNotFound;
            }
            feeTokens.add(tokenMetadata);
          } on APIError catch (e) {
            if (CosmosProviderUtils.itemNotFound(e.errorCode)) {
              throw WalletExceptionConst.feeTokenNotFound;
            }
            rethrow;
          }
        }
      }
    }

    return CosmosTransactionRequirment(
        account: payerAccount,
        feeTokens: feeTokens,
        fixedNativeGas: fixedFee,
        ethermintTxFee: ethermintTxFee);
  }

  Future<CosmosWeb3SimulateInfos> simulateWeb3Transaction(List<int> txBytes,
      {List<ICosmosProtoServiceMessage> txMessages = const []}) async {
    final result = await client.simulateTx(txBytes);
    return CosmosWeb3SimulateInfos(result);
  }
}
