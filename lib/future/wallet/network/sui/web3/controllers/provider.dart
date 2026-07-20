import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
import 'package:on_chain/serialization/bcs/move/types/types.dart';
import 'package:on_chain/sui/sui.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/wallet/network/sui/web3/types/types.dart';
import 'package:on_chain_wallet/wallet/api/client/networks/sui/models/types.dart';
import 'package:on_chain_wallet/wallet/wallet.dart';
import 'package:on_chain_wallet/web3/web3/networks/sui/constant/constants/exception.dart';
import 'package:on_chain_wallet/web3/web3/networks/sui/params/models/transaction.dart';

class _MoveNormalizedArguments {
  final List<SuiApiMoveNormalizedType> parameters;
  const _MoveNormalizedArguments._(this.parameters);
  static bool isTxContext(SuiApiMoveNormalizedType type) {
    switch (type.type) {
      case SuiApiMoveNormalizedTypes.struct:
        return type.cast<SuiApiMoveNormalizedTypeStruct>().struct.isTxContext;
      case SuiApiMoveNormalizedTypes.reference:
        return isTxContext(type.cast<SuiApiMoveNormalizedTypeReference>().reference);
      case SuiApiMoveNormalizedTypes.mutableReference:
        return isTxContext(
            type.cast<SuiApiMoveNormalizedTypeMutableReference>().mutableReference);
      default:
        return false;
    }
  }

  static bool isReceiving(SuiApiMoveNormalizedType type) {
    switch (type.type) {
      case SuiApiMoveNormalizedTypes.struct:
        return type.cast<SuiApiMoveNormalizedTypeStruct>().struct.isReceiving;
      case SuiApiMoveNormalizedTypes.reference:
        return isTxContext(type.cast<SuiApiMoveNormalizedTypeReference>().reference);
      case SuiApiMoveNormalizedTypes.mutableReference:
        return isTxContext(
            type.cast<SuiApiMoveNormalizedTypeMutableReference>().mutableReference);
      default:
        return false;
    }
  }

  factory _MoveNormalizedArguments(SuiApiMoveNormalizedFunction abi) {
    final parameters = abi.parameters.clone();
    if (parameters.isEmpty) return _MoveNormalizedArguments._([]);
    final lastParameter = parameters.last;
    if (_MoveNormalizedArguments.isTxContext(lastParameter)) {
      parameters.removeLast();
    }
    return _MoveNormalizedArguments._(parameters);
  }

  Web3SuiTransactionPureArg? encodeAt(int index, Object? value) {
    final encode = parameters[index].toSuiCallArgPrue(value: value);
    if (encode != null) {
      return Web3SuiTransactionPureArg(bytes: encode.toBcsBase64());
    }
    return null;
  }
}

