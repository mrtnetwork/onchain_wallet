import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cosmos_sdk/cosmos_sdk.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_bridge/serialization/src/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain/on_chain.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:polkadot_dart/polkadot_dart.dart';
import 'package:stellar_dart/stellar_dart.dart';
import 'package:ton_dart/ton_dart.dart';
import 'package:xrpl_dart/xrpl_dart.dart';
import 'package:zcash_dart/zcash.dart';

class BlockchainAddressUtils {
  static BitcoinNetworkAddress toBitcoinAddress(
      String address, BasedUtxoNetwork network) {
    BitcoinNetworkAddress addr;
    try {
      if (network is BitcoinCashNetwork) {
        addr = BitcoinCashAddress(address, network: network);
      } else if (network is BitcoinNetwork) {
        addr = BitcoinAddress(address, network: network);
      } else if (network is DogecoinNetwork) {
        addr = DogeAddress(address, network: network);
      } else if (network is DashNetwork) {
        addr = DashAddress(address, network: network);
      } else if (network is LitecoinNetwork) {
        addr = LitecoinAddress(address, network: network);
      } else if (network is PepeNetwork) {
        addr = PepeAddress(address, network: network);
      } else {
        throw UnimplementedError();
      }
      return addr;
    } catch (_) {
      throw WalletExceptionConst.addressGenerationFailed;
    }
  }

  static BitcoinNetworkAddress publicKeyToBitcoinNetworkAddress(
      {required List<int> publicKey,
      required CryptoCoins coin,
      required BitcoinAddressType addressType,
      required PubKeyModes keyType,
      required BasedUtxoNetwork network}) {
    return BitcoinNetworkAddress.fromBaseAddress(
        address: publicKeyToBitcoinAddress(
            publicKey: publicKey, coin: coin, addressType: addressType, keyType: keyType),
        network: network);
  }

  static BitcoinBaseAddress publicKeyToBitcoinAddress(
      {required List<int> publicKey,
      required CryptoCoins coin,
      required BitcoinAddressType addressType,
      required PubKeyModes keyType}) {
    final bitcoinPublicKey = ECPublic.fromBytes(publicKey);
    BitcoinBaseAddress address;
    switch (coin.proposal) {
      case CoinProposal.bip44:
        address = bitcoinPublicKey.toAddress(mode: keyType);
        if (addressType == P2pkhAddressType.p2pkhwt) {
          address = P2pkhAddress.fromHash160(
              addrHash: address.addressProgram, type: P2pkhAddressType.p2pkhwt);
        }
        break;
      case CoinProposal.bip49:
        switch (addressType) {
          case P2shAddressType.p2wshInP2sh:
            address = bitcoinPublicKey.toP2wshInP2sh();
            break;
          case P2shAddressType.p2wpkhInP2sh:
            address = bitcoinPublicKey.toP2wpkhInP2sh();
            break;
          case P2shAddressType.p2pkhInP2sh:
          case P2shAddressType.p2pkhInP2sh32:
          case P2shAddressType.p2pkhInP2shwt:
          case P2shAddressType.p2pkhInP2sh32wt:
            address = bitcoinPublicKey.toP2pkhInP2sh(
                useBCHP2sh32: addressType == P2shAddressType.p2pkhInP2sh32 ||
                    addressType == P2shAddressType.p2pkhInP2sh32wt,
                mode: keyType);
            if (addressType == P2shAddressType.p2pkhInP2shwt ||
                addressType == P2shAddressType.p2pkhInP2sh32wt) {
              address = P2shAddress.fromHash160(
                  addrHash: address.addressProgram, type: addressType.cast());
            }
            break;
          case P2shAddressType.p2pkInP2sh:
          case P2shAddressType.p2pkInP2sh32:
          case P2shAddressType.p2pkInP2shwt:
          case P2shAddressType.p2pkInP2sh32wt:
            address = bitcoinPublicKey.toP2pkInP2sh(
                useBCHP2sh32: addressType == P2shAddressType.p2pkInP2sh32 ||
                    addressType == P2shAddressType.p2pkInP2sh32wt,
                mode: keyType);
            if (addressType == P2shAddressType.p2pkInP2shwt ||
                addressType == P2shAddressType.p2pkInP2sh32wt) {
              address = P2shAddress.fromHash160(
                  addrHash: address.addressProgram, type: addressType.cast());
            }
            break;
          default:
            throw WalletExceptionConst.addressGenerationFailed;
        }
        break;
      case CoinProposal.bip84:
        if (addressType == SegwitAddressType.p2wsh) {
          address = bitcoinPublicKey.toP2wshAddress();
        } else {
          address = bitcoinPublicKey.toSegwitAddress();
        }

        break;
      case CoinProposal.bip86:
        address = bitcoinPublicKey.toTaprootAddress();
      default:
        throw WalletExceptionConst.addressGenerationFailed;
    }

    if (address.type != addressType) {
      throw WalletExceptionConst.addressGenerationFailed;
    }

    return address;
  }

