enum StorageActionId {
  logging(0),
  webview(1),
  web3(2),
  walletConnect(3),
  network(4),
  backup(5),
  chain(6),
  restoreBackup(7),
  wallet(8),
  walletRuntime(9),
  walletKeys(10),
  bridge(11),
  appSettings(12),
  swapSettings(13),
  walletExternalConnection(14),
  unknown(-1);

  final int id;
  const StorageActionId(this.id);
  static StorageActionId fromId(int? id) {
    return values.firstWhere(
      (e) => e.id == id,
      orElse: () => unknown,
    );
  }
}
