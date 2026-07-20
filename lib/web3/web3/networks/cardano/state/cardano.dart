import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:on_chain/ada/ada.dart';
import 'package:on_chain_wallet/crypto/types/networks.dart';
import 'package:on_chain_wallet/web3/web3/constant/constant/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/exception/exception.dart';
import 'package:on_chain_wallet/web3/web3/core/messages/models/models/wallet_response.dart';
import 'package:on_chain_wallet/web3/web3/core/messages/types/message.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/constant/constants/exception.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/methods/methods.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/params/params.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/permission/permission.dart';
import 'package:on_chain_wallet/web3/web3/networks/cardano/state/types/types.dart';
import 'package:on_chain_wallet/web3/web3/state/core/network.dart';
import 'package:on_chain_wallet/web3/web3/state/core/types.dart';
import 'package:on_chain_wallet/web3/web3/utils/web3_validator_utils.dart';

mixin ADAWeb3StateHandler<
        ADDRESS,
        STATEADDRESS extends Web3StateAddress<ADAAddress, Web3ADAChainAccount, ADDRESS,
            Web3ADAChainIdnetifier>,
        STATEACCOUNT extends Web3StateAccount<ADAAddress, Web3ADAChainAccount, ADDRESS,
            Web3ADAChainIdnetifier, STATEADDRESS>,
        RESPONSE,
        REQUEST extends Web3ClientRequest,
        EVENT>
    on Web3StateHandler<ADAAddress, Web3ADAChainAccount, ADDRESS, Web3ADAChainIdnetifier,
        STATEADDRESS, STATEACCOUNT, RESPONSE, REQUEST, EVENT> {
  List<Web3StateAddress<ADAAddress, Web3ADAChainAccount, dynamic, Web3ADAChainIdnetifier>>
      getChainOrDefaultAccounts(
          {required STATEACCOUNT state,
          required Web3ADAChainIdnetifier? network,
          bool? rewardAddress}) {
    network ??= state.defaultChain;
    if (network == null) {
      throw Web3RequestExceptionConst.missingPermission;
    }
    final addresses =
        state.accounts.where((e) => e.networkIdentifier == network).toList();
    if (addresses.isEmpty) {
      throw Web3RequestExceptionConst.missingPermission;
    }
    if (rewardAddress == null) return addresses;
    return addresses
        .where((e) => e.chainaccount.isRewardAddress == rewardAddress)
        .toList();
  }

  @override
  ADAAddress toAddress(String v, {Web3ADAChainIdnetifier? network}) {
    try {
      if (StringUtils.isHexBytes(v)) {
        return ADAAddress.fromRawBytes(BytesUtils.fromHexString(v),
            network: network?.network);
      }
      final address = ADAAddress.fromAddress(v, network: network?.network);
      return address;
    } catch (_) {}
    throw Web3RequestExceptionConst.invalidAddress(key: v, network: networkType.name);
  }

  @override
  NetworkType get networkType => NetworkType.cardano;

  @override
  List<Web3ADARequestMethods> get methods => Web3ADARequestMethods.values;

  List<TransactionUnspentOutput> selectUtxosForValue(
      {required List<TransactionUnspentOutput> totalUtxos, required Value targetValue}) {
    final requiredCoin = targetValue.coin;
    final requiredAssets = targetValue.multiAsset ?? MultiAsset.empty;

    BigInt totalCoin = BigInt.zero;
    MultiAsset totalAssets = MultiAsset.empty;
    final selected = <TransactionUnspentOutput>[];

    // Create a copy so sorting doesn't affect the original list
    final sortedUtxos = List<TransactionUnspentOutput>.from(totalUtxos)
      ..sort((a, b) => a.output.amount.coin.compareTo(b.output.amount.coin));

    // Filter UTxOs if only ADA is required
    final candidateUtxos = requiredAssets.hasAsset
        ? sortedUtxos
        : sortedUtxos.where((u) {
            final ma = u.output.amount.multiAsset;
            return ma == null || ma == MultiAsset.empty;
          }).toList();

    // Iterate until we meet both ADA and asset requirements
    for (final utxo in candidateUtxos) {
      selected.add(utxo);
      totalCoin += utxo.output.amount.coin;
      totalAssets += utxo.output.amount.multiAsset ?? MultiAsset.empty;
      final adaOk = totalCoin >= requiredCoin;
      final assetsOk =
          !requiredAssets.hasAsset || MultiAsset.compare(totalAssets, requiredAssets);

      if (adaOk && assetsOk) {
        return selected;
      }
    }
    return [];
  }

  T? parseCbor<T extends Object>(
      {required Object? object,
      required String name,
      required REQUEST params,
      required STATEACCOUNT state,
      required Web3ADARequestMethods method,
      required T Function(CborObject obj) onParse,
      Web3ADAChainIdnetifier? network}) {
    if (object == null) return null;
    return Web3ValidatorUtils.parseParams2(
      () {
        final asBytes = params.objectAsBytes(
            object: object,
            name: name,
            encoding: [StringEncoding.hex],
            error: Web3ADAExceptionConstant.invalidCborParameters(name));
        return onParse(CborObject.fromCbor(asBytes));
      },
      error: Web3ADAExceptionConstant.invalidCborParameters(name),
    );
  }

  ADAPaginate? parsePaginate(
      {required Object? object,
      required REQUEST params,
      required STATEACCOUNT state,
      required Web3ADARequestMethods method,
      Web3ADAChainIdnetifier? network}) {
    if (object == null) return null;
    return Web3ValidatorUtils.parseParams2(() {
      final toJson = params.objectAsMap(
          object: object,
          name: "Paginate",
          keys: ["page", "limit"],
          error: Web3ADAExceptionConstant.invalidPaginated);
      final page = IntUtils.parse(toJson["page"]);
      final limit = IntUtils.parse(toJson["limit"]);
      if (page.isNegative || limit <= 0) {
        return null;
      }
      return ADAPaginate.fromJson(toJson);
    }, error: Web3ADAExceptionConstant.invalidPaginated);
  }

  List<T> paginate<T>({required List<T> items, required ADAPaginate? paginated}) {
    if (paginated == null) return items;
    final maxSize = items.length;
    final totalPages = (maxSize / paginated.limit).ceil();

    // If page is outside the available range
    if (paginated.page >= totalPages) {
      throw Web3ADAExceptionConstant.paginateReached(maxSize);
    }

    // Calculate start and end indexes
    final startIndex = paginated.page * paginated.limit;
    final endIndex = (startIndex + paginated.limit).clamp(0, maxSize);

    return items.sublist(startIndex, endIndex);
  }

  (List<Web3ADAChainAccount>, Web3ADASignTransactionParams) parseTransferObject(
      {required REQUEST params,
      required Map<String, dynamic> param,
      required STATEACCOUNT state,
      required Web3ADARequestMethods method,
      Web3ADAChainIdnetifier? network}) {
    return Web3ValidatorUtils.parseParams2(() {
      final accounts = Web3ValidatorUtils.parseParams2(() {
        final accountsJson = param["account"] ?? param["accounts"];
        if (accountsJson == null) return null;
        if (accountsJson is List) {
          final accounts = accountsJson
              .map((e) => tryParseStateAddress(
                  addr: e, params: params, state: state, network: network))
              .cast<ParsedNetworkStateAddress<ADAAddress, Web3ADAChainIdnetifier>>();
          if (accounts.isEmpty) return null;
          return accounts
              .map((e) => state.findAddressOrDefault(
                  address: e.address, network: network ?? e.chain))
              .toList();
        }
        final account = tryParseStateAddress(
            addr: accountsJson, params: params, state: state, network: network);
        if (account == null) return null;
        return [
          state.findAddressOrDefault(
              address: account.address, network: network ?? account.chain)
        ];
      }, error: Web3ADAExceptionConstant.invalidWsTransactionParams);

      final txBytes = params.objectAsBytes(
          object: param['transaction'],
          encoding: [StringEncoding.hex],
          name: 'transaction',
          error: Web3ADAExceptionConstant.invalidWsTransactionParams);
      final partialSign = Web3ValidatorUtils.parseBool<bool?>(
          key: "partialSign", method: method, json: param);
      return (
        accounts,
        Web3ADASignTransactionParams(
            transaction: ADATransaction.fromCborBytes(txBytes),
            partialSign: partialSign ?? false)
      );
    }, error: Web3ADAExceptionConstant.invalidWsTransactionParams);
  }

  int findErrorCode(
      {required Web3ErrorCode error, required Web3ADARequestMethods? method}) {
    if (method == null) return -1;
    switch (error) {
      case Web3ErrorCode.invalidRequest:
      case Web3ErrorCode.invalidParams:
        return -1;
      case Web3ErrorCode.internalError:
        return -2;
      case Web3ErrorCode.refused:
      case Web3ErrorCode.rpcError:
        switch (method) {
          case Web3ADARequestMethods.signData:
          case Web3ADARequestMethods.signMessage:
            return 2;
          case Web3ADARequestMethods.signTransaction:
          case Web3ADARequestMethods.signTx:
          case Web3ADARequestMethods.signAndSendTransaction:
          case Web3ADARequestMethods.submitTx:
          case Web3ADARequestMethods.submitTxs:
          case Web3ADARequestMethods.submitUnsignedTx:
            return 1;
          default:
            return -3;
        }
      case Web3ErrorCode.invalidOrDisabledClient:
      case Web3ErrorCode.missingPermission:
      case Web3ErrorCode.rejectedByUser:
        switch (method) {
          case Web3ADARequestMethods.signData:
          case Web3ADARequestMethods.signMessage:
            return 3;
          case Web3ADARequestMethods.signTransaction:
          case Web3ADARequestMethods.signTx:
          case Web3ADARequestMethods.signTxs:
          case Web3ADARequestMethods.signAndSendTransaction:
            return 2;
          default:
            return -3;
        }
      default:
        return error.code;
    }
  }

  Web3ADASignTransaction toSignTransactionRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3ADARequestMethods method,
      Web3ADAChainIdnetifier? network}) {
    if (!state.hasAccount) {
      throw Web3RequestExceptionConst.missingPermission;
    }
    return Web3ValidatorUtils.parseParams2(() {
      final List<Web3ADASignTransactionParams> transactions = [];
      List<Web3ADAChainAccount> accounts = [];
      for (int i = 0; i < params.requestParams.length; i++) {
        final param = params.elementAsMap(i, keys: ["transaction"], method: method);
        final tx = parseTransferObject(
            params: params, param: param, state: state, method: method);
        transactions.add(tx.$2);
        accounts.addAll(tx.$1);
      }
      if (transactions.isEmpty) return null;
      if (accounts.isEmpty) {
        throw Web3RequestExceptionConst.missingPermission;
      }
      if (accounts.map((e) => e.id).toSet().length != 1) {
        throw Web3ADAExceptionConstant.invalidRequestAccounts;
      }

      return Web3ADASignTransaction(
          transactions: transactions,
          accounts: accounts.toSet().toList(),
          method: method);
    }, error: Web3ADAExceptionConstant.invalidWsTransactionParams);
  }

  Web3ADASignTransaction toSignTxRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3ADARequestMethods method,
      Web3ADAChainIdnetifier? network}) {
    if (!state.hasAccount) {
      throw Web3RequestExceptionConst.missingPermission;
    }
    final addresses = getChainOrDefaultAccounts(state: state, network: network);
    if (addresses.isEmpty) {
      throw Web3RequestExceptionConst.missingPermission;
    }
    return Web3ValidatorUtils.parseParams2(() {
      final param = params.getParams(length: 1);
      final txBytes = params.objectAsBytes(
          object: param[0],
          encoding: [StringEncoding.hex],
          name: 'transaction',
          error: Web3ADAExceptionConstant.invalidTransaction);
      final adataTransaction = ADATransaction.fromCborBytes(txBytes);

      final partialSign = params.tryElementAsBolean(1);

      return Web3ADASignTransaction(transactions: [
        Web3ADASignTransactionParams(
            transaction: adataTransaction, partialSign: partialSign ?? false)
      ], accounts: addresses.map((e) => e.chainaccount).toList(), method: method);
    }, error: Web3ADAExceptionConstant.invalidTransaction);
  }

  Web3ADASignTransaction toSubmitTxes(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3ADARequestMethods method,
      Web3ADAChainIdnetifier? network}) {
    if (!state.hasAccount) {
      throw Web3RequestExceptionConst.missingPermission;
    }
    final addresses = getChainOrDefaultAccounts(state: state, network: network);
    if (addresses.isEmpty) {
      throw Web3RequestExceptionConst.missingPermission;
    }
    return Web3ValidatorUtils.parseParams2(() {
      List<Web3ADASignTransactionParams> transactions = [];
      for (final i in params.requestParams) {
        final txBytes = params.objectAsBytes(
            object: i,
            encoding: [StringEncoding.hex],
            name: 'transaction',
            error: Web3ADAExceptionConstant.invalidTransaction);
        final adataTransaction = ADATransaction.fromCborBytes(txBytes);
        transactions.add(Web3ADASignTransactionParams(
            transaction: adataTransaction, partialSign: false));
      }
      return Web3ADASignTransaction(
          transactions: transactions,
          accounts: addresses.map((e) => e.chainaccount).toList(),
          method: method);
    }, error: Web3ADAExceptionConstant.invalidTransaction);
  }

  Web3WalletResponseMessage toIsEnabledRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3ADARequestMethods method,
      Web3ADAChainIdnetifier? network}) {
    return createResponse(state.hasChainAccount);
  }

  Web3ADASignTransaction toSignTxsRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3ADARequestMethods method,
      Web3ADAChainIdnetifier? network}) {
    if (!state.hasAccount) {
      throw Web3RequestExceptionConst.missingPermission;
    }
    final addresses = getChainOrDefaultAccounts(state: state, network: network);
    if (addresses.isEmpty) {
      throw Web3RequestExceptionConst.missingPermission;
    }
    return Web3ValidatorUtils.parseParams2(
      () {
        final List<Web3ADASignTransactionParams> transactions = [];
        for (final i in params.requestParams) {
          final data = params.objectAsMap(
            object: i,
            name: "cbor",
            keys: ["cbor"],
            error: Web3ADAExceptionConstant.invalidBatchTransaction,
          );
          final txBytes = params.objectAsBytes(
            object: data["cbor"],
            name: "cbor",
            encoding: [StringEncoding.hex],
            error: Web3ADAExceptionConstant.invalidBatchTransaction,
          );
          final transaction = ADATransaction.fromCborBytes(txBytes);
          final partialSign = Web3ValidatorUtils.parseBool<bool?>(
              key: "partialSign", method: method, json: data);
          transactions.add(Web3ADASignTransactionParams(
              transaction: transaction, partialSign: partialSign ?? false));
        }
        if (transactions.isEmpty) return null;
        return Web3ADASignTransaction(
            transactions: transactions,
            accounts: addresses.map((e) => e.chainaccount).toList(),
            method: method);
      },
      error: Web3ADAExceptionConstant.invalidBatchTransaction,
    );
  }

  Web3WalletResponseMessage toGetNetworkIdRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3ADARequestMethods method,
      Web3ADAChainIdnetifier? network}) {
    final networkId = state.defaultChain?.network.value ?? ADANetwork.mainnet.value;
    return createResponse(networkId);
  }

  Web3WalletResponseMessage toGetBalanceRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3ADARequestMethods method,
      Web3ADAChainIdnetifier? network}) {
    if (!state.hasChainAccount) {
      throw Web3RequestExceptionConst.missingPermission;
    }
    final addresses =
        getChainOrDefaultAccounts(state: state, network: network, rewardAddress: false);
    if (addresses.isEmpty) {
      throw Web3RequestExceptionConst.missingPermission;
    }
    final balances = addresses
        .where((e) => !e.chainaccount.isRewardAddress)
        .expand((e) => e.chainaccount.utxos);
    final value =
        balances.fold<Value>(Value(coin: BigInt.zero), (p, v) => p + v.output.amount);
    return createResponse(value.toCbor().toCborHex());
  }

  Web3WalletResponseMessage toGetChangeAddressRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3ADARequestMethods method,
      Web3ADAChainIdnetifier? network}) {
    final addresses =
        getChainOrDefaultAccounts(state: state, network: network, rewardAddress: false);
    if (addresses.isEmpty) {
      throw Web3RequestExceptionConst.missingPermission;
    }
    final account = addresses
        .firstWhereNullable((e) => !e.chainaccount.isRewardAddress && e.isDefault);
    if (account == null) {
      throw Web3RequestExceptionConst.missingPermission;
    }

    return createResponse(account.chainaccount.asCborAddress);
  }

  Future<Web3WalletResponseMessage> toGetUtxos(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3ADARequestMethods method,
      Web3ADAChainIdnetifier? network}) async {
    if (!state.hasChainAccount) {
      throw Web3RequestExceptionConst.missingPermission;
    }

    state = await silentConnetInternal();
    final addresses =
        getChainOrDefaultAccounts(state: state, network: network, rewardAddress: false);
    if (addresses.isEmpty) {
      throw Web3RequestExceptionConst.missingPermission;
    }
    return Web3ValidatorUtils.parseParams2(() {
      final addressesUtxos = addresses.expand((e) => e.chainaccount.utxos).toList();
      final value = parseCbor(
          object: params.tryElementAs(0),
          name: "amount",
          params: params,
          state: state,
          method: method,
          onParse: (obj) => Value.deserialize(obj));
      if (value == null) {
        final utxos = addressesUtxos.map((e) => e.toCbor().toCborHex()).toList();
        final respone = paginate(
            items: utxos,
            paginated: parsePaginate(
                params: params,
                state: state,
                method: method,
                object: params.tryElementAs(1)));
        return createResponse(respone);
      }
      final utxo = selectUtxosForValue(totalUtxos: addressesUtxos, targetValue: value);
      return createResponse(utxo.map((e) => e.toCbor().toCborHex()));
    });
  }

  Future<Web3WalletResponseMessage> toGetAddressUtxos(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3ADARequestMethods method,
      Web3ADAChainIdnetifier? network}) async {
    if (!state.hasChainAccount) {
      throw Web3RequestExceptionConst.missingPermission;
    }
    state = await silentConnetInternal();
    return Web3ValidatorUtils.parseParams2(() {
      Map<String, dynamic> data = params.elementAsMap(0, keys: ["account"]);
      final account = Web3ValidatorUtils.parseParams2(() {
        final accountsJson = data["account"];
        final account = tryParseStateAddress(
            addr: accountsJson, params: params, state: state, network: network);
        if (account == null || account.address.isRewardAddress) return null;
        return state.findAddressOrDefault(
            address: account.address, network: network ?? account.chain);
      },
          error: Web3RequestExceptionConst.invalidAddress(
              key: 'account', network: networkType.name));

      final utxos = account.utxos.map((e) => e.toCbor().toCborHex()).toList();
      return createResponse(utxos);
    });
  }

  Web3WalletResponseMessage toGetUsedAddresses(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3ADARequestMethods method,
      Web3ADAChainIdnetifier? network}) {
    if (!state.hasAccount) {
      throw Web3RequestExceptionConst.missingPermission;
    }
    final addresses =
        getChainOrDefaultAccounts(state: state, network: network, rewardAddress: false);
    final usedAddresses = addresses
        .where((e) => !e.chainaccount.isRewardAddress && e.chainaccount.utxos.isNotEmpty)
        .map((e) => e.chainaccount.asCborAddress)
        .toList();
    final respone = paginate(
        items: usedAddresses,
        paginated: parsePaginate(
            params: params,
            state: state,
            method: method,
            object: params.tryElementAs(0)));
    return createResponse(respone);
  }

  Web3WalletResponseMessage toGetUnusedAddressess(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3ADARequestMethods method,
      Web3ADAChainIdnetifier? network}) {
    if (!state.hasAccount) {
      throw Web3RequestExceptionConst.missingPermission;
    }
    final addresses =
        getChainOrDefaultAccounts(state: state, network: network, rewardAddress: false);
    final unUsedAddresses = addresses
        .where((e) => !e.chainaccount.isRewardAddress && e.chainaccount.utxos.isEmpty)
        .map((e) => e.chainaccount.asCborAddress)
        .toList();
    final respone = paginate(
        items: unUsedAddresses,
        paginated: parsePaginate(
            params: params,
            state: state,
            method: method,
            object: params.tryElementAs(0)));
    return createResponse(respone);
  }

  Web3WalletResponseMessage toGetRewardAddresses(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3ADARequestMethods method,
      Web3ADAChainIdnetifier? network}) {
    if (!state.hasAccount) {
      throw Web3RequestExceptionConst.missingPermission;
    }
    final addresses =
        getChainOrDefaultAccounts(state: state, network: network, rewardAddress: true);
    final rewardAddresses = addresses.map((e) => e.chainaccount).toList();
    return createResponse(rewardAddresses.map((e) => e.asCborAddress).toList());
  }

  Web3MessageCore toGetCollateral(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3ADARequestMethods method,
      Web3ADAChainIdnetifier? network}) {
    if (!state.hasAccount) {
      throw Web3RequestExceptionConst.missingPermission;
    }
    final addresses =
        getChainOrDefaultAccounts(state: state, network: network, rewardAddress: false);
    final paymentAccount = addresses.map((e) => e.chainaccount).toList();
    if (paymentAccount.isEmpty) {
      return createResponse();
    }
    return Web3ValidatorUtils.parseParams2(() {
      final elem = params.tryElementAs(0);
      BigInt? amount;
      if (elem != null) {
        final data = params.elementAsMap(0,
            keys: ["amount"],
            error: Web3ADAExceptionConstant.invalidCborParameters("amount"));
        amount = parseCbor(
            object: data["amount"],
            name: "amount",
            params: params,
            state: state,
            method: method,
            onParse: (obj) => (obj as CborNumeric).toBigInt());
      }
      return Web3ADAGetCollateral(accounts: paymentAccount, coin: amount);
    });
  }

  Web3MessageCore toGetAccountPub(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3ADARequestMethods method,
      Web3ADAChainIdnetifier? network}) {
    if (!state.hasAccount) {
      throw Web3RequestExceptionConst.missingPermission;
    }
    return Web3ValidatorUtils.parseParams2(() {
      Web3ADAChainAccount? account;
      final addr = params.tryElementAs(0);
      if (addr != null) {
        Map<String, dynamic> data = params.elementAsMap(0);
        account = Web3ValidatorUtils.parseParams2(() {
          final accountsJson = data["account"] ?? data["address"];
          final account = tryParseStateAddress(
              addr: accountsJson, params: params, state: state, network: network);
          if (account == null || account.address.isRewardAddress) return null;
          return state.findAddressOrDefault(
              address: account.address, network: network ?? account.chain);
        },
            error: Web3RequestExceptionConst.invalidAddress(
                key: 'account', network: networkType.name));
      }
      account ??= state.findAddressOrDefault(network: network);
      if (account.isScript) {
        throw Web3ADAExceptionConstant.unableToAccessBip32PublicKey;
      }
      return Web3ADAGetAccountPub(accessAccount: account);
    });
  }

  Web3MessageCore toGetExtensions(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3ADARequestMethods method,
      Web3ADAChainIdnetifier? network}) {
    return createResponse(
        [30, 103, 106, 104].map((e) => Web3ADAExtension(cip: e)).toList());
  }

  Web3MessageCore toGetScriptRequirements(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3ADARequestMethods method,
      Web3ADAChainIdnetifier? network}) {
    if (!state.hasAccount) {
      throw Web3RequestExceptionConst.missingPermission;
    }
    return Web3ValidatorUtils.parseParams2(() {
      Web3ADAChainAccount? account;
      final addr = params.tryElementAs(0);
      if (addr != null) {
        Map<String, dynamic> data = params.elementAsMap(0);
        account = Web3ValidatorUtils.parseParams2(() {
          final accountsJson = data["account"] ?? data["address"];
          final account = tryParseStateAddress(
              addr: accountsJson, params: params, state: state, network: network);
          if (account == null || account.address.isRewardAddress) return null;
          return state.findAddressOrDefault(
              address: account.address, network: network ?? account.chain);
        },
            error: Web3RequestExceptionConst.invalidAddress(
                key: 'account', network: networkType.name));
      }
      account ??= state.findAddressOrDefault(network: network);
      final mSig = account.multisig;
      if (mSig == null) {
        throw Web3ADAExceptionConstant.walletNotConnectedToScript;
      }
      final scripts = mSig.requirementsKeyHashes
          .map((e) => Web3ADAScriptRequirement(value: e))
          .toList();
      return createResponse(scripts);
    });
  }

  Web3MessageCore toGetScriptRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3ADARequestMethods method,
      Web3ADAChainIdnetifier? network}) {
    if (!state.hasAccount) {
      throw Web3RequestExceptionConst.missingPermission;
    }
    return Web3ValidatorUtils.parseParams2(() {
      Web3ADAChainAccount? account;
      final addr = params.tryElementAs(0);
      if (addr != null) {
        Map<String, dynamic> data = params.elementAsMap(0);
        account = Web3ValidatorUtils.parseParams2(() {
          final accountsJson = data["account"] ?? data["address"];
          final account = tryParseStateAddress(
              addr: accountsJson, params: params, state: state, network: network);
          if (account == null || account.address.isRewardAddress) return null;
          return state.findAddressOrDefault(
              address: account.address, network: network ?? account.chain);
        },
            error: Web3RequestExceptionConst.invalidAddress(
                key: 'account', network: networkType.name));
      }
      account ??= state.findAddressOrDefault(network: network);
      final mSig = account.multisig;
      if (mSig == null) {
        throw Web3ADAExceptionConstant.walletNotConnectedToScript;
      }
      return createResponse(mSig.script.serializeHex());
    });
  }

  Web3MessageCore toGetCompletedTx(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3ADARequestMethods method,
      Web3ADAChainIdnetifier? network}) {
    throw Web3ADAExceptionConstant.transactionNotFound;
  }

  Web3ADASignMessage toSignMessageRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3ADARequestMethods method,
      Web3ADAChainIdnetifier? network}) {
    return Web3ValidatorUtils.parseParams2(() {
      const List<String> keys = ["message"];
      final data = params.paramsAsMap(keys: keys, method: method);
      final account = Web3ValidatorUtils.parseParams2(() {
        final account = tryParseStateAddress(
            addr: data["address"] ?? data["account"],
            params: params,
            state: state,
            network: network);
        if (account == null) return null;
        return state.findAddressOrDefault(
            address: account.address, network: network ?? account.chain);
      },
          error: Web3RequestExceptionConst.invalidAddressArgrument(
              key: "address", network: networkType.name));
      if (account.publicKey == null) {
        throw Web3ADAExceptionConstant.unsuportedSigningMessageAccount;
      }
      final message = params.objectAsBytes(
          object: data["message"],
          name: "message",
          encoding: [StringEncoding.hex, StringEncoding.utf8]);
      return Web3ADASignMessage(
          accessAccount: account,
          challeng: BytesUtils.toHexString(message),
          content: StringUtils.tryDecode(message));
    });
  }

  Web3ADASignData toSignDataRequest(
      {required REQUEST params,
      required STATEACCOUNT state,
      required Web3ADARequestMethods method,
      Web3ADAChainIdnetifier? network}) {
    return Web3ValidatorUtils.parseParams2(() {
      final account = Web3ValidatorUtils.parseParams2(() {
        final account = tryParseStateAddress(
            addr: params.tryElementAs(0), params: params, state: state, network: network);
        if (account == null) return null;
        return state.findAddressOrDefault(
            address: account.address, network: network ?? account.chain);
      },
          error: Web3RequestExceptionConst.invalidAddressArgrument(
              key: "address", network: networkType.name));
      if (account.publicKey == null) {
        throw Web3ADAExceptionConstant.unsuportedSigningMessageAccount;
      }
      final message = params.objectAsBytes(
          object: params.tryElementAs(1),
          name: "payload",
          encoding: [StringEncoding.hex, StringEncoding.utf8]);
      return Web3ADASignData(
          accessAccount: account,
          challeng: BytesUtils.toHexString(message),
          content: StringUtils.tryDecode(message));
    });
  }

  @override
  Future<Web3MessageCore> request(REQUEST message,
      {Web3ADAChainIdnetifier? network}) async {
    final method = Web3ADARequestMethods.fromName(message.method);
    final state = await getState();
    if (method == null) {
      throw Web3RequestExceptionConst.methodDoesNotExist;
    }
    switch (method) {
      case Web3ADARequestMethods.requestAccounts:
        return onConnect_(message);
      case Web3ADARequestMethods.signTransaction:
      case Web3ADARequestMethods.signAndSendTransaction:
        return toSignTransactionRequest(params: message, state: state, method: method);
      case Web3ADARequestMethods.getAddressUtxos:
        return toGetAddressUtxos(params: message, state: state, method: method);
      case Web3ADARequestMethods.signTxs:
        return toSignTxsRequest(params: message, state: state, method: method);
      case Web3ADARequestMethods.submitTxs:
        return toSubmitTxes(params: message, state: state, method: method);
      case Web3ADARequestMethods.signTx:
      case Web3ADARequestMethods.submitTx:
      case Web3ADARequestMethods.submitUnsignedTx:
        return toSignTxRequest(params: message, state: state, method: method);
      case Web3ADARequestMethods.signMessage:
        return toSignMessageRequest(
            params: message, state: state, method: method, network: network);
      case Web3ADARequestMethods.signData:
        return toSignDataRequest(
            params: message, state: state, method: method, network: network);
      case Web3ADARequestMethods.isEnabled:
        return toIsEnabledRequest(
            params: message, state: state, method: method, network: network);
      case Web3ADARequestMethods.getNetworkId:
        return toGetNetworkIdRequest(
            params: message, state: state, method: method, network: network);
      case Web3ADARequestMethods.getBalance:
        return toGetBalanceRequest(
            params: message, state: state, method: method, network: network);
      case Web3ADARequestMethods.getUtxos:
        return toGetUtxos(
            params: message, state: state, method: method, network: network);
      case Web3ADARequestMethods.getChangeAddress:
        return toGetChangeAddressRequest(
            params: message, state: state, method: method, network: network);
      case Web3ADARequestMethods.getUnusedAddresses:
        return toGetUnusedAddressess(
            params: message, state: state, method: method, network: network);
      case Web3ADARequestMethods.getUsedAddresses:
        return toGetUsedAddresses(
            params: message, state: state, method: method, network: network);
      case Web3ADARequestMethods.getRewardAddresses:
        return toGetRewardAddresses(
            params: message, state: state, method: method, network: network);
      case Web3ADARequestMethods.getCollateral:
        return toGetCollateral(
            params: message, state: state, method: method, network: network);
      case Web3ADARequestMethods.getAccountPub:
        return toGetAccountPub(
            params: message, state: state, method: method, network: network);
      case Web3ADARequestMethods.getScriptRequirements:
        return toGetScriptRequirements(
            params: message, state: state, method: method, network: network);
      case Web3ADARequestMethods.getScript:
        return toGetScriptRequest(
            params: message, state: state, method: method, network: network);
      case Web3ADARequestMethods.getCompletedTx:
        return toGetCompletedTx(params: message, state: state, method: method);
      case Web3ADARequestMethods.getExtensions:
        return toGetExtensions(params: message, state: state, method: method);
      default:
        throw Web3RequestExceptionConst.methodDoesNotSupport;
    }
  }
}