  static ETHAddress _validatorEthereumAccount(String address) {
    return ETHAddress(address);
  }

  static AptosAddress _validateAptosAddress(String address) {
    return AptosAddress(address);
  }

  static SuiAddress _validateSuiAddress(String address) {
    return SuiAddress(address);
  }

  static ZcashAddress _validateZcashAddress(String address, WalletZcashNetwork network) {
    final addr = ZcashAddress(address, network: network.coinParam.network);
    if (addr.supportedProtocols.isEmpty) {
      throw WalletExceptionConst.unsupportedAddressType;
    }
    return addr;
  }

  static MoneroAddress? _validateMoneroAddress(
      String address, WalletMoneroNetwork network) {
    return MoneroAddress(address, network: network.coinParam.network);
  }

  static TronAddress _validatorTronAccount(String address) {
    return TronAddress(address);
  }

  static SolAddress _validatorSolAccount(String address) {
    return SolAddress(address);
  }

  static ADAAddress _validatorCardanoAddress(
      String address, WalletCardanoNetwork network) {
    return ADAAddress.fromAddress(address, network: network.coinParam.networkType);
  }

  static CosmosBaseAddress _validateCosmosAddress(
      String address, WalletCosmosNetwork network) {
    return CosmosBaseAddress(address, forceHrp: network.coinParam.hrp);
  }

  static TonAddress _validateTonAddress(String address, WalletTonNetwork network) {
    return TonAddress(address);
  }

  static StellarAddress _validateStallerAddress(
      String address, WalletStellarNetwork network) {
    return StellarAddress.fromBase32Addr(address);
  }

  static BitcoinNetworkAddress _validateBitcoinNetwork(
      String address, WalletBitcoinNetwork network) {
    return toBitcoinAddress(address, network.coinParam.transacationNetwork);
  }

  static BaseSubstrateAddress _validateSubstrateAddress(
      String address, WalletSubstrateNetwork network) {
    if (network.coinParam.substrateChainType.isEthereum) {
      return SubstrateEthereumAddress(address);
    }
    return SubstrateAddress(address, ss58Format: network.coinParam.ss58Format);
  }

  static XRPBaseAddress? _validateXRPAddress(String address, WalletXRPNetwork network) {
    return XRPBaseAddress(address, chainType: network.coinParam.chainType);
  }

  // static XRPAddress? validateXAddressTag(
  //     {required String? addr,
  //     required WalletXRPNetwork network,
  //     required int? tag}) {
  //   if (addr == null) return null;
  //   return MethodUtils.nullOnException(() {
  //     final address = toRippleAddress(addr, network);
  //     if (address == null) return null;
  //     if (tag != null) {
  //       if (address.tag == tag) return address;
  //       if (address.tag != null && address.tag != tag) return null;
  //       return XRPAddress(address.toXAddress(
  //           tag: tag, isTestnet: !network.coinParam.mainnet));
  //     }
  //     return address;
  //   }, logOnError: false);
  // }

  static Result<IAddress, WalletException?> validateAddress(
      String? address, WalletNetwork network) {
    try {
      final addr = _validateNetworkAddress(address, network);
      if (addr == null) return Err(null);
      return Ok(addr);
    } on WalletException catch (e) {
      return Err(e);
    } catch (e) {
      return Err(null);
    }
  }

  static IAddress? _validateNetworkAddress(String? address, WalletNetwork network) {
    if (address == null) return null;
    const int minumumAddressLength = 32;
    if (address.length < minumumAddressLength) return null;
    switch (network.type) {
      case NetworkType.bitcoinCash:
      case NetworkType.bitcoinAndForked:
        return _validateBitcoinNetwork(address, network.cast());
      case NetworkType.xrpl:
        return _validateXRPAddress(address, network.cast());
      case NetworkType.ethereum:
        return _validatorEthereumAccount(address);
      case NetworkType.sui:
        return _validateSuiAddress(address);
      case NetworkType.aptos:
        return _validateAptosAddress(address);
      case NetworkType.tron:
        return _validatorTronAccount(address);
      case NetworkType.solana:
        return _validatorSolAccount(address);
      case NetworkType.cardano:
        return _validatorCardanoAddress(address, network.cast());
      case NetworkType.cosmos:
        return _validateCosmosAddress(address, network.cast());
      case NetworkType.ton:
        return _validateTonAddress(address, network.cast());
      case NetworkType.stellar:
        return _validateStallerAddress(address, network.cast());
      case NetworkType.monero:
        return _validateMoneroAddress(address, network.cast());
      case NetworkType.substrate:
        return _validateSubstrateAddress(address, network.cast());
      case NetworkType.zcash:
        return _validateZcashAddress(address, network.cast());
    }
  }

