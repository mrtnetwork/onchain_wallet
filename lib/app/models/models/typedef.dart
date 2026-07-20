import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';

typedef DynamicVoid = void Function();

typedef ObjectVoid = void Function(Object?);
typedef StringVoid = void Function(String);
typedef StringFunc = String Function();
typedef NullStringString = String? Function(String?);
typedef NullStringT<T> = String? Function(T?);
typedef NullBoolVoid = void Function(bool?);
typedef BoolVoid = void Function(bool);

typedef FutureVoid = Future<void> Function();
typedef FutureT<T> = Future<T> Function();
typedef VoidSetT<T> = Function(Set<T>);
typedef FuncBool<T> = bool Function(T);
typedef BigIntRationalVoid = void Function(BigRational);
typedef BigIntRationalNullString = String? Function(BigRational);
typedef FuncBoolString = bool Function(String);
typedef FuncFutureBoolString = Future<bool> Function(String);
typedef FuncFutureNullableBool = Future<bool?> Function();
typedef FuncFutureNullableBoolString = Future<bool?> Function(String);

typedef IntVoid = void Function(int);
typedef NullableIntVoid = void Function(int?);
typedef BigIntVoid = void Function(BigInt);

typedef FuncVoidNullT<T> = void Function(T);

typedef FutureNullString = Future<String?> Function();

typedef FuncTResult<T> = T? Function(T?);
