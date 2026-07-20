import 'dart:js_interop';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:on_chain_bridge/web/api/types/types.dart';
import 'package:on_chain_bridge/web/utils/utils.dart';
import 'package:on_chain_wallet/app/core.dart';

extension ExtJsToIResult<T extends JSAny?, E extends JSAny> on ResultOrErrorJs<T, E>? {
  IResult<TD> toIResult<TD extends Object?, ED extends Object>({
    required TD Function(T ok) onResult,
    required IException Function(E err) onErr,
  }) {
    final result = this;
    if (result.isUndefinedOrNull || result == null) {
      return ResultErr.fromException(AppInternalError());
    }
    final err = result.err;
    if (result.errNullable.isDefinedAndNotNull) {
      return ResultErr.fromException(onErr(err));
    }
    return ResultOk(onResult(result.ok));
  }

  void fold(
      {void Function(T ok)? onResult,
      void Function(E err)? onErr,
      void Function()? onInvalid}) {
    final result = this;
    if (result.isUndefinedOrNull || result == null) {
      if (onInvalid != null) onInvalid();
      return;
    }
    if (result.errNullable.isDefinedAndNotNull) {
      if (onErr != null) onErr(result.err);
      return;
    }
    if (onResult != null) onResult(result.ok);
  }
}

extension ExtIResultToJs<E> on IResult<E> {
  ResultOrErrorJs<T, APPJSUint8Array> toJs<T extends JSAny?>(
      {required T Function(E) ok}) {
    return fold<ResultOrErrorJs<T, APPJSUint8Array>>(
      onOk: (e) => OkJs<T, APPJSUint8Array>(ok(e)),
      onErr: (error) =>
          ErrJs(JsUtils.toAppJsUint8Array(error.exception.toCbor().encode())),
    );
  }
}
