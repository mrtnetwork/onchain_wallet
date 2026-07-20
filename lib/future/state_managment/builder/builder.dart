part of 'package:on_chain_wallet/future/state_managment/state_managment.dart';

typedef CbStateBuilder<T extends StateController> = Widget Function(T controller);
typedef CbControllerBuilder<T extends StateController> = T Function();

enum StateBuilderDisposeStrategy { never, onDispose }

class StateBuilder<T extends StateController> extends StatefulWidget {
  final CbStateBuilder<T> builder;
  final CbControllerBuilder<T> controller;
  final String repositoryId;

  final StateBuilderDisposeStrategy disposeStrategy;
  const StateBuilder({
    super.key,
    required this.controller,
    required this.builder,
    required this.repositoryId,
    required this.disposeStrategy,
  });

  @override
  StateBuilderState<T> createState() => StateBuilderState<T>();
}

class StateBuilderState<T extends StateController> extends State<StateBuilder<T>>
    with SafeState {
  late final T stateController = widget.controller();
  void update() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    stateController._start();
    stateController._addListener(update);
  }

  @override
  void dispose() {
    super.dispose();
    stateController._removeListener(update);
    switch (widget.disposeStrategy) {
      case StateBuilderDisposeStrategy.never:
        break;
      case StateBuilderDisposeStrategy.onDispose:
        r._remove(widget.repositoryId);
        break;
    }
  }

  late RepositoryController r;

  @override
  void didChangeDependencies() {
    r = StateRepository.of(context);
    r._add(context, widget.repositoryId, stateController);
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(StateBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(stateController);
  }
}
