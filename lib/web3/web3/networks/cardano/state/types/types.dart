import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';

class ADAPaginate {
  final int page;
  final int limit;
  const ADAPaginate({required this.page, required this.limit});
  factory ADAPaginate.fromJson(Map<String, dynamic> json) {
    return ADAPaginate(
      limit: IntUtils.parse(json["limit"]),
      page: IntUtils.parse(json["page"]),
    );
  }
}

class Web3ADAScriptRequirement {
  final String value;
  final int code;
  const Web3ADAScriptRequirement({required this.value, this.code = 3});
  Map<String, dynamic> toWalletConnectJson() {
    return {"code": code, "value": value};
  }
}

class Web3ADAExtension {
  final int cip;
  const Web3ADAExtension({required this.cip});

  Map<String, dynamic> toWalletConnectJson() {
    return {"cip": cip};
  }
}