  static IAddress parseIAddress({List<int>? bytes, CborObject? object}) {
    final decode = AppSerialization.decodeTaggedValueWithInfo(
        expectedTags: BlockchainNetwork.values.map((e) => e.identifier).toList(),
        cborBytes: bytes,
        cborObject: object);
    final network = BlockchainNetwork.fromIdentifier(decode.identifier.id);
    return switch (network) {
      BlockchainNetwork.aptos => AptosAddress.deserializeIAddress(object: decode.tag),
      BlockchainNetwork.ethereum => ETHAddress.deserializeIAddress(object: decode.tag),
      BlockchainNetwork.cardano => ADAAddress.deserializeIAddress(object: decode.tag),
      BlockchainNetwork.solana => SolAddress.deserializeIAddress(object: decode.tag),
      BlockchainNetwork.sui => SuiAddress.deserializeIAddress(object: decode.tag),
      BlockchainNetwork.tron => TronAddress.deserializeIAddress(object: decode.tag),
      BlockchainNetwork.bitcoinAndRelated =>
        BitcoinNetworkAddress.deserializeIAddress(object: decode.tag),
      BlockchainNetwork.ton => TonAddress.deserializeIAddress(object: decode.tag),
      BlockchainNetwork.substrateAndRelated =>
        BaseSubstrateAddress.deserializeIAddress(object: decode.tag),
      BlockchainNetwork.cosmosAndRelated =>
        CosmosBaseAddress.deserializeIAddress(object: decode.tag),
      BlockchainNetwork.monero => MoneroAddress.deserializeIAddress(object: decode.tag),
      BlockchainNetwork.stellar => StellarAddress.deserializeIAddress(object: decode.tag),
      BlockchainNetwork.xrpl => XRPBaseAddress.deserializeIAddress(object: decode.tag),
      BlockchainNetwork.zcash => ZcashAddress.deserializeIAddress(object: decode.tag),
    };
  }

  // static IAddress parseIAddressString(String address, NetworkType network) {
  //   return switch (network) {
  //     NetworkType.aptos => AptosAddress(address),
  //     NetworkType.ethereum => ETHAddress(address),
  //     NetworkType.cardano => ADAAddress.fromAddress(address),
  //     NetworkType.solana => SolAddress.uncheckCurve(address),
  //     NetworkType.sui => SuiAddress(address),
  //     NetworkType.tron => TronAddress(address),
  //     NetworkType.bitcoinAndForked => BitcoinNetworkAddress.parse(
  //         address: address,

  //       ),
  //     BlockchainNetwork.ton =>
  //       TonAddress.deserializeIAddress(object: decode.tag),
  //     BlockchainNetwork.substrateAndRelated =>
  //       BaseSubstrateAddress.deserializeIAddress(object: decode.tag),
  //     BlockchainNetwork.cosmosAndRelated =>
  //       CosmosBaseAddress.deserializeIAddress(object: decode.tag),
  //     BlockchainNetwork.monero =>
  //       MoneroAddress.deserializeIAddress(object: decode.tag),
  //     BlockchainNetwork.stellar =>
  //       StellarAddress.deserializeIAddress(object: decode.tag),
  //     BlockchainNetwork.xrpl =>
  //       XRPBaseAddress.deserializeIAddress(object: decode.tag),
  //     BlockchainNetwork.zcash =>
  //       ZcashAddress.deserializeIAddress(object: decode.tag),
  //   };
  // }

  static bool isValidNetworkAddress(String? address, WalletNetwork network) {
    return validateAddress(address, network).isOk;
  }

  static List<Bip32KeyIndex> praseBip32Path(String path) {
    return Bip32PathParser.parse(path).elems;
  }

  static List<SubstratePathElem> praseSubstratePath(String path) {
    return SubstratePathParser.parse(path).elems;
  }
}
