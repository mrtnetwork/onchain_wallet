import 'package:blockchain_utils/bip/bip.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/wallet/models/networks/monero/account/account.dart';

sealed class NetDerivation<DERIVABLEINDEX extends DerivableIndex> {
  final DERIVABLEINDEX nextIndex;
  const NetDerivation(this.nextIndex);

  T cast<T extends NetDerivation>() {
    if (this is! T) {
      throw AppInternalError.internalError("NetDerivation");
    }
    return this as T;
  }

  NetDerivation<DERIVABLEINDEX> copyWith({DERIVABLEINDEX? nextIndex});
}

class NextDerivationDefault extends NetDerivation<Bip32DerivationIndex> {
  const NextDerivationDefault(super.nextIndex);

  @override
  NextDerivationDefault copyWith({Bip32DerivationIndex? nextIndex}) {
    return NextDerivationDefault(nextIndex ?? this.nextIndex);
  }
}

class NextDerivationSubstrate extends NetDerivation<SubstrateDerivationIndex> {
  const NextDerivationSubstrate(super.nextIndex);

  @override
  NetDerivation<SubstrateDerivationIndex> copyWith(
      {SubstrateDerivationIndex? nextIndex}) {
    return NextDerivationSubstrate(nextIndex ?? this.nextIndex);
  }
}

class NextDerivationZip32 extends NetDerivation<Bip32DerivationIndex> {
  const NextDerivationZip32(
      {required Bip32DerivationIndex nextIndex, required this.nextDiversifier})
      : super(nextIndex);
  final DiversifierIndex nextDiversifier;

  @override
  NextDerivationZip32 copyWith(
      {Bip32DerivationIndex? nextIndex, DiversifierIndex? nextDiversifier}) {
    return NextDerivationZip32(
        nextIndex: nextIndex ?? this.nextIndex,
        nextDiversifier: nextDiversifier ?? this.nextDiversifier);
  }
}

class NextDerivationMonero extends NetDerivation<Bip32DerivationIndex> {
  const NextDerivationMonero(
      {required Bip32DerivationIndex nextIndex, required this.index})
      : super(nextIndex);
  final MoneroSubIndex index;

  @override
  NetDerivation<Bip32DerivationIndex> copyWith(
      {Bip32DerivationIndex? nextIndex, MoneroSubIndex? index}) {
    return NextDerivationMonero(
        nextIndex: nextIndex ?? this.nextIndex, index: index ?? this.index);
  }
}

sealed class NetDerivationRequest {
  final CryptoCoins coin;
  const NetDerivationRequest({required this.coin});
  T cast<T extends NetDerivationRequest>() {
    if (this is! T) {
      throw AppInternalError.internalError("NetDerivation");
    }
    return this as T;
  }
}

sealed class AddressDerivedIndex<DERIVABLEINDEX extends DerivableIndex> {
  DERIVABLEINDEX get derivableIndex;
}

class DefaultAddressDeivedIndex
    with Equality
    implements AddressDerivedIndex<Bip32DerivationIndex> {
  final Bip32DerivationIndex index;
  const DefaultAddressDeivedIndex(this.index);

  @override
  List<dynamic> get variables => [index];

  @override
  Bip32DerivationIndex get derivableIndex => index;
}

class MoneroAddressDeivedIndex
    with Equality
    implements AddressDerivedIndex<Bip32DerivationIndex> {
  final MoneroAccountIndex index;
  const MoneroAddressDeivedIndex(this.index);

  @override
  List<dynamic> get variables => [index];

  @override
  Bip32DerivationIndex get derivableIndex => index.masterIndex;
}

sealed class NetDerivationBuilder<
    DERIVABLEINDEX extends DerivableIndex,
    DERIVATION extends NetDerivation<DERIVABLEINDEX>,
    COIN extends CryptoCoins,
    INDEX extends AddressDerivedIndex<DERIVABLEINDEX>> {
  final COIN coin;
  final List<INDEX> indexes;
  final SeedTypes seedGenerationType;
  const NetDerivationBuilder(
      {required this.indexes, required this.coin, required this.seedGenerationType});
  DERIVABLEINDEX defaultIndex(
      {ViewSubWalletKey? subId, ViewImportedSecretKey? importedKey});
  DERIVABLEINDEX masterIndex(
      {ViewSubWalletKey? subId, ViewImportedSecretKey? importedKey});
  DERIVATION next(
      {DERIVATION? currentIndex,
      ViewSubWalletKey? subId,
      ViewImportedSecretKey? importedKey});

  bool isValidIndex(DERIVABLEINDEX currentIndex,
      {ViewSubWalletKey? subId, ViewImportedSecretKey? importedKey}) {
    if (currentIndex.currencyCoin != coin) return false;
    if (currentIndex.seedGeneration != seedGenerationType) return false;
    if (currentIndex.subId != subId?.id) return false;
    if (currentIndex.importedKeyId != importedKey?.id) return false;
    if (subId != null && !subId.type.allowDerivation && !currentIndex.isMaster) {
      return false;
    }
    if (importedKey != null &&
        !importedKey.allowDerivation(coin) &&
        !currentIndex.isMaster) {
      return false;
    }
    return true;
  }

  DERIVATION getDefaultDerivation(
      {ViewSubWalletKey? subId, ViewImportedSecretKey? importedKey});
  DERIVABLEINDEX getDefaultDerivationIndex(
      {ViewSubWalletKey? subId, ViewImportedSecretKey? importedKey}) {
    assert([subId, importedKey].where((e) => e != null).length < 2,
        "Invalid derivation request.");
    if (subId != null) {
      if (subId.type.allowDerivation) {
        return defaultIndex(subId: subId);
      }
      return masterIndex(subId: subId);
    }
    if (importedKey != null) {
      if (importedKey.allowDerivation(coin)) {
        return defaultIndex(importedKey: importedKey);
      }
      return masterIndex(importedKey: importedKey);
    }
    return defaultIndex();
  }
}

