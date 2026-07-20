import 'package:blockchain_utils/bip/bip/bip.dart';
import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/bip/monero/monero_subaddr.dart';
import 'package:blockchain_utils/bip/substrate/conf/substrate_coins.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/types/next_derivation.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/networks/monero/account/account.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/models/account/account.dart';

class BipDerivationUtils {
  static const String substrateBaseAccount = "//44//60//0/0/";
  static NetDerivation generateAccountNextKeyIndex(
      {required CryptoCoins coin,
      required SeedTypes seedGenerationType,
      List<ChainAccount> addresses = const [],
      int? coinIndex,
      int? subId,
      // DerivableIndex? startIndex,
      List<DerivableIndex> exclude = const []}) {
    switch (coin) {
      case SubstrateCoins coin:
        return findNextSubstratePath(
            coin: coin, addresses: addresses, subId: subId, exclude: exclude);
      case BipCoins coin:
        if (coin.proposal == CoinProposal.cip0019) {
          return findNextByronLegacyIndex(
              coin: coin, addresses: addresses, subId: subId, exclude: exclude);
        }
        final conf = coin.conf;
        return findNextBipCoin(
            coin: coin,
            addresses: addresses,
            seedGenerationType: seedGenerationType,
            coinIndex: coinIndex,
            defPath: conf.defPath);
      case ZIP32Coins coin:
        return findNextZipCoin(
          coin: coin,
          addresses: addresses.cast(),
          seedGenerationType: seedGenerationType,
        );
      default:
        throw AppCryptoExceptionConst.invalidCoin;
    }
  }

  static NextDerivationMonero findMoneroNextBip32Index(
      {required BipCoins coin,
      required List<IMoneroAddress> addresses,
      required SeedTypes seedGenerationType,
      DerivableIndex? startIndex,
      int? subId}) {
    assert(startIndex == null || startIndex is Bip32DerivationIndex);
    Bip32DerivationIndex? defaultIndex = switch (startIndex) {
      Bip32DerivationIndex index => index,
      _ => Bip32DerivationIndex.defaultBip(coin: coin, seedGeneration: seedGenerationType)
    };
    if (subId != null) {
      defaultIndex = defaultIndex.asSubWalletKey(subId);
    }
    int major = 0;
    int minor = 0;
    while (true) {
      final index = MoneroAccountIndex(
          masterIndex: defaultIndex, index: MoneroSubIndex(major: major, minor: minor));
      if (!addresses.any((e) => e.index == index)) {
        return NextDerivationMonero(
            nextIndex: defaultIndex, index: MoneroSubIndex(major: major, minor: minor));
      }
      minor++;
      if (minor > MoneroSubaddressConst.subaddrMaxIdx) break;
    }
    throw WalletExceptionConst.tooManyAccounts;
  }

  static NextDerivationDefault findNextBipCoin(
      {required BipCoins coin,
      required List<ChainAccount> addresses,
      required SeedTypes seedGenerationType,
      required String defPath,
      List<DerivableIndex> exclude = const [],
      int? subId,
      int? coinIndex}) {
    final List<DerivableIndex> existsIndexes = [
      ...exclude,
      ...addresses.expand(
          (e) => e.derivableIndexes(request: AccountDerivationIndexRequestAddress()))
    ];

    Bip32DerivationIndex? defaultIndex =
        Bip32DerivationIndex.defaultBip(coin: coin, seedGeneration: seedGenerationType);
    if (subId != null) {
      defaultIndex = defaultIndex.asSubWalletKey(subId);
    }
    if (coinIndex != null) {
      defaultIndex =
          defaultIndex.copyWith(coin: Bip32KeyIndex.hardenIndex(coinIndex).index);
    }
    while (defaultIndex != null) {
      if (!existsIndexes.contains(defaultIndex)) {
        return NextDerivationDefault(defaultIndex);
      }
      defaultIndex = defaultIndex.tryIncrementLatestLevel();
    }

    throw WalletExceptionConst.tooManyAccounts;
  }

