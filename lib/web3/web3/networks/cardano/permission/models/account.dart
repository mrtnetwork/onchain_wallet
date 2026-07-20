import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain/ada/ada.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/app/core.dart';

import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/wallet/chain/account.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/permission/types/account.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';

class Web3ADAMultisigChainAccount with AppSerialization {
  List<String> get requirementsKeyHashes => script.nativeScripts
      .cast<NativeScriptScriptPubkey>()
      .map((e) => e.addressKeyHash.toHex())
      .toList();
  final NativeScriptScriptNOfK script;
  Web3ADAMultisigChainAccount({required this.script});

  factory Web3ADAMultisigChainAccount.deserialize(
      {List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object,
        cborBytes: bytes,
        identifier: AppSerializationIdentifier.web3CardanoMultiSigAccount);
    return Web3ADAMultisigChainAccount(
        script: NativeScriptScriptNOfK.deserialize(values.objectAt<CborListValue>(0)));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.web3CardanoMultiSigAccount;

  @override
  List<CborObject?> get serializationItems => [script.toCbor()];
}

class Web3ADAChainAccount extends Web3ChainAccount<ADAAddress> {
  @override
  final int id;
  final List<int>? publicKey;
  final List<TransactionUnspentOutput> utxos;
  final BigInt balance;
  final bool isRewardAddress;
  final Web3ADAMultisigChainAccount? multisig;
  bool get isScript => publicKey == null;
  String get asCborAddress => BytesUtils.toHexString(address.toBytes());
  Web3ADAChainAccount(
      {required super.derivationIndex,
      required super.address,
      required super.defaultAddress,
      required this.id,
      required super.identifier,
      required this.balance,
      required this.isRewardAddress,
      required List<TransactionUnspentOutput> utxos,
      this.multisig,
      List<int>? publicKey})
      : utxos = utxos.immutable,
        publicKey = publicKey?.asImmutableBytes;
  @override
  Web3ADAChainAccount clone({
    DerivationIndex? derivationIndex,
    ADAAddress? address,
    bool? defaultAddress,
    int? id,
    List<int>? publicKey,
    String? identifier,
    BigInt? balance,
    List<TransactionUnspentOutput>? utxos,
    bool? isRewardAddress,
    Web3ADAMultisigChainAccount? multisig,
  }) {
    return Web3ADAChainAccount(
        derivationIndex: derivationIndex ?? this.derivationIndex,
        address: address ?? this.address,
        defaultAddress: defaultAddress ?? this.defaultAddress,
        id: id ?? this.id,
        publicKey: publicKey ?? this.publicKey,
        identifier: identifier ?? this.identifier,
        utxos: utxos ?? this.utxos,
        balance: balance ?? this.balance,
        isRewardAddress: isRewardAddress ?? this.isRewardAddress,
        multisig: multisig ?? this.multisig);
  }

  factory Web3ADAChainAccount.fromChainAccount(
      {required ICardanoAddress address,
      required int id,
      required bool isDefault,
      required List<TransactionUnspentOutput> utxos,
      required bool isRewardAddress}) {
    if (isRewardAddress) {
      if (!address.isBaseAddress && !address.isBaseAddress) {
        throw Web3RequestExceptionConst.invalidRequest;
      }
    }

    Web3ADAMultisigChainAccount? multisig;
    if (address.multiSigAccount) {
      BaseCardanoMultiSignatureCredential? credential;
      final mAccount = address as ICardanoMultiSigAddress;
      if (isRewardAddress) {
        if (mAccount.isBaseAddress) {
          credential = mAccount.addressInfo.stakeCredential;
        } else {
          credential = mAccount.addressInfo.credential;
        }
      } else {
        credential = mAccount.addressInfo.credential;
      }
      assert(credential != null);
      if (credential != null && credential.type.isScript) {
        final script = credential.cast<CardanoMultiSignatureScript>();

        multisig = Web3ADAMultisigChainAccount(script: script.script);
      }
    }
    return Web3ADAChainAccount(
        derivationIndex: isRewardAddress
            ? (address.rewardKeyIndex ?? address.derivationIndex)
            : address.derivationIndex,
        address: isRewardAddress
            ? address.rewardAddress ?? address.networkAddress
            : address.networkAddress,
        id: id,
        defaultAddress: isDefault,
        publicKey: isRewardAddress ? address.rewardPublicKey : address.publicKey,
        identifier: address.identifier,
        balance: isRewardAddress ? BigInt.zero : address.addressData.currencyBalance,
        utxos: utxos,
        isRewardAddress: isRewardAddress,
        multisig: multisig);
  }