// class BipCoinDerivationBuilder extends NetDerivationBuilder<Bip32DerivationIndex,
//     NextDerivationDefault, BipCoins, DefaultAddressDeivedIndex> {
//   final int? coinId;
//   BipCoinDerivationBuilder(
//       {required super.indexes,
//       required super.coin,
//       required super.seedGenerationType,
//       this.coinId});

//   @override
//   NextDerivationDefault next({int? subId, int? importedKey}) {
//     Bip32DerivationIndex? defaultIndex = currentIndex ?? this.defaultIndex();
//     final indexes = this.indexes.map((e) => e.index).toList();
//     final subId = this.subId;
//     if (subId != null && defaultIndex.subId != subId) {
//       defaultIndex = defaultIndex.asSubWalletKey(subId);
//     }
//     final coinId = this.coinId;
//     if (coinId != null) {
//       defaultIndex = defaultIndex.copyWith(coin: Bip32KeyIndex.hardenIndex(coinId).index);
//     }
//     while (defaultIndex != null) {
//       if (!indexes.contains(defaultIndex)) {
//         return NextDerivationDefault(defaultIndex);
//       }
//       defaultIndex = defaultIndex.tryIncrementLatestLevel();
//     }

//     throw WalletExceptionConst.tooManyAccounts;
//   }

//   @override
//   Bip32DerivationIndex defaultIndex({int? subId, int? importedKey}) {
//     return Bip32DerivationIndex.defaultBip(
//         coin: coin, seedGeneration: seedGenerationType);
//   }

//   @override
//   Bip32DerivationIndex masterIndex({int? subId, int? importedKey}) {
//     return Bip32DerivationIndex(currencyCoin: coin, seedGeneration: seedGenerationType);
//   }
// }

class MoneroNextDerivationBuilder extends NetDerivationBuilder<Bip32DerivationIndex,
    NextDerivationMonero, BipCoins, MoneroAddressDeivedIndex> {
  MoneroNextDerivationBuilder({
    required super.indexes,
    required super.coin,
    // required super.seedGenerationType,
  }) : super(seedGenerationType: SeedTypes.bip39);

  @override
  Bip32DerivationIndex defaultIndex(
      {ViewSubWalletKey? subId, ViewImportedSecretKey? importedKey}) {
    final index =
        Bip32DerivationIndex.defaultBip(coin: coin, seedGeneration: seedGenerationType);
    if (subId != null) return index.asSubWalletKey(subId.id);
    if (importedKey != null) return index.asImportedKey(importedKey.id);
    return index;
  }

  @override
  Bip32DerivationIndex masterIndex(
      {ViewSubWalletKey? subId, ViewImportedSecretKey? importedKey}) {
    final index =
        Bip32DerivationIndex(currencyCoin: coin, seedGeneration: seedGenerationType);
    if (subId != null) return index.asSubWalletKey(subId.id);
    if (importedKey != null) return index.asImportedKey(importedKey.id);
    return index;
  }

  @override
  NextDerivationMonero next(
      {NextDerivationMonero? currentIndex,
      ViewSubWalletKey? subId,
      ViewImportedSecretKey? importedKey}) {
    if (currentIndex != null &&
        !isValidIndex(currentIndex.nextIndex, subId: subId, importedKey: importedKey)) {
      currentIndex = null;
    }
    Bip32DerivationIndex defaultIndex = switch (currentIndex) {
      NextDerivationMonero index => index.nextIndex,
      _ => getDefaultDerivationIndex(subId: subId, importedKey: importedKey),
    };
    MoneroSubIndex? subIndex = currentIndex?.index ?? MoneroSubIndex(major: 0, minor: 0);
    while (subIndex != null) {
      final index = MoneroAccountIndex(masterIndex: defaultIndex, index: subIndex);
      if (!indexes.any((e) => e.index == index)) {
        return NextDerivationMonero(nextIndex: defaultIndex, index: subIndex);
      }
      subIndex = subIndex.tryIncrement();
    }
    throw WalletExceptionConst.tooManyAccounts;
  }

  @override
  NextDerivationMonero getDefaultDerivation(
      {ViewSubWalletKey? subId, ViewImportedSecretKey? importedKey}) {
    return NextDerivationMonero(
        nextIndex: getDefaultDerivationIndex(subId: subId, importedKey: importedKey),
        index: const MoneroSubIndex.unsafe());
  }
}