mixin SuiWeb3TransactionApiController on DisposableMixin {
  SuiNetworkClient get client;

  final Map<String, _MoveNormalizedArguments> _abis = {};
  Future<_MoveNormalizedArguments> _getAbi(
      Web3SuiTransactionCommandMoveCall moveCall) async {
    final name = "${moveCall.package.address}::${moveCall.module}::${moveCall.function}";
    _abis[name] ??= _MoveNormalizedArguments(await client.normalizeFunction(
        package: moveCall.package.address,
        moduleName: moveCall.module,
        functionName: moveCall.function));
    return _abis[name]!;
  }

  List<SuiAddress> _getUnresolvedObjectIds(List<Web3SuiTransactionCallArg> inputs) {
    final unresolvedObject =
        inputs.whereType<Web3SuiTransactionUnresolvedObject>().toList();
    return unresolvedObject
        .where((e) =>
            (e.digest == null) ||
            (e.initialSharedVersion == null && e.initialSharedVersion == null))
        .map((e) => e.objectId)
        .toList();
  }

  Future<void> _getUnresolvedObject(
      {required List<SuiAddress> objectIds,
      required Map<SuiAddress, SuiObjectResponse> resolvedObjects}) async {
    final ids = objectIds.where((e) => !resolvedObjects.containsKey(e)).toList();
    if (ids.isEmpty) return;
    final objects = await client.getObjects(ids);
    final fetchedObject = objects.map((k, v) {
      BigInt? initialVersion;
      final data = v.data;
      if (v.error != null || data == null) {
        throw Web3SuiExceptionConstant.retrieveObjectFailed(
            objectId: k.address, error: v.error?.errorMessage);
      }
      if (data.owner?.type == SuiApiObjectOwnerType.shared) {
        initialVersion =
            (v.data!.owner as SuiApiObjectOwnerShared).shared.initialSharedVersion;
      }
      return MapEntry(
          k,
          SuiObjectResponse(
              objectId: data.objectId,
              digest: data.digest,
              version: data.version,
              initialVersion: initialVersion));
    });
    resolvedObjects.addAll(fetchedObject);
  }

  Web3SuiTransactionUnresolvedPurePureArg? _getUnresolvedPure(
      Web3SuiTransactionArgument argument, List<Web3SuiTransactionCallArg> inputs) {
    if (argument.type != Web3SuiArguments.input) return null;
    final index = argument.cast<Web3SuiTransactionArgumentInput>().input;
    final input = inputs[index];
    if (input.type != Web3SuiTransactionCallArgs.unresolvedPure) return null;
    return input.cast();
  }

  Future<void> _updateTransferObjectArguments(
      Web3SuiTransactionCommandTransferObjects transferObject,
      List<Web3SuiTransactionCallArg> inputs) async {
    final pure = _getUnresolvedPure(transferObject.address, inputs);
    if (pure != null) {
      final address = MoveAddress.parse(pure.value);
      final index = inputs.indexOf(pure);
      inputs[index] = Web3SuiTransactionPureArg(bytes: address.toBcsBase64());
    }
  }

  Future<void> _resolveObjects(
      {required Web3SuiTransactionDataV2 transaction,
      required List<Web3SuiTransactionCallArg> inputs,
      required Map<SuiAddress, SuiObjectResponse> resolvedObjects}) async {
    int? asInput(Web3SuiTransactionArgument argument) {
      if (argument.type != Web3SuiArguments.input) return null;
      return argument.cast<Web3SuiTransactionArgumentInput>().input;
    }

    for (int i = 0; i < inputs.length; i++) {
      final input = inputs[i];
      if (input.type != Web3SuiTransactionCallArgs.unresolvedObject) continue;
      final unResolveObject = input.cast<Web3SuiTransactionUnresolvedObject>();
      bool mutable = false;
      bool isReceving = false;
      for (final command in transaction.commands) {
        if (isReceving && mutable) break;
        switch (command.type) {
          case Web3SuiTransactionCommands.splitCoins:
            final splitCoins = command.cast<Web3SuiTransactionCommandSplitCoins>();
            final index = asInput(splitCoins.coin);
            if (index == i) {
              mutable = true;
            }

            break;
          case Web3SuiTransactionCommands.mergeCoins:
            final mergeCoins = command.cast<Web3SuiTransactionCommandMergeCoins>();
            for (final coin in [mergeCoins.destination, ...mergeCoins.sources]) {
              final index = asInput(coin);
              if (index == i) {
                mutable = true;
                break;
              }
            }
            break;
          case Web3SuiTransactionCommands.moveCall:
            if (isReceving && mutable) continue;
            final moveCall = command.cast<Web3SuiTransactionCommandMoveCall>();
            for (int j = 0; j < moveCall.arguments.length; j++) {
              if (isReceving && mutable) break;
              final argument = moveCall.arguments[j];
              if (argument.type != Web3SuiArguments.input) continue;
              final index = asInput(argument);
              if (index != i) continue;
              final abi = await _getAbi(moveCall);
              final param = abi.parameters[j];
              mutable = mutable || param.type != SuiApiMoveNormalizedTypes.reference;
              isReceving = isReceving || _MoveNormalizedArguments.isReceiving(param);
            }
          case Web3SuiTransactionCommands.makeMoveVec:
            final mergeCoins = command.cast<Web3SuiTransactionCommandMakeMoveVec>();
            for (final inp in mergeCoins.elements) {
              final index = asInput(inp);
              if (index == i) {
                mutable = true;
                break;
              }
            }
            break;
          default:
            break;
        }
      }
      await _resolveObject(
          object: unResolveObject,
          isMutable: mutable,
          isReceiving: isReceving,
          inputs: inputs,
          resolvedObjects: resolvedObjects);
    }
  }

  Future<void> _updateSplitCoins(Web3SuiTransactionCommandSplitCoins splitCoins,
      List<Web3SuiTransactionCallArg> inputs) async {
    for (final i in splitCoins.amounts) {
      final pure = _getUnresolvedPure(i, inputs);
      if (pure == null) continue;
      final index = inputs.indexOf(pure);
      final amount = MoveU64.parse(pure.value);
      inputs[index] = Web3SuiTransactionPureArg(bytes: amount.toBcsBase64());
    }
  }

  Future<void> _resolveObject({
    required Web3SuiTransactionUnresolvedObject object,
    required Map<SuiAddress, SuiObjectResponse> resolvedObjects,
    required List<Web3SuiTransactionCallArg> inputs,
    required bool isMutable,
    required bool isReceiving,
  }) async {
    final obj = resolvedObjects[object.objectId];

    Web3SuiTransactionObject updatedObject;
    if (object.initialSharedVersion != null || obj!.initialVersion != null) {
      updatedObject = Web3SuiTransactionObject(Web3SuiTransactionSharedObject(
        objectId: object.objectId,
        initialSharedVersion: object.initialSharedVersion ?? obj!.initialVersion!,
        mutable: isMutable,
      ));
    } else if (isReceiving) {
      updatedObject = Web3SuiTransactionObject(Web3SuiTransactionReceiving(
          objectId: object.objectId,
          version: object.version ?? obj.version,
          digest: object.digest ?? obj.digest));
    } else {
      updatedObject = Web3SuiTransactionObject(Web3SuiTransactionImmOrOwnedObject(
          objectId: object.objectId,
          version: object.version ?? obj.version,
          digest: object.digest ?? obj.digest));
    }
    final index = inputs.indexOf(object);
    inputs[index] = updatedObject;
  }

  Future<void> _updateMoveCall(Web3SuiTransactionCommandMoveCall moveCall,
      List<Web3SuiTransactionCallArg> inputs) async {
    late final List<Web3SuiTransactionArgumentInput> inputsArguments =
        moveCall.arguments.whereType<Web3SuiTransactionArgumentInput>().toList();
    if (inputsArguments.isEmpty) return;
    final abi = await _getAbi(moveCall);
    if (abi.parameters.length != moveCall.arguments.length) {
      throw Web3SuiExceptionConstant.mismatchMoveCallArguments;
    }
    for (int i = 0; i < moveCall.arguments.length; i++) {
      final argument = moveCall.arguments[i];
      final pure = _getUnresolvedPure(argument, inputs);
      if (pure != null) {
        final inputIndex = inputs.indexOf(pure);
        final encode = abi.encodeAt(i, pure.value);
        if (encode != null) {
          inputs[inputIndex] = encode;
          continue;
        } else {
          final address = MethodUtils.fallbackOnException(() => SuiAddress(pure.value),
              logOnDebug: false);
          if (address == null) {
            throw Web3SuiExceptionConstant.fialedToParseTransactionObject(
                pure.value?.toString() ?? 'null');
          }
          inputs[inputIndex] = Web3SuiTransactionUnresolvedObject(objectId: address);
        }
      }
    }
  }

  Future<SuiTransactionDataV1> resolveWeb3Transaction(
      {required Web3SuiTransactionDataV2 transaction,
      required ISuiAddress address}) async {
    final inputs = transaction.inputs.clone();
    final Map<SuiAddress, SuiObjectResponse> resolvedObjects = {};
    await _getUnresolvedObject(
        objectIds: _getUnresolvedObjectIds(inputs), resolvedObjects: resolvedObjects);
    for (final i in transaction.commands) {
      switch (i.type) {
        case Web3SuiTransactionCommands.transferObject:
          await _updateTransferObjectArguments(i.cast(), inputs);
          break;
        case Web3SuiTransactionCommands.splitCoins:
          await _updateSplitCoins(i.cast(), inputs);
          break;
        case Web3SuiTransactionCommands.moveCall:
          await _updateMoveCall(i.cast(), inputs);
          break;
        default:
          break;
      }
    }
    await _resolveObjects(
        transaction: transaction, inputs: inputs, resolvedObjects: resolvedObjects);
    final commands = transaction.commands.map((e) => e.toTrnsactionCommand()).toList();
    final resolvedInputs = inputs.map((e) => e.toTransactionCallArguments()).toList();
    final kind = SuiTransactionKindProgrammableTransaction(
        SuiProgrammableTransaction(inputs: resolvedInputs, commands: commands));
    final gasPrice = transaction.gasData.price ?? await client.getGasPrice();
    final gasData = transaction.gasData.toTransactionGasData(
        owner: address.networkAddress, budget: SuiHelper.toMist("0.1"), price: gasPrice);
    final expiration = transaction.expiration?.toTransactionExpiration() ??
        SuiTransactionExpirationNone();
    return SuiTransactionDataV1(
        expiration: expiration,
        sender: transaction.sender ?? address.networkAddress,
        gasData: gasData,
        kind: kind);
  }

  final Map<SuiAddress, CachedObject<List<SuiToken>>> _accoutTokens = {};

  Future<List<SuiWeb3AccountChangeBalance>?> getSimulateBalanceChanges(
      {required SuiAddress address,
      required List<SuiApiBalanceChange> changes,
      required SuiChain account}) async {
    final cached = _accoutTokens[address] ??= CachedObject();
    final tokens = await cached.get(
        onFetch: () async => await client.getAccountTokens(address, allowSuiCoin: true));
    List<SuiWeb3AccountChangeBalance> changed = [];
    for (final i in changes) {
      if (i.owner.type == SuiApiObjectOwnerType.addressOwner ||
          i.owner.type == SuiApiObjectOwnerType.objectOwner) {}
      SuiWeb3AccountChangeBalance change;
      final amount = BigintUtils.tryParse(i.amount);
      final token = tokens.firstWhereNullable((e) => e.assetType == i.coinType);
      final ownerAddress = () {
        final owner = i.owner;
        switch (owner.type) {
          case SuiApiObjectOwnerType.addressOwner:
            return SuiAddress((owner as SuiApiObjectOwnerAddressOwner).addressOwner);
          case SuiApiObjectOwnerType.objectOwner:
            return SuiAddress((owner as SuiApiObjectOwnerObjectOwner).objectOwner);
          default:
            return null;
        }
      }();
      final ownerAddressInfo = ownerAddress == null
          ? null
          : account.getOrCreateReceiptFromNetworkAddressSync(address: ownerAddress);
      final owner = i.owner.type.name.camelCase;
      if (amount != null && token != null) {
        change = SuiWeb3AccountChangeBalance(
          coinType: i.coinType,
          amountStr: i.amount,
          token: token,
          amount: IntegerBalance.token(amount, token.token, immutable: true),
          owner: owner,
          ownerAddres: ownerAddressInfo,
        );
      } else {
        change = SuiWeb3AccountChangeBalance(
            coinType: i.coinType,
            amountStr: i.amount,
            owner: owner,
            ownerAddres: ownerAddressInfo);
      }
      changed.add(change);
    }
    if (changed.isEmpty) return null;
    return changed;
  }

  @override
  void dispose() {
    super.dispose();
    _accoutTokens.clear();
  }
}
