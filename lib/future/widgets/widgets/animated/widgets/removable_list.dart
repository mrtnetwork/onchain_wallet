import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';

class APPAnimatedRemovableList extends StatefulWidget {
  const APPAnimatedRemovableList(
      {required this.itemBuilder,
      required this.length,
      required this.shrinkWrap,
      this.physics,
      super.key});
  final int length;
  final bool shrinkWrap;
  final Widget Function(BuildContext, int index, Animation<double>, [bool? inRemove])
      itemBuilder;
  final ScrollPhysics? physics;
  @override
  State<APPAnimatedRemovableList> createState() => APPRemovableListState();
}

class APPRemovableListState extends State<APPAnimatedRemovableList> {
  final GlobalKey<SliverAnimatedListState> key = GlobalKey();
  void removeIndex(int index) {
    Widget builder(context, animation) {
      return widget.itemBuilder(context, index, animation, true);
    }

    key.currentState?.removeItem(index, builder);
  }

  void addIndex(int index) {
    key.currentState?.insertItem(index);
  }

  @override
  Widget build(BuildContext context) {
    return SliverAnimatedList(
      key: key,
      itemBuilder: widget.itemBuilder,
      initialItemCount: widget.length,
    );
  }
}

typedef ANIMATEDLISTITEMBUILDER<T> = Widget Function(BuildContext context, T item);

class APPAnimatedList<T extends Object> extends StatefulWidget {
  final ANIMATEDLISTITEMBUILDER<T> builder;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  const APPAnimatedList(this.builder, {this.physics, this.shrinkWrap = false, super.key});

  @override
  State<APPAnimatedList<T>> createState() => APPAnimatedListState<T>();
}

class APPAnimatedListState<T extends Object> extends State<APPAnimatedList<T>> {
  final GlobalKey<SliverAnimatedListState> _listKey =
      GlobalKey<SliverAnimatedListState>();

  final List<T> _items = [];

  void _addItem(T item) {
    final index = _items.length;
    _items.add(item);
    _listKey.currentState?.insertItem(index, duration: APPConst.animationDuraion);
  }

  void addItem(T item) {
    _addItem(item);
  }

  void removeItem(T item) {
    _removeItem(_items.indexOf(item));
  }

  void _removeItem(int index) {
    final removedItem = _items[index];

    _items.removeAt(index);

    _listKey.currentState?.removeItem(index, (context, animation) {
      return _AnimatedItemBuilder<T>(
          item: removedItem, animation: animation, builder: widget.builder);
    }, duration: APPConst.animationDuraion);
  }

  // Widget _buildItem(
  //   T item,
  //   Animation<double> animation,
  // ) {
  //   return SizeTransition(
  //     sizeFactor: animation,
  //     child: widget.builder(context, item),
  //   );
  // }

  @override
  void dispose() {
    super.dispose();
    _items.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SliverAnimatedList(
      key: _listKey,
      initialItemCount: _items.length,
      itemBuilder: (
        context,
        index,
        animation,
      ) {
        return _AnimatedItemBuilder<T>(
            item: _items[index], animation: animation, builder: widget.builder);
      },
    );
  }
}

class _AnimatedItemBuilder<T extends Object> extends StatelessWidget {
  final T item;
  final Animation<double> animation;
  final ANIMATEDLISTITEMBUILDER<T> builder;
  const _AnimatedItemBuilder(
      {required this.item, required this.animation, required this.builder});

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: animation,
      child: builder(context, item),
    );
  }
}
