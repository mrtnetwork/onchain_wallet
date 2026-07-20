import 'package:blockchain_utils/cbor/cbor.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:on_chain_bridge/serialization/serialization.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/response.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/connector/types/types.dart';
import 'package:on_chain_wallet/crypto/wallet/keys/crypto_keys.dart';
import 'package:on_chain_wallet/crypto/basic_crypto/requets/messages/core/message.dart';
import 'package:on_chain_wallet/app/core.dart';

enum CryptoArgsType {
  crypto,
  wallet;

  const CryptoArgsType();
}

sealed class CryptoMessageArgs extends RequestableMessage {
  CryptoMessageArgs({required super.cancelable});
  abstract final AppCryptoMethods method;

  @override
  bool get isEncrypted => true;
  static T deserialize<T extends CryptoMessageArgs>(List<int> bytes) {
    final CborTagValue cbor = AppSerialization.decode(cborBytes: bytes);
    final type = AppCryptoMethods.fromTag(cbor.tags);
    CryptoMessageArgs args;
    switch (type) {
      case CryptoRequestMethod method:
        args = CryptoRequest.deserialize(method, cbor);
        break;
      case WalletRequestMethod _:
        args = WalletArgs.deserialize(object: cbor);
        break;
    }
    if (args is! T) {
      throw AppInternalError.internalError("CryptoMessageArgs");
    }
    return args;
  }
}

abstract class CryptoStreamMessageArgs extends RequestableMessage {
  CryptoStreamMessageArgs({required super.cancelable});
  abstract final StreamIsolateMethod method;
  @override
  bool get isEncrypted => false;
  static T deserialize<T extends CryptoStreamMessageArgs>(List<int> bytes) {
    final decode = AppSerialization.decodeTaggedValueWithInfo(
        cborBytes: bytes,
        expectedTags: StreamIsolateMethod.values.map((e) => e.tag).toList());
    final type = StreamIsolateMethod.fromIdentifier(decode.identifier.id);
    CryptoStreamMessageArgs args;
    switch (type) {
      case StreamIsolateMethod.streamArgs:
        args = MessageArgsStream.deserialize(object: decode.tag);
        break;
      default:
        args = IsolateStreamRequest.deserialize(object: decode.tag);
        break;
    }
    if (args is! T) {
      throw AppInternalError.internalError("CryptoStreamMessageArgs");
    }
    return args;
  }
}

abstract class StreamArgsRequestable extends CryptoStreamMessageArgs {
  StreamArgsRequestable({super.cancelable});
}

class MessageArgsStream extends StreamArgsRequestable {
  final List<int>? data;
  final String streamId;
  final MessageArgsStreamMethod type;
  MessageArgsStream._({List<int>? data, required this.streamId, required this.type})
      : data = data?.asImmutableBytes;
  factory MessageArgsStream.deserialize({List<int>? bytes, CborTagValue? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes,
        cborObject: object,
        identifier: StreamIsolateMethod.streamArgs.tag);
    return MessageArgsStream._(
        data: values.rawValueAt(0),
        streamId: values.rawValueAt(1),
        type: MessageArgsStreamMethod.fromValue(values.rawValueAt(2)));
  }
  factory MessageArgsStream.message({required List<int> data, required String streamId}) {
    return MessageArgsStream._(
        data: data, type: MessageArgsStreamMethod.message, streamId: streamId);
  }
  factory MessageArgsStream.close(String streamId) {
    return MessageArgsStream._(type: MessageArgsStreamMethod.close, streamId: streamId);
  }

  @override
  SerializationIdentifier get serializationIdentifier => method.tag;

  @override
  List<CborObject?> get serializationItems =>
      [data?.toCborBytes(), streamId.toCbor(), type.value.toCbor()];

  @override
  StreamIsolateMethod get method => StreamIsolateMethod.streamArgs;
}

abstract class StreamArgsCompleter<T, S> extends StreamArgsRequestable {
  StreamArgsCompleter({required super.cancelable});
  Stream<({MessageArgsStreamResponse message, bool encrypted})> getIsolateResult(
      String streamId, AppContext context);
  T parsResult(MessageArgsStreamResponse result);
  MessageArgsStream toRequest({required S message, required String streamId});
  void add(MessageArgsStream args, List<int>? encryptedPart);
}

abstract class CryptoArgsCompleter<T extends CborTagSerializable>
    extends CryptoMessageArgs {
  CryptoArgsCompleter({super.cancelable});
  T parsResult(MessageArgsComplete result);
  Future<T> result(AppContext context, {List<int>? encryptedPart});
}

abstract class WalletArgsCompleter<T extends CborTagSerializable> with AppSerialization {
  const WalletArgsCompleter() : super();
  WalletRequestMethod get method;
  Future<T> parsResult(MessageArgsComplete result);
  Future<T> result(MemoryWalletContext wallet, AppContext context);
  CryptoProcessLevel get level => CryptoProcessLevel.normal;
  Duration get processTimeout => Duration(seconds: 60);
}

class WalletArgs<T extends CborTagSerializable, R extends WalletArgsCompleter<T>>
    extends CryptoMessageArgs {
  final R args;
  final TransfableMemoryWallet memoryWallet;
  @override
  CryptoProcessLevel get level => args.level;
  @override
  Duration get processTimeout => args.processTimeout;
  WalletArgs({
    required this.args,
    required this.memoryWallet,
    super.cancelable,
  });

  factory WalletArgs.deserialize({List<int>? bytes, CborTagValue? object}) {
    final CborListValue values = AppSerialization.decodeTaggedValue(
        cborBytes: bytes, cborObject: object, identifier: null);
    final WalletArgsCompleter args =
        WalletRequest.deserialize(object: values.objectAt<CborTagValue>(0));
    if (args is! R) {
      throw AppInternalError.internalError("WalletArgs");
    }
    return WalletArgs(
      args: args,
      memoryWallet:
          TransfableMemoryWallet.deserialize(object: values.objectAt<CborTagValue>(1)),
    );
  }

  Future<T> parseResult(MessageArgsComplete result) {
    return args.parsResult(result);
  }

  Future<T> result(AppContext context) async {
    final masterKey = MemoryWalletContext.fromTransfableMemeoryWallet(memoryWallet);
    try {
      final result = await args.result(masterKey, context);
      return result;
    } finally {
      masterKey.close();
    }
  }

  @override
  SerializationIdentifier get serializationIdentifier => args.serializationIdentifier;

  @override
  List<CborObject?> get serializationItems => [args.toCbor(), memoryWallet.toCbor()];

  @override
  AppCryptoMethods get method => args.method;
}