  static NextDerivationZip32 findNextZipCoin(
      {required ZIP32Coins coin,
      required List<IZcashAddress> addresses,
      required SeedTypes seedGenerationType,
      // required String defPath,
      int? subId,
      int? coinIndex,
      Bip32DerivationIndex? startIndex}) {
    final protocol = switch (coin.conf.type) {
      EllipticCurveTypes.redJubJub => ZcashProtocol.sapling,
      EllipticCurveTypes.redPallas => ZcashProtocol.orchard,
      _ => throw AppCryptoExceptionConst.invalidCoin
    };
    final List<ZcashAccountInfoShield> receivers = addresses
        .expand((e) => e.multiSigAccount
            ? <ZcashAccountInfoShield>[]
            : e.account.receivers.whereType<ZcashAccountInfoShield>())
        .toList()
        .where((e) => e.type.protocol == protocol)
        .toList();
    final diversifiers = receivers.map((e) => e.diversifierIndex).toList()..sort();
    Bip32DerivationIndex? defaultIndex = startIndex ??
        Bip32DerivationIndex.defaultZip(coin: coin, seedGeneration: seedGenerationType);
    if (subId != null) {
      defaultIndex = defaultIndex.asSubWalletKey(subId);
    }
    if (coinIndex != null) {
      defaultIndex =
          defaultIndex.copyWith(coin: Bip32KeyIndex.hardenIndex(coinIndex).index);
    }
    DiversifierIndex? diversifierIndex =
        diversifiers.lastOrNull ?? DiversifierIndex.zero();
    if (protocol.isOrchard) {
      diversifierIndex = DiversifierIndex.zero();
    }
    while (diversifierIndex != null) {
      if (!diversifiers.contains(diversifierIndex)) {
        return NextDerivationZip32(
            nextIndex: defaultIndex, nextDiversifier: diversifierIndex);
      }
      diversifierIndex = diversifierIndex.tryIncrement();
    }
    return NextDerivationZip32(
        nextIndex: defaultIndex, nextDiversifier: DiversifierIndex.zero());
  }

  static NetDerivation findNextByronLegacyIndex(
      {required BipCoins coin,
      required List<ChainAccount> addresses,
      required List<DerivableIndex> exclude,
      int? subId}) {
    final List<DerivableIndex> addressIndex = [
      ...exclude,
      ...addresses.expand(
          (e) => e.derivableIndexes(request: AccountDerivationIndexRequestAddress()))
    ];
    Bip32DerivationIndex? defaultIndex = Bip32DerivationIndex.byronLegacy(
      firstIndex: 0,
      secoundIndex: 0,
      currencyCoin: coin,
    );
    if (subId != null) {
      defaultIndex = defaultIndex.asSubWalletKey(subId);
    }
    while (defaultIndex != null) {
      if (!addressIndex.contains(defaultIndex)) {
        return NextDerivationDefault(defaultIndex);
      }
      defaultIndex = defaultIndex.tryIncrementLatestLevel();
    }
    throw WalletExceptionConst.tooManyAccounts;
  }

  static NextDerivationSubstrate findNextSubstratePath({
    required SubstrateCoins coin,
    required List<ChainAccount> addresses,
    required List<DerivableIndex> exclude,
    int? subId,
  }) {
    final List<DerivableIndex> addressIndex = [
      ...exclude,
      ...addresses
          .expand(
              (e) => e.derivableIndexes(request: AccountDerivationIndexRequestAddress()))
          .whereType<SubstrateDerivationIndex>()
    ];

    for (int i = 0; i < Bip32KeyDataConst.keyIndexMaxVal; i++) {
      SubstrateDerivationIndex newKeyIndex = SubstrateDerivationIndex(
          currencyCoin: coin, substratePath: "$substrateBaseAccount$i");
      if (subId != null) {
        newKeyIndex = newKeyIndex.asSubWalletKey(subId);
      }
      if (!addressIndex.contains(newKeyIndex)) {
        return NextDerivationSubstrate(newKeyIndex);
      }
    }
    throw WalletExceptionConst.tooManyAccounts;
  }
}
