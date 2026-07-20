import 'package:on_chain_bridge/database/actions/actions.dart';
import 'package:on_chain_bridge/database/core/interface.dart';
import 'package:on_chain_bridge/serialization/src/tags.dart';
import 'package:on_chain_wallet/app/utils/method/result.dart';
import 'package:on_chain_wallet/repository/core/database.dart';

class SyncAppDatabase extends IAppDatabaseApi {
  final IDatabaseApi database;
  const SyncAppDatabase(this.database);
  @override
  Future<IResult<T>> excuteStorage<T extends Object?>(IStorageAction<T> action) async {
    return IResult.call(() async {
      return await database.storageAction(action);
    });
  }

  @override
  Future<IResult<T>> excuteTable<T extends Object?>(ITableAction<T> action) {
    return IResult.call(() async {
      return await database.tableAction(action);
    });
  }

  @override
  Stream<IStorageEvent<Object?>> listenOnTable(String tableId,
      {List<OnChainBrdigeSerializationIdentifier> actions =
          OnChainBrdigeSerializationIdentifier.values}) {
    return Stream.empty();
  }
}
