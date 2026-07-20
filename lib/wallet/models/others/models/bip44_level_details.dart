import 'package:blockchain_utils/blockchain_utils.dart';

class Bip44LevelsDetails {
  Bip44LevelsDetails(this.key, this.level);
  Bip44LevelsDetails.fromIntIndex(int index, this.level) : key = Bip32KeyIndex(index);

  final Bip32KeyIndex key;
  final Bip44Levels level;
  int get index => key.index;
  late final bool isHardened = key.isHardened;
  late final int unHardendValue = key.unharden().index;
  late final String path = "$unHardendValue${isHardened ? "'" : ""}";
}
