part of 'package:on_chain_wallet/future/state_managment/state_managment.dart';

typedef CbStreamBuilder<T> = Widget Function(BuildContext context, T value);

class APPStreamBuilder<T> extends StatelessWidget {
  final StreamValue<T> value;
  final CbStreamBuilder<T> builder;
  const APPStreamBuilder({required this.value, required this.builder, super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
        stream: value.stream,
        initialData: value.value,
        builder: (context, snapshot) {
          return builder(context, snapshot.data as T);
        });
  }
}

typedef CbStreamNotify<T> = bool Function(T value);

class APPStreamWidget<T> extends StatefulWidget {
  final StreamValue<T> stream;
  final CbStreamBuilder<T> builder;
  final CbStreamNotify<T>? allowNotify;
  const APPStreamWidget(
      {required this.builder, required this.stream, this.allowNotify, super.key});

  @override
  State<APPStreamWidget> createState() => _ChainStreamBuilderState<T>();
}

class _ChainStreamBuilderState<T> extends State<APPStreamWidget<T>>
    with SafeState<APPStreamWidget<T>> {
  late StreamValue<T> stream = widget.stream;
  StreamSubscription<T>? _subscription;
  void onChainNotify(T value) {
    final allowNotify = widget.allowNotify;
    if (allowNotify == null || allowNotify(value)) {
      updateState();
    }
  }

  void diposeStream() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    _subscription = stream.stream.listen(onChainNotify);
  }

  @override
  void safeDispose() {
    super.safeDispose();
    diposeStream();
  }

  @override
  void didUpdateWidget(covariant APPStreamWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (stream != widget.stream) {
      stream = widget.stream;
      diposeStream();
      _subscription = stream.stream.listen(onChainNotify);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, stream.value);
  }
}