  factory Web3ADAChainAccount.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object,
        cborBytes: bytes,
        identifier: AppSerializationIdentifier.web3CardanoAccount);
    return Web3ADAChainAccount(
        derivationIndex:
            DerivationIndex.deserialize(object: values.objectAt<CborTagValue>(0)),
        address: ADAAddress.deserializeIAddress(bytes: values.rawValueAt(1)),
        id: values.rawValueAt(2),
        defaultAddress: values.rawValueAt(3),
        publicKey: values.rawValueAt(4),
        identifier: values.rawValueAt(5),
        balance: values.rawValueAt(6),
        utxos: values
            .listAt<CborIterableObject>(7)
            .map((e) => TransactionUnspentOutput.deserialize(e))
            .toList(),
        isRewardAddress: values.rawValueAt(8),
        multisig: values.maybeObjectAt<Web3ADAMultisigChainAccount, CborTagValue>(
            9, (e) => Web3ADAMultisigChainAccount.deserialize(object: e)));
  }

  @override
  String get addressStr => address.address;

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.web3CardanoAccount;

  @override
  List<CborObject?> get serializationItems => [
        derivationIndex.toCbor(),
        CborBytesValue(address.encodeAsIAddress()),
        id.toCbor(),
        defaultAddress.toCbor(),
        publicKey?.toCborBytes(),
        identifier.toCbor(),
        balance.toCbor(),
        CborListValue<CborObject>.definite(utxos.map((e) => e.toCbor()).toList()),
        isRewardAddress.toCbor(),
        multisig?.toCbor()
      ];
}

class Web3ADAChainIdnetifier extends Web3ChainIdnetifier {
  final ADANetwork network;
  Web3ADAChainIdnetifier(
      {required super.wsIdentifier,
      required super.caip2,
      required super.id,
      required this.network});
  factory Web3ADAChainIdnetifier.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object,
        cborBytes: bytes,
        identifier: AppSerializationIdentifier.web3ADAChainIdentifier);
    return Web3ADAChainIdnetifier(
        id: values.rawValueAt(0),
        wsIdentifier: values.rawValueAt(1),
        caip2: values.rawValueAt(2),
        network: ADANetwork.fromProtocolMagic(values.rawValueAt(3)));
  }

  @override
  SerializationIdentifier get serializationIdentifier =>
      AppSerializationIdentifier.web3ADAChainIdentifier;

  @override
  List<CborObject?> get serializationItems => [
        id.toCbor(),
        wsIdentifier.toCbor(),
        caip2.toCbor(),
        network.protocolMagic.toCbor(),
      ];
}

class Web3ADAChainAuthenticated extends Web3ChainAuthenticated<Web3ADAChainAccount> {
  @override
  final List<Web3ADAChainIdnetifier> networks;
  @override
  final Web3ADAChainIdnetifier currentNetwork;
  Web3ADAChainAuthenticated({
    required super.accounts,
    required this.currentNetwork,
    required List<Web3ADAChainIdnetifier> networks,
  })  : networks = networks.immutable,
        super(networkType: NetworkType.cardano);

  factory Web3ADAChainAuthenticated.deserialize({List<int>? bytes, CborObject? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborObject: object, cborBytes: bytes, identifier: NetworkType.cardano.identifier);
    return Web3ADAChainAuthenticated(
      accounts: values
          .listAt<CborTagValue>(0)
          .map((e) => Web3ADAChainAccount.deserialize(object: e))
          .toList(),
      networks: values
          .listAt<CborTagValue>(1)
          .map((e) => Web3ADAChainIdnetifier.deserialize(object: e))
          .toList(),
      currentNetwork:
          Web3ADAChainIdnetifier.deserialize(object: values.objectAt<CborTagValue>(2)),
    );
  }
}
