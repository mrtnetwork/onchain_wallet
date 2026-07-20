part of 'package:on_chain_wallet/wallet/chain/chain/chain.dart';

sealed class ChainAction<RESPONSE extends Object?, CHAIN extends APPCHAIN> {
  Future<IResult<RESPONSE>> execute(CHAIN chain);
  const ChainAction();
}

sealed class ChainActionGeneric<RESPONSE extends Object?>
    extends ChainAction<RESPONSE, APPCHAIN> {
  const ChainActionGeneric();
}

class ChainActionConnect extends ChainActionGeneric<NetworkApiProvider> {
  @override
  Future<IResult<NetworkApiProvider>> execute(APPCHAIN chain) async {
    throw UnimplementedError();
    // final result = await chain.client();
    // return result.map((e) => e.networkProvider);
  }
}

sealed class ChainActionToken<RESPONSE extends Object?>
    extends ChainAction<RESPONSE, APPCHAIN> {
  const ChainActionToken();
}

final class ChainActionRemoveToken extends ChainActionToken<bool> {
  final String token;
  final String account;
  const ChainActionRemoveToken._({required this.account, required this.token});
  static ChainActionRemoveToken
      from<TOKEN extends TokenCore, ACCOUNT extends ACCOUNTTOKEN<TOKEN>>({
    required TOKEN token,
    required ACCOUNT account,
  }) {
    return ChainActionRemoveToken._(account: account.identifier, token: token.identifier);
  }

  @override
  Future<IResult<bool>> execute(APPCHAIN chain) async {
    final account = await chain.getAddressFromIdentifier(this.account);
    return account.andThenAsync((e) async {
      final token = await e.getTokenFromIdentifier(this.token);
      return token.andThenAsync((token) async {
        return await e._removeToken(token);
      });
    });
  }
}

final class ChainActionUpdateToken extends ChainActionToken<bool> {
  final String token;
  final String account;
  final Token updateToken;
  const ChainActionUpdateToken._(
      {required this.token, required this.account, required this.updateToken});
  static ChainActionUpdateToken
      from<TOKEN extends TokenCore, ACCOUNT extends ACCOUNTTOKEN<TOKEN>>(
          {required TOKEN token, required ACCOUNT account, required Token updateToken}) {
    return ChainActionUpdateToken._(
        account: account.identifier, token: token.identifier, updateToken: updateToken);
  }

  @override
  Future<IResult<bool>> execute(APPCHAIN chain) async {
    final account = await chain.getAddressFromIdentifier(this.account);
    return account.andThenAsync((e) async {
      final token = await e.getTokenFromIdentifier(this.token);
      return token.andThenAsync((token) async {
        final update = await e._updateToken(updateToken, token);
        return update.map((e) => e != null);
      });
    });
  }
}

final class ChainActionAddNewToken extends ChainActionToken<bool> {
  final TokenCore token;
  final String account;
  const ChainActionAddNewToken._({required this.token, required this.account});
  static ChainActionAddNewToken
      from<TOKEN extends TokenCore, ACCOUNT extends ACCOUNTTOKEN<TOKEN>>(
          {required TOKEN token, required ACCOUNT account, required Token updateToken}) {
    return ChainActionAddNewToken._(account: account.identifier, token: token);
  }

  @override
  Future<IResult<bool>> execute(APPCHAIN chain) async {
    final account = await chain.getAddressFromIdentifier(this.account);
    return account.andThenAsync((account) async {
      final result = await account._addToken(token);
      return result.map((_) => true);
    });
  }
}

final class ChainActionSetAccountName extends ChainActionGeneric<bool> {
  final String name;
  final String account;
  const ChainActionSetAccountName._({required this.account, required this.name});
  static ChainActionSetAccountName
      from<TOKEN extends TokenCore, ACCOUNT extends ACCOUNTTOKEN<TOKEN>>({
    required ChainAccount account,
    required String name,
  }) {
    return ChainActionSetAccountName._(account: account.identifier, name: name);
  }

  @override
  Future<IResult<bool>> execute(APPCHAIN chain) async {
    final account = await chain.getAddressFromIdentifier(this.account);
    return account.andThenAsync((account) async {
      return await account._updateAccountName(name);
    });
  }
}

final class ChainActionAddNewContact extends ChainActionGeneric<bool> {
  final NetworkContact contact;
  const ChainActionAddNewContact._({required this.contact});
  static ChainActionSetAccountName from({
    required ChainAccount account,
    required String name,
  }) {
    return ChainActionSetAccountName._(account: account.identifier, name: name);
  }

  @override
  Future<IResult<bool>> execute(APPCHAIN chain) async {
    return IResult.call(
      () async {
        throw Exception();
        // final contacts = await chain.getAccountContacts();
        // if (contacts.contains(contact) || contacts.any((e) => e.name == contact.name)) {
        //   throw WalletExceptionConst.contactExists;
        // }
        // if (contact.name.length < 3 ||
        //     contact.addressObject.blockchainNetwork != chain.network.type.network) {
        //   throw WalletExceptionConst.invalidContactDetails;
        // }
        // final result = await chain._saveContact(contact);
        // return result.fold(
        //   onOk: (value) {
        //     chain._contacts = [contact, ...chain._contacts].immutable;
        //     return true;
        //   },
        // );
      },
    );
    // final account = await chain.getAddressFromIdentifier(this.account);
    // return account.andThenAsync((account) async {
    //   return await account._setAccountName(name);
    // });
  }
}

final class ChainActionAddRemoveContact extends ChainActionGeneric<bool> {
  final String contact;
  const ChainActionAddRemoveContact._({required this.contact});
  static ChainActionAddRemoveContact from(NetworkContact contact) {
    return ChainActionAddRemoveContact._(contact: contact.identifier);
  }

  @override
  Future<IResult<bool>> execute(APPCHAIN chain) async {
    throw UnimplementedError();
    // final contact = await chain.getContactFromIdentifier(this.contact);
    // return contact.andThenAsync((e) async {
    //   final remove = await chain._removeContact(e);
    //   return remove.map(
    //     (_) {
    //       final newContacts = chain._contacts.where((element) => element != e).toList();
    //       chain._contacts = newContacts.toImutableList;
    //       return true;
    //     },
    //   );
    // });
  }
}
