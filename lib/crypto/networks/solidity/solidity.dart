import 'package:on_chain/solidity/address/core.dart';
import 'package:on_chain/solidity/contract/fragments.dart';

class SolidityContractUtils {
  static const int abiSelectorLength = 4;

  static List<int>? getSelector(List<int> data) {
    if (data.length >= abiSelectorLength) {
      return data.sublist(0, abiSelectorLength);
    }
    return null;
  }

  static final AbiFunctionFragment erc20Decimal =
      AbiFunctionFragment.fromJson(const {
    "inputs": [],
    "name": "decimals",
    "outputs": [
      {"internalType": "uint8", "name": "", "type": "uint8"}
    ],
    "stateMutability": "view",
    "type": "function"
  });
  static final AbiFunctionFragment erc20Balance =
      AbiFunctionFragment.fromJson(const {
    "inputs": [
      {"internalType": "address", "name": "account", "type": "address"}
    ],
    "name": "balanceOf",
    "outputs": [
      {"internalType": "uint256", "name": "", "type": "uint256"}
    ],
    "stateMutability": "view",
    "type": "function"
  });
  static final AbiFunctionFragment erc20Name =
      AbiFunctionFragment.fromJson(const {
    "inputs": [],
    "name": "name",
    "outputs": [
      {"internalType": "string", "name": "", "type": "string"}
    ],
    "stateMutability": "view",
    "type": "function"
  });
  static final AbiFunctionFragment supperInterfaceId =
      AbiFunctionFragment.fromJson(const {
    "inputs": [
      {"internalType": "bytes4", "name": "interfaceId", "type": "bytes4"}
    ],
    "name": "supportsInterface",
    "outputs": [
      {"internalType": "bool", "name": "", "type": "bool"}
    ],
    "stateMutability": "view",
    "type": "function"
  });

  static final AbiFunctionFragment erc20Symbol =
      AbiFunctionFragment.fromJson(const {
    "inputs": [],
    "name": "symbol",
    "outputs": [
      {"internalType": "string", "name": "", "type": "string"}
    ],
    "stateMutability": "view",
    "type": "function"
  });
  static final AbiFunctionFragment erc20Transfer =
      AbiFunctionFragment.fromJson(const {
    "inputs": [
      {"internalType": "address", "name": "to", "type": "address"},
      {"internalType": "uint256", "name": "value", "type": "uint256"}
    ],
    "name": "transfer",
    "outputs": [
      {"internalType": "bool", "name": "", "type": "bool"}
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  });

  static SolidityEncoderResult<SolidityAddress, BigInt, void, void, void>
      decodeErc20Transfer(List<int> data) {
    return decodeInput(fragment: erc20Transfer, data: data);
  }

  static T _getEncodedValue<T>(int index, List<dynamic> result) {
    final r = result.elementAtOrNull(index);
    if (r == null && null is T) return null as T;
    return r as T;
  }

  static SolidityEncoderResult<A, B, C, D, E> decodeInput<A, B, C, D, E>(
      {required AbiFunctionFragment fragment, required List<int> data}) {
    final encode = fragment.decodeInput(data);
    return SolidityEncoderResult.from(
        () => _getEncodedValue(0, encode),
        () => _getEncodedValue(1, encode),
        () => _getEncodedValue(2, encode),
        () => _getEncodedValue(3, encode),
        () => _getEncodedValue(4, encode));
  }
}

typedef OnEncodeFragment<T> = T Function();

class SolidityEncoderResult<A, B, C, D, E> {
  final A a;
  final B b;
  final C c;
  final D d;
  final E e;

  SolidityEncoderResult._({
    required this.a,
    required this.b,
    required this.c,
    required this.d,
    required this.e,
  });
  static SolidityEncoderResult<A, B, C, D, E> from<A, B, C, D, E>(
    OnEncodeFragment<A>? a,
    OnEncodeFragment<B>? b,
    OnEncodeFragment<C>? c,
    OnEncodeFragment<D>? d,
    OnEncodeFragment<E>? e,
  ) {
    return SolidityEncoderResult<A, B, C, D, E>._(
        a: a?.call() as A,
        b: b?.call() as B,
        c: c?.call() as C,
        d: d?.call() as D,
        e: e?.call() as E);
  }
}
