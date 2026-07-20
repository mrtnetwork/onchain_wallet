import 'package:blockchain_utils/bip/bip.dart';
import 'package:blockchain_utils/utils/binary/binary_operation.dart';
import 'package:on_chain_wallet/crypto/wallet/keys.dart';

void main() {
  derivationInceremnt5();
}

void derivationInceremnt5() {
  final coin = Bip44Coins.solana;
  Bip32DerivationIndex? index = Bip32DerivationIndex(
    currencyCoin: coin,
    seedGeneration: SeedTypes.bip39,
    purpose: coin.proposal.purpose.index,
    coin: Bip32KeyIndex.hardenIndex(coin.conf.coinIdx).index,
    accountLevel: BinaryOps.maxUint32,
  );
  for (int i = 0; i < 10; i++) {
    index = index?.tryIncrementLatestLevel();
  }
  assert(index == null);
}

void derivationInceremnt4() {
  final coin = Bip44Coins.solana;
  final path = Bip32PathParser.parse(coin.conf.defPath);
  Bip32DerivationIndex? index = Bip32DerivationIndex(
    currencyCoin: coin,
    seedGeneration: SeedTypes.bip39,
    purpose: coin.proposal.purpose.index,
    coin: Bip32KeyIndex.hardenIndex(coin.conf.coinIdx).index,
    accountLevel: path.elems.elementAtOrNull(0)?.index,
  );
  for (int i = 0; i < 10; i++) {
    index = index?.tryIncrementLatestLevel();
  }
  assert(index?.accountLevel == Bip32KeyIndex.hardenIndex(10).index);
  assert(index?.purpose == coin.proposal.purpose.index);
  assert(index?.coin == Bip32KeyIndex.hardenIndex(coin.conf.coinIdx).index);
}

void derivationInceremnt3() {
  final coin = Bip44Coins.bitcoin;
  final path = Bip32PathParser.parse(coin.conf.defPath);
  Bip32DerivationIndex? index = Bip32DerivationIndex(
    currencyCoin: coin,
    seedGeneration: SeedTypes.bip39,
    purpose: coin.proposal.purpose.index,
    coin: Bip32KeyIndex.hardenIndex(coin.conf.coinIdx).index,
    accountLevel: path.elems.elementAtOrNull(0)?.index,
  );
  for (int i = 0; i < 10; i++) {
    index = index?.tryIncrementLatestLevel();
  }
  assert(index?.accountLevel == Bip32KeyIndex.hardenIndex(10).index);
  assert(index?.purpose == coin.proposal.purpose.index);
  assert(index?.coin == Bip32KeyIndex.hardenIndex(coin.conf.coinIdx).index);
}

void derivationInceremnt2() {
  final coin = Bip44Coins.bitcoin;
  final path = Bip32PathParser.parse(coin.conf.defPath);
  Bip32DerivationIndex? index = Bip32DerivationIndex(
    currencyCoin: coin,
    seedGeneration: SeedTypes.bip39,
    purpose: coin.proposal.purpose.index,
    coin: coin.conf.coinIdx,
    accountLevel: path.elems.elementAtOrNull(0)?.index,
    changeLevel: path.elems.elementAtOrNull(1)?.index,
  );
  for (int i = 0; i < 10; i++) {
    index = index?.tryIncrementLatestLevel();
  }
  assert(index?.changeLevel == 10);
  assert(index?.purpose == coin.proposal.purpose.index);
  assert(index?.coin == Bip32KeyIndex.hardenIndex(coin.conf.coinIdx).index);
  assert(index?.accountLevel == path.elems.elementAtOrNull(0)?.index);
}

void derivationInceremnt() {
  final coin = Bip44Coins.bitcoin;
  final path = Bip32PathParser.parse(coin.conf.defPath);
  Bip32DerivationIndex? index = Bip32DerivationIndex(
    currencyCoin: coin,
    seedGeneration: SeedTypes.bip39,
    purpose: coin.proposal.purpose.index,
    coin: coin.conf.coinIdx,
    accountLevel: path.elems.elementAtOrNull(0)?.index,
    changeLevel: path.elems.elementAtOrNull(1)?.index,
    addressIndex: path.elems.elementAtOrNull(2)?.index,
  );
  for (int i = 0; i < 10; i++) {
    index = index?.tryIncrementLatestLevel();
  }
  assert(index?.addressIndex == 10);
  assert(index?.purpose == coin.proposal.purpose.index);
  assert(index?.coin == Bip32KeyIndex.hardenIndex(coin.conf.coinIdx).index);
  assert(index?.accountLevel == path.elems.elementAtOrNull(0)?.index);
  assert(index?.changeLevel == path.elems.elementAtOrNull(1)?.index);
}
