import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
import 'package:cosmos_sdk/proto_messages/cosmos/base/v1beta1/src/coin.dart';
import 'package:cosmos_sdk/proto_messages/cosmos/tx/v1beta1/src/tx.dart';
import 'package:cosmos_sdk/sdk/serialization/buffer/any.dart';
import 'package:on_chain_wallet/app/core.dart';

extension ExtCosmosCoin on Coin {
  BigInt getAmount() {
    return BigintUtils.parse(amount ?? "0");
  }

  String getDenom() {
    final denom = this.denom;
    if (denom == null || denom.isEmpty) {
      throw AppInternalError.internalError("getDenom",
          reason: "Invalid coin denom", details: {"denom": denom});
    }
    return denom;
  }
}

extension ExtCosmosAuthInfo on AuthInfo {
  AuthInfo copyWith({
    List<SignerInfo>? signerInfos,
    Fee? fee,
    Tip? tip,
  }) {
    return AuthInfo(
        signerInfos: signerInfos ?? this.signerInfos,
        fee: fee ?? this.fee,
        tip: tip ?? this.tip);
  }
}

extension ExtCosmosSignerInfo on SignerInfo {
  SignerInfo copyWith({
    Any? publicKey,
    ModeInfo? modeInfo,
    BigInt? sequence,
  }) {
    return SignerInfo(
        publicKey: publicKey ?? this.publicKey,
        modeInfo: modeInfo ?? this.modeInfo,
        sequence: sequence ?? this.sequence);
  }
}
