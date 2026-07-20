typedef ONSUBSCRIBE = void Function(EthereumSubscribeResult);

class EthereumSubscribeResult {
  final String subscription;
  final Object result;
  const EthereumSubscribeResult(
      {required this.subscription, required this.result});
  factory EthereumSubscribeResult.fromJson(Map<String, dynamic> json) {
    return EthereumSubscribeResult(
        subscription: json["subscription"], result: json["result"]);
  }

  Map<String, dynamic> toJson() {
    return {"subscription": subscription, "result": result};
  }
}
