import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:monero_dart/monero_dart.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/types.dart';

import 'package:on_chain_wallet/crypto/wallet/keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/zcash_context.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/wallet/models/networks/cardano/models/address_details.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/models/models/derive_address_response.dart';
import 'package:on_chain/aptos/src/address/address/address.dart';
import 'package:on_chain/sui/src/address/address/address.dart';
import 'package:on_chain_wallet/wallet/models/networks/monero/account/account.dart';
import 'package:on_chain_wallet/wallet/models/networks/zcash/zcash.dart';
import 'package:zcash_dart/zcash.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';

final class WalletRequestDeriveAddress
    extends WalletRequest<CryptoDeriveAddressResponse> {
  final NewAccountParams addressParams;
  const WalletRequestDeriveAddress._({required this.addressParams});

  factory WalletRequestDeriveAddress({
    required NewAccountParams addressParams,
  }) {
    return WalletRequestDeriveAddress._(addressParams: addressParams);
  }
  factory WalletRequestDeriveAddress.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: WalletRequestMethod.deriveAddress.tag);
    final addrParams =
        NewAccountParams.deserialize(object: values.objectAt<CborTagValue>(0))
            .cast<NewDerivableAccountParams>();

    return WalletRequestDeriveAddress(addressParams: addrParams);
  }

  @override
  WalletRequestMethod get method => WalletRequestMethod.deriveAddress;

  static T _getPublicKey<T extends CryptoPublicKeyData>(
      MemoryWalletContext wallet, DerivableIndex index) {
    final pubKey = wallet.readPublicKeys([index]).keys.first;
    return pubKey.key.cast<T>();
  }

  static CryptoDeriveAddressResponse _deriveMoneroAddress(
      MoneroNewAddressParams addressParams, MemoryWalletContext wallet) {
    final pubKey = _getPublicKey<MoneroPublicKeyData>(wallet, addressParams.deriveIndex);
    final masterKey = MoneroViewPrimaryAccountDetails(
        viewPrivateKey: pubKey.viewPrivateKey,
        spendPublicKey: pubKey.spendPublicKey,
        index: addressParams.deriveIndex,
        network: addressParams.network);
    final index = MoneroAccountIndex(
        masterIndex: addressParams.deriveIndex,
        index: MoneroSubIndex(major: addressParams.major, minor: addressParams.minor));
    return CryptoDeriveAddressResponse(
        accountParams: addressParams.copyWith(masterKey: masterKey, index: index),
        publicKey: pubKey);
  }

  static CryptoDeriveAddressResponse _deriveCardanoAddress(
      CardanoNewAddressParams params, MemoryWalletContext wallet) {
    final bool byronLegacy = params.coin.proposal == CoinProposal.cip0019;
    final bip = _getPublicKey(wallet, params.deriveIndex);
    final CardanoAddrDetails addrDetails;
    switch (params.addressType) {
      case ADAAddressType.base:
        final stake = _getPublicKey(wallet, params.rewardKeyIndex!);
        addrDetails = CardanoAddrDetails.shelley(
            publicKey: bip.keyBytes(),
            stakePubkey: stake.keyBytes(),
            addressType: params.addressType,
            seedGeneration: params.deriveIndex.seedGeneration);
        break;
      case ADAAddressType.enterprise:
      case ADAAddressType.reward:
        addrDetails = CardanoAddrDetails.shelley(
            publicKey: bip.keyBytes(),
            addressType: params.addressType,
            seedGeneration: params.deriveIndex.seedGeneration);
        break;
      case ADAAddressType.byron:
        if (byronLegacy) {
          final adaPubKey = bip.cast<AdaLegacyPublicKeyData>();
          addrDetails = CardanoAddrDetails.byron(
              publicKey: bip.keyBytes(),
              chainCode: adaPubKey.chainCodeBytes(),
              seedGeneration: params.deriveIndex.seedGeneration,
              hdPathKey: params.customHdPathKey ?? adaPubKey.hdPathKeyBytes(),
              hdPath: params.customHdPath ?? params.deriveIndex.hdPath);
          break;
        }

        addrDetails = CardanoAddrDetails.byron(
            publicKey: bip.keyBytes(),
            chainCode: bip.chainCodeBytes()!,
            seedGeneration: params.deriveIndex.seedGeneration);
        break;
      default:
        throw AppCryptoExceptionConst.invalidNeweAddressConfiguration;
    }
    return CryptoDeriveAddressResponse(
        accountParams: params.copyWith(addressDetails: addrDetails), publicKey: bip);
  }

  static CryptoDeriveAddressResponse _deriveAptosAddress(
      AptosNewAddressParams addressParams, MemoryWalletContext wallet) {
    if (addressParams.coin.conf.type != addressParams.keyScheme.curve) {
      throw AppCryptoExceptionConst.invalidNeweAddressConfiguration;
    }
    final publicKey = _getPublicKey(wallet, addressParams.deriveIndex);
    String address;
    switch (addressParams.coin) {
      case Bip44Coins.aptos:
        address = AptosAddrEncoder().encodeKey(publicKey.keyBytes());
        break;
      case Bip44Coins.aptosEd25519SingleKey:
      case Bip44Coins.aptosSecp256k1SingleKey:
        final key =
            IPublicKey.fromBytes(publicKey.keyBytes(), addressParams.coin.conf.type);
        address = AptosAddrEncoder().encodeSingleKey(key);
      default:
        throw AppCryptoExceptionConst.invalidNeweAddressConfiguration;
    }
    addressParams = addressParams.updateAddress(AptosAddress(address));
    return CryptoDeriveAddressResponse(
        accountParams: addressParams as NewAccountParams, publicKey: publicKey);
  }

  static CryptoDeriveAddressResponse _deriveSuiAddress(
      SuiNewAddressParams addressParams, MemoryWalletContext wallet) {
    final publicKey = _getPublicKey(wallet, addressParams.deriveIndex);
    String address;
    switch (addressParams.coin.conf.type) {
      case EllipticCurveTypes.ed25519:
        address = SuiAddrEncoder().encodeKey(publicKey.keyBytes());
        break;
      case EllipticCurveTypes.secp256k1:
        address = SuiSecp256k1AddrEncoder().encodeKey(publicKey.keyBytes());
        break;
      case EllipticCurveTypes.nist256p1Hybrid:
        address = SuiSecp256r1AddrEncoder().encodeKey(publicKey.keyBytes());
        break;
      default:
        throw AppCryptoExceptionConst.invalidNeweAddressConfiguration;
    }
    addressParams = addressParams.updateAddress(SuiAddress(address));
    return CryptoDeriveAddressResponse(
        accountParams: addressParams as NewAccountParams, publicKey: publicKey);
  }

  static CryptoDeriveAddressResponse _deriveAddress(
      NewDerivableAccountParams addressParams, MemoryWalletContext wallet) {
    final pubKey = _getPublicKey(wallet, addressParams.deriveIndex);
    return CryptoDeriveAddressResponse(accountParams: addressParams, publicKey: pubKey);
  }

  static ({
    ZcsahAccountInfoSapling sapling,
    ReceiverSapling receiver,
    SaplingDiversifiableFullViewingKey fvk
  }) _deriveZcashSaplingInternal(
      {required ZcashAccountCreationParamsSapling sapling,
      required MemoryWalletContext wallet,
      required List<BigInt> existsDiversifier,
      required ZcashNetwork network}) {
    final key = _getPublicKey<Zip32PublicKeyData>(wallet, sapling.index);
    final fvk = key.toFvk().cast<SaplingDiversifiableFullViewingKey>();
    final ivk = fvk.toIvk(sapling.change);
    final addr = switch (sapling.exactDiversifier) {
      false => () {
          DiversifierIndex? index = sapling.diversifierIndex;
          while (index != null) {
            final addr = ivk.findAddress(index);
            if (addr == null) break;
            index = addr.$2;
            final toBig = index.toU128();
            if (existsDiversifier.contains(toBig)) {
              index = index.tryIncrement();
              continue;
            }
            return (addr.$1, index);
          }
          throw AppCryptoExceptionConst.zcashDeriveAddressIndexOutOfRange;
        }(),
      true => () {
          final addr = ivk.tryAddressAt(sapling.diversifierIndex);
          if (addr == null) return null;
          return (addr, sapling.diversifierIndex);
        }(),
    };
    if (addr == null) {
      throw AppCryptoExceptionConst.zcashDeriveAddressBadSaplingDiversifierIndex;
    }
    final receiver =
        ReceiverSapling(data: addr.$1.toBytes(), mode: UnifiedReceiverMode.address);
    final info = ZcsahAccountInfoSapling(
        index: sapling.index,
        diversifierIndex: addr.$2,
        scope: sapling.change,
        activationHeight: sapling.activationHeight);
    return (sapling: info, receiver: receiver, fvk: fvk);
  }

  static Future<CryptoDeriveAddressResponse> _deriveZcashUnifiedAddress(
      ZcashNewAddressParamsUnified addressParams,
      MemoryWalletContext wallet,
      AppContext context) async {
    final (crypto, _) = (await OnChainCryptoContext.inst(context)).unwrap();
    final List<ZcashAccountInfo> derivedAccount = [];
    final params = addressParams.params;
    if (params == null) {
      throw AppCryptoExceptionConst.invalidNeweAddressConfiguration;
    }
    final sapling = params
        .firstWhereOrNull((e) => e.type == ZcashAccountInfoType.sapling)
        ?.cast<ZcashAccountCreationParamsSapling>();
    DiversifierIndex? saplingIndex;
    List<DiversifiableFullViewingKey> fvks = [];
    List<ZUnifiedReceiver> receivers = [];
    if (sapling != null) {
      final account = _deriveZcashSaplingInternal(
          sapling: sapling,
          wallet: wallet,
          existsDiversifier: addressParams.existsIndexes,
          network: addressParams.network);
      saplingIndex = account.sapling.diversifierIndex;
      derivedAccount.add(account.sapling);
      receivers.add(account.receiver);
      fvks.add(account.fvk);
    }

    for (final param in params) {
      switch (param) {
        case ZcashAccountCreationParamsSapling _:
          continue;
        case ZcashAccountCreationParamsUnified orchard:
          final key = _getPublicKey<Zip32PublicKeyData>(wallet, orchard.index);
          final fvk = key.toFvk().cast<OrchardFullViewingKey>();
          final ivk = fvk.toIvk(orchard.change, context: crypto);
          DiversifierIndex? orchardIndex = orchard.diversifierIndex ?? saplingIndex;
          if (orchardIndex == null) {
            throw AppCryptoExceptionConst.invalidNeweAddressConfiguration;
          }
          final addr = ivk.addressAt(orchardIndex);
          final receiver =
              ReceiverOrchard(data: addr.toBytes(), mode: UnifiedReceiverMode.address);

          derivedAccount.add(ZcsahAccountInfoOrchard(
              index: orchard.index,
              diversifierIndex: orchardIndex,
              activationHeight: orchard.activationHeight,
              scope: orchard.change));
          receivers.add(receiver);
          fvks.add(fvk);
          continue;
        case ZcashAccountCreationParamsP2pkh p2pkh:
          Bip32DerivationIndex newPath = p2pkh.index;
          Bip32KeyIndex? addrLevl;
          if (p2pkh.followingSaplingRole) {
            final sapling = saplingIndex;
            if (sapling == null) {
              throw AppCryptoExceptionConst.invalidNeweAddressConfiguration;
            }
            addrLevl = sapling.toBip32Index();
            if (addrLevl == null) {
              throw AppCryptoExceptionConst.zcashDeriveTransparentAddressIndexOutOfRange;
            }
            newPath = newPath.copyWith(addressIndex: addrLevl.toInt());
          }
          final key = _getPublicKey<PublicKeyData>(wallet, newPath);
          final pkBytes = key.keyBytes().asImmutableBytes;
          final n = ZECPublic.fromBytes(pkBytes);
          final addr = n.toAddress(network: addressParams.network);
          final receiver =
              ReceiverP2pkh(data: addr.data, mode: UnifiedReceiverMode.address);
          derivedAccount.add(ZcsahAccountInfoP2pkh(index: newPath));
          receivers.add(receiver);
          continue;
        case ZcashAccountCreationParamsP2shStandard p2sh:
          Bip32DerivationIndex newPath = p2sh.index;
          Bip32KeyIndex? addrLevl;
          if (p2sh.followingSaplingRole) {
            final sapling = saplingIndex;
            if (sapling == null) {
              throw AppCryptoExceptionConst.invalidNeweAddressConfiguration;
            }
            addrLevl = sapling.toBip32Index();
            if (addrLevl == null) {
              throw AppCryptoExceptionConst.zcashDeriveTransparentAddressIndexOutOfRange;
            }
            newPath = newPath.copyWith(addressIndex: addrLevl.toInt());
          }
          final key = _getPublicKey<PublicKeyData>(wallet, newPath);
          final pkBytes = key.keyBytes().asImmutableBytes;
          final n = ZECPublic.fromBytes(pkBytes);
          final addr = switch (p2sh.p2shType) {
            P2shAddressType.p2pkhInP2sh =>
              n.toP2pkhInP2sh(network: addressParams.network),
            P2shAddressType.p2pkInP2sh => n.toP2pkInP2sh(network: addressParams.network),
            _ => throw AppCryptoExceptionConst.invalidNeweAddressConfiguration
          };
          final redeemScript = switch (p2sh.p2shType) {
            P2shAddressType.p2pkhInP2sh => n.toAddress().toScriptPubKey(),
            P2shAddressType.p2pkInP2sh => n.toP2pkRedeemScript(),
            _ => throw AppCryptoExceptionConst.invalidNeweAddressConfiguration
          };
          final receiver = ReceiverP2sh(addr.data);
          derivedAccount.add(ZcsahAccountInfoP2shStandard(
              index: newPath, transparentType: addr.type, redeemScript: redeemScript));
          receivers.add(receiver);
          continue;
        case ZcashAccountCreationParamsP2shMultisig msig:
          final addr = ZcashP2shAddress.fromScript(
              script: msig.multisig.multiSigScript, network: addressParams.network);
          final receiver = ReceiverP2sh(addr.data);
          derivedAccount.add(ZcsahAccountInfoP2shMultisig(multisig: msig.multisig));
          receivers.add(receiver);
      }
    }
    return CryptoDeriveAddressResponse(
        accountParams: ZcashNewAddressParamsUnified(
            coin: addressParams.coin,
            currentHeight: addressParams.currentHeight,
            fvks: fvks,
            network: addressParams.network,
            derivedAccount: ZcashDerivedAccountInfo(
                receivers: derivedAccount,
                address: ZcashUnifiedAddress.fromReceivers(
                    receivers: receivers, network: addressParams.network))));
  }

  static Future<CryptoDeriveAddressResponse> _deriveZcashSaplingAddress(
      ZcashNewAddressParamsSapling addressParams,
      MemoryWalletContext wallet,
      AppContext context) async {
    (await OnChainCryptoContext.inst(context)).unwrap();
    final sapling = addressParams.param;
    if (sapling == null) {
      throw AppCryptoExceptionConst.invalidNeweAddressConfiguration;
    }
    final saplingReceiver = _deriveZcashSaplingInternal(
        sapling: sapling,
        wallet: wallet,
        network: addressParams.network,
        existsDiversifier: addressParams.existsIndexes);
    return CryptoDeriveAddressResponse(
        accountParams: ZcashNewAddressParamsSapling(
            coin: addressParams.coin,
            network: addressParams.network,
            fvk: saplingReceiver.fvk,
            currentHeight: addressParams.currentHeight,
            derivedAccount: ZcashDerivedAccountInfo(
                receivers: [saplingReceiver.sapling],
                address: SaplingAddress.fromBytes(
                    bytes: saplingReceiver.receiver.data,
                    network: addressParams.network))));
  }

  static CryptoDeriveAddressResponse _deriveZcashTransparentAddress(
      ZcashNewAddressParamsTransparent addressParams, MemoryWalletContext wallet) {
    final param = addressParams.param;
    if (param == null) {
      throw AppCryptoExceptionConst.invalidNeweAddressConfiguration;
    }
    switch (param) {
      case ZcashAccountCreationParamsP2pkh p2pkh:
        Bip32DerivationIndex newPath = p2pkh.index;
        final key = _getPublicKey<PublicKeyData>(wallet, newPath);
        final pkBytes = key.keyBytes().asImmutableBytes;
        final n = ZECPublic.fromBytes(pkBytes);
        final addr = n.toAddress(network: addressParams.network);
        return CryptoDeriveAddressResponse(
            accountParams: ZcashNewAddressParamsTransparent(
                coin: addressParams.coin,
                network: addressParams.network,
                derivedAccount: ZcashDerivedAccountInfo(
                    receivers: [ZcsahAccountInfoP2pkh(index: newPath)], address: addr)));
      case ZcashAccountCreationParamsP2shStandard p2sh:
        Bip32DerivationIndex newPath = p2sh.index;
        final key = _getPublicKey<PublicKeyData>(wallet, newPath);
        final pkBytes = key.keyBytes().asImmutableBytes;
        final n = ZECPublic.fromBytes(pkBytes);
        final addr = switch (p2sh.p2shType) {
          P2shAddressType.p2pkhInP2sh => n.toP2pkhInP2sh(network: addressParams.network),
          P2shAddressType.p2pkInP2sh => n.toP2pkInP2sh(network: addressParams.network),
          _ => throw AppCryptoExceptionConst.invalidNeweAddressConfiguration
        };
        final redeemScript = switch (p2sh.p2shType) {
          P2shAddressType.p2pkhInP2sh => n.toAddress().toScriptPubKey(),
          P2shAddressType.p2pkInP2sh => n.toP2pkRedeemScript(),
          _ => throw AppCryptoExceptionConst.invalidNeweAddressConfiguration
        };
        return CryptoDeriveAddressResponse(
            accountParams: ZcashNewAddressParamsTransparent(
                coin: addressParams.coin,
                network: addressParams.network,
                derivedAccount: ZcashDerivedAccountInfo(receivers: [
                  ZcsahAccountInfoP2shStandard(
                      index: newPath,
                      transparentType: addr.type,
                      redeemScript: redeemScript)
                ], address: addr)));
      case ZcashAccountCreationParamsP2shMultisig _:
        throw AppCryptoExceptionConst.invalidNeweAddressConfiguration;
    }
  }

  static CryptoDeriveAddressResponse _deriveZcashTransparentMultisigAddress(
      ZcashNewAddressParamsTransparentMultisignature addressParams,
      MemoryWalletContext wallet) {
    final param = addressParams.param;
    if (param == null) {
      throw AppCryptoExceptionConst.invalidNeweAddressConfiguration;
    }
    final addr = ZcashP2shAddress.fromScript(
        script: param.multisig.multiSigScript, network: addressParams.network);
    return CryptoDeriveAddressResponse(
        accountParams: ZcashNewAddressParamsTransparentMultisignature(
            coin: addressParams.coin,
            network: addressParams.network,
            derivedAccount: ZcashDerivedAccountInfo(receivers: [
              ZcsahAccountInfoP2shMultisig(
                multisig: param.multisig,
              )
            ], address: addr)));
  }

  static Future<CryptoDeriveAddressResponse> deriveAddress(NewAccountParams addressParams,
      MemoryWalletContext wallet, AppContext context) async {
    switch (addressParams) {
      case AptosNewAddressParams():
        return _deriveAptosAddress(addressParams, wallet);
      case CardanoNewAddressParams():
        return _deriveCardanoAddress(addressParams, wallet);
      case MoneroNewAddressParams():
        return _deriveMoneroAddress(addressParams, wallet);
      case SuiNewAddressParams():
        return _deriveSuiAddress(addressParams, wallet);
      case ZcashNewAddressParamsUnified():
        return _deriveZcashUnifiedAddress(addressParams, wallet, context);
      case ZcashNewAddressParamsSapling():
        return _deriveZcashSaplingAddress(addressParams, wallet, context);
      case ZcashNewAddressParamsTransparent():
        return _deriveZcashTransparentAddress(addressParams, wallet);
      case ZcashNewAddressParamsTransparentMultisignature():
        return _deriveZcashTransparentMultisigAddress(addressParams, wallet);
      case NewDerivableAccountParams():
        return _deriveAddress(addressParams, wallet);
      default:
        throw AppCryptoExceptionConst.invalidNeweAddressConfiguration;
    }
  }

  @override
  Future<CryptoDeriveAddressResponse> parsResult(MessageArgsComplete result) async {
    return CryptoDeriveAddressResponse.deserialize(object: result.result);
  }

  @override
  Future<CryptoDeriveAddressResponse> result(
      MemoryWalletContext wallet, AppContext context) async {
    return deriveAddress(addressParams, wallet, context);
  }

  @override
  List<CborObject?> get serializationItems => [addressParams.toCbor()];

  @override
  CryptoProcessLevel get level => addressParams.level;
  @override
  Duration get processTimeout => switch (level) {
        CryptoProcessLevel.normal => super.processTimeout,
        CryptoProcessLevel.high => Duration(minutes: 3),
      };
}
