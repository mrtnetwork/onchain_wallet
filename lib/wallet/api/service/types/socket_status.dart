enum SocketStatus {
  connect,
  disconnect,
  pending,
  dispose;

  bool get isConnect => this == connect;
  bool get isPending => this == pending;
  bool get isDispose => this == dispose;
}
