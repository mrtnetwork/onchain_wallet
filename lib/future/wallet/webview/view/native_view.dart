import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:on_chain_bridge/models/device/models/platform.dart';
import 'package:on_chain_wallet/app/core.dart';

class APPAndroidViewController<T> {
  final T controller;
  final int id;
  final String viewType;
  DynamicVoid? onFocus;
  final FocusNode node;
  APPAndroidViewController(
      {required this.controller,
      required this.id,
      required this.node,
      required this.viewType});
  static Future<APPAndroidViewController> create(
      {required String viewType,
      required AppPlatform platform,
      Map<String, String> createParms = const {},
      TextDirection layoutDirection = TextDirection.ltr}) async {
    final id = Random.secure().nextInt(10000) + 50;
    final node = FocusNode(debugLabel: "APPAndroidViewController $id");
    Object controller;

    if (platform.isAndroid) {
      controller = PlatformViewsService.initAndroidView(
        id: id,
        viewType: viewType,
        layoutDirection: layoutDirection,
        creationParams: createParms,
        creationParamsCodec: const StandardMessageCodec(),
        onFocus: () {
          node.requestFocus();
        },
      );
    } else {
      controller = await PlatformViewsService.initAppKitView(
        id: id,
        viewType: viewType,
        layoutDirection: layoutDirection,
        creationParams: createParms,
        creationParamsCodec: const StandardMessageCodec(),
        onFocus: () {
          node.requestFocus();
        },
      );
      await (controller as AppKitViewController).acceptGesture();
    }
    return APPAndroidViewController(
        controller: controller, id: id, node: node, viewType: viewType);
  }

  // Future<void> dispose() async {
  //   if (PlatformInterface.appPlatform == AppPlatform.android) {
  //     await (controller as AndroidViewController).dispose();
  //   } else {
  //     await PlatformInterface.webViewController.dispose(viewType);
  //     await (controller as AppKitViewController).dispose();
  //   }

  //   node.dispose();
  // }
}

class APPNativeView extends StatefulWidget {
  const APPNativeView(
      {super.key,
      required this.controller,
      this.onPlatformViewCreated,
      this.hitTestBehavior = PlatformViewHitTestBehavior.opaque,
      this.gestureRecognizers,
      this.clipBehavior = Clip.hardEdge,
      this.creationParamsCodec,
      required this.platform});
  final PlatformViewCreatedCallback? onPlatformViewCreated;
  final APPAndroidViewController controller;
  final PlatformViewHitTestBehavior hitTestBehavior;
  final MessageCodec<dynamic>? creationParamsCodec;
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;
  final Clip clipBehavior;
  final AppPlatform platform;

  @override
  // ignore: no_logic_in_create_state
  State<APPNativeView> createState() {
    if (platform.isAndroid) {
      return _AndroidViewState();
    }
    return _UiKitViewState();
  }
}

class _AndroidViewState extends State<APPNativeView> {
  late final APPAndroidViewController controller = widget.controller;
  TextDirection _layoutDirection = TextDirection.ltr;
  AndroidViewController get _controller => controller.controller;

  bool _initialized = false;
  FocusNode get _focusNode => controller.node;

  static final Set<Factory<OneSequenceGestureRecognizer>> _emptyRecognizersSet =
      <Factory<OneSequenceGestureRecognizer>>{};

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onFocusChange: _onFocusChange,
      child: _AndroidPlatformView(
        controller: _controller,
        hitTestBehavior: widget.hitTestBehavior,
        gestureRecognizers: widget.gestureRecognizers ?? _emptyRecognizersSet,
        clipBehavior: widget.clipBehavior,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final TextDirection newLayoutDirection = _findLayoutDirection();
    final bool didChangeLayoutDirection = _layoutDirection != newLayoutDirection;
    _layoutDirection = newLayoutDirection;
    if (didChangeLayoutDirection || !_initialized) {
      _initialized = true;
      // The native view will update asynchronously, in the meantime we don't want
      // to block the framework. (so this is intentionally not awaiting).
      _controller.setLayoutDirection(_layoutDirection);
    }
  }

  @override
  void didUpdateWidget(APPNativeView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final TextDirection newLayoutDirection = _findLayoutDirection();
    final bool didChangeLayoutDirection = _layoutDirection != newLayoutDirection;
    _layoutDirection = newLayoutDirection;

    if (didChangeLayoutDirection) {
      _controller.setLayoutDirection(_layoutDirection);
    }
  }

  TextDirection _findLayoutDirection() {
    assert(debugCheckHasDirectionality(context));
    return Directionality.of(context);
  }

  void _onFocusChange(bool isFocused) {
    if (!_controller.isCreated) {
      return;
    }
    if (!isFocused) {
      _controller.clearFocus().catchError((dynamic e) {
        if (e is MissingPluginException) {
          return;
        }
      });
      return;
    }
    SystemChannels.textInput.invokeMethod<void>(
      'TextInput.setPlatformViewClient',
      <String, dynamic>{'platformViewId': controller.id},
    ).catchError((dynamic e) {
      if (e is MissingPluginException) {
        return;
      }
    });
  }
}

class _AndroidPlatformView extends LeafRenderObjectWidget {
  const _AndroidPlatformView({
    required this.controller,
    required this.hitTestBehavior,
    required this.gestureRecognizers,
    this.clipBehavior = Clip.hardEdge,
  });

  final AndroidViewController controller;
  final PlatformViewHitTestBehavior hitTestBehavior;
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;
  final Clip clipBehavior;

  @override
  RenderObject createRenderObject(BuildContext context) => RenderAndroidView(
        viewController: controller,
        hitTestBehavior: hitTestBehavior,
        gestureRecognizers: gestureRecognizers,
        clipBehavior: clipBehavior,
      );

  @override
  void updateRenderObject(BuildContext context, RenderAndroidView renderObject) {
    renderObject.controller = controller;
    renderObject.hitTestBehavior = hitTestBehavior;
    renderObject.updateGestureRecognizers(gestureRecognizers);
    renderObject.clipBehavior = clipBehavior;
  }
}

abstract class _DarwinViewState<
        PlatformViewT extends APPNativeView,
        RenderT extends RenderDarwinPlatformView,
        ViewT extends _DarwinPlatformView<DarwinPlatformViewController, RenderT>>
    extends State<PlatformViewT> {
  AppKitViewController get controller =>
      widget.controller.controller as AppKitViewController;
  TextDirection? _layoutDirection;

  FocusNode get focusNode => widget.controller.node;

  static final Set<Factory<OneSequenceGestureRecognizer>> _emptyRecognizersSet =
      <Factory<OneSequenceGestureRecognizer>>{};

  @override
  Widget build(BuildContext context) {
    return Focus(
        focusNode: focusNode,
        onFocusChange: (bool isFocused) => _onFocusChange(isFocused, controller),
        child: childPlatformView());
  }

  ViewT childPlatformView();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final TextDirection newLayoutDirection = _findLayoutDirection();
    final bool didChangeLayoutDirection = _layoutDirection != newLayoutDirection;
    _layoutDirection = newLayoutDirection;
    if (didChangeLayoutDirection) {
      // The native view will update asynchronously, in the meantime we don't want
      // to block the framework. (so this is intentionally not awaiting).
      controller.setLayoutDirection(_layoutDirection!);
    }
  }

  @override
  void didUpdateWidget(PlatformViewT oldWidget) {
    super.didUpdateWidget(oldWidget);

    final TextDirection newLayoutDirection = _findLayoutDirection();
    final bool didChangeLayoutDirection = _layoutDirection != newLayoutDirection;
    _layoutDirection = newLayoutDirection;

    if (didChangeLayoutDirection) {
      controller.setLayoutDirection(_layoutDirection ?? TextDirection.ltr);
    }
  }

  TextDirection _findLayoutDirection() {
    assert(debugCheckHasDirectionality(context));
    return Directionality.of(context);
  }

  void _onFocusChange(bool isFocused, DarwinPlatformViewController controller) {
    if (!isFocused) {
      return;
    }
    SystemChannels.textInput.invokeMethod<void>(
      'TextInput.setPlatformViewClient',
      <String, dynamic>{'platformViewId': controller.id},
    );
  }
}

class _UiKitViewState
    extends _DarwinViewState<APPNativeView, MyRenderAppKitView, _UiKitPlatformView> {
  @override
  _UiKitPlatformView childPlatformView() {
    return _UiKitPlatformView(
      controller: controller,
      hitTestBehavior: widget.hitTestBehavior,
      gestureRecognizers:
          widget.gestureRecognizers ?? _DarwinViewState._emptyRecognizersSet,
    );
  }
}

abstract class _DarwinPlatformView<TController extends DarwinPlatformViewController,
        TRender extends RenderDarwinPlatformView<TController>>
    extends LeafRenderObjectWidget {
  const _DarwinPlatformView({
    required this.controller,
    required this.hitTestBehavior,
    required this.gestureRecognizers,
  });

  final TController controller;
  final PlatformViewHitTestBehavior hitTestBehavior;
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  @override
  @mustCallSuper
  void updateRenderObject(BuildContext context, TRender renderObject) {
    renderObject
      ..viewController = controller
      ..hitTestBehavior = hitTestBehavior
      ..updateGestureRecognizers(gestureRecognizers);
  }
}

class _UiKitPlatformView
    extends _DarwinPlatformView<AppKitViewController, MyRenderAppKitView> {
  const _UiKitPlatformView(
      {required super.controller,
      required super.hitTestBehavior,
      required super.gestureRecognizers});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return MyRenderAppKitView(
      viewController: controller,
      hitTestBehavior: hitTestBehavior,
      gestureRecognizers: gestureRecognizers,
    );
  }
}

/// A render object for a macOS platform view.
class MyRenderAppKitView extends RenderDarwinPlatformView<AppKitViewController>
    with _PlatformViewGestureMixin {
  /// Creates a render object for a macOS AppKitView.
  MyRenderAppKitView({
    required super.viewController,
    required super.hitTestBehavior,
    required super.gestureRecognizers,
  });

  @override
  void updateGestureRecognizers(
      Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers) {
    _updateGestureRecognizersWithCallBack(gestureRecognizers, (v) async {});
  }
}

typedef _HandlePointerEvent = Future<void> Function(PointerEvent event);

/// The Mixin handling the pointer events and gestures of a platform view render box.
mixin _PlatformViewGestureMixin on RenderBox implements MouseTrackerAnnotation {
  /// How to behave during hit testing.
  // Changing _hitTestBehavior might affect which objects are considered hovered over.
  set hitTestBehavior(PlatformViewHitTestBehavior value) {
    if (value != _hitTestBehavior) {
      _hitTestBehavior = value;
      if (owner != null) {
        markNeedsPaint();
      }
    }
  }

  PlatformViewHitTestBehavior? _hitTestBehavior;

  _HandlePointerEvent? _handlePointerEvent;
  Set<Type> _factoriesTypeSet<T>(Set<Factory<T>> factories) {
    return factories.map<Type>((Factory<T> factory) => factory.type).toSet();
  }

  /// {@macro flutter.rendering.PlatformViewRenderBox.updateGestureRecognizers}
  ///
  /// Any active gesture arena the `PlatformView` participates in is rejected when the
  /// set of gesture recognizers is changed.
  void _updateGestureRecognizersWithCallBack(
    Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers,
    _HandlePointerEvent handlePointerEvent,
  ) {
    assert(
      _factoriesTypeSet(gestureRecognizers).length == gestureRecognizers.length,
      'There were multiple gesture recognizer factories for the same type, there must only be a single '
      'gesture recognizer factory for each gesture recognizer type.',
    );
    // if (_factoryTypesSetEquals(
    //   gestureRecognizers,
    //   _gestureRecognizer?.gestureRecognizerFactories,
    // )) {
    //   return;
    // }
    _gestureRecognizer?.dispose();
    _gestureRecognizer =
        _PlatformViewGestureRecognizer(handlePointerEvent, gestureRecognizers);
    _handlePointerEvent = handlePointerEvent;
  }

  _PlatformViewGestureRecognizer? _gestureRecognizer;
  @override
  bool hitTest(BoxHitTestResult result, {Offset? position}) {
    if (position == null) return false;
    if (_hitTestBehavior == PlatformViewHitTestBehavior.transparent ||
        !size.contains(position)) {
      return false;
    }
    result.add(BoxHitTestEntry(this, position));
    return _hitTestBehavior == PlatformViewHitTestBehavior.opaque;
  }

  @override
  bool hitTestSelf(Offset position) =>
      _hitTestBehavior != PlatformViewHitTestBehavior.transparent;

  @override
  PointerEnterEventListener? onEnter;

  @override
  PointerExitEventListener? onExit;

  @override
  MouseCursor get cursor => MouseCursor.uncontrolled;

  @override
  bool get validForMouseTracker => true;

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    if (event is PointerDownEvent) {
      _gestureRecognizer!.addPointer(event);
    }
    if (event is PointerHoverEvent) {
      _handlePointerEvent?.call(event);
    }
  }

  @override
  void detach() {
    _gestureRecognizer!.reset();
    super.detach();
  }

  @override
  void dispose() {
    _gestureRecognizer?.dispose();
    super.dispose();
  }
}

class _PlatformViewGestureRecognizer extends OneSequenceGestureRecognizer {
  _PlatformViewGestureRecognizer(
    _HandlePointerEvent handlePointerEvent,
    this.gestureRecognizerFactories,
  ) {
    team = GestureArenaTeam()..captain = this;
    _gestureRecognizers = gestureRecognizerFactories
        .map((Factory<OneSequenceGestureRecognizer> recognizerFactory) {
      final OneSequenceGestureRecognizer gestureRecognizer =
          recognizerFactory.constructor();
      gestureRecognizer.team = team;
      // The below gesture recognizers requires at least one non-empty callback to
      // compete in the gesture arena.
      // https://github.com/flutter/flutter/issues/35394#issuecomment-562285087
      if (gestureRecognizer is LongPressGestureRecognizer) {
        gestureRecognizer.onLongPress ??= () {};
      } else if (gestureRecognizer is DragGestureRecognizer) {
        gestureRecognizer.onDown ??= (_) {};
      } else if (gestureRecognizer is TapGestureRecognizer) {
        gestureRecognizer.onTapDown ??= (_) {};
      }
      return gestureRecognizer;
    }).toSet();
    _handlePointerEvent = handlePointerEvent;
  }

  late _HandlePointerEvent _handlePointerEvent;

  // Maps a pointer to a list of its cached pointer events.
  // Before the arena for a pointer is resolved all events are cached here, if we win the arena
  // the cached events are dispatched to `_handlePointerEvent`, if we lose the arena we clear the cache for
  // the pointer.
  final Map<int, List<PointerEvent>> cachedEvents = <int, List<PointerEvent>>{};

  // Pointer for which we have already won the arena, events for pointers in this set are
  // immediately dispatched to `_handlePointerEvent`.
  final Set<int> forwardedPointers = <int>{};

  // We use OneSequenceGestureRecognizers as they support gesture arena teams.
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizerFactories;
  late Set<OneSequenceGestureRecognizer> _gestureRecognizers;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    for (final OneSequenceGestureRecognizer recognizer in _gestureRecognizers) {
      recognizer.addPointer(event);
    }
  }

  @override
  String get debugDescription => 'Platform view';

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  void handleEvent(PointerEvent event) {
    if (!forwardedPointers.contains(event.pointer)) {
      _cacheEvent(event);
    } else {
      _handlePointerEvent(event);
    }
    stopTrackingIfPointerNoLongerDown(event);
  }

  @override
  void acceptGesture(int pointer) {
    _flushPointerCache(pointer);
    forwardedPointers.add(pointer);
  }

  @override
  void rejectGesture(int pointer) {
    stopTrackingPointer(pointer);
    cachedEvents.remove(pointer);
  }

  void _cacheEvent(PointerEvent event) {
    if (!cachedEvents.containsKey(event.pointer)) {
      cachedEvents[event.pointer] = <PointerEvent>[];
    }
    cachedEvents[event.pointer]!.add(event);
  }

  void _flushPointerCache(int pointer) {
    cachedEvents.remove(pointer)?.forEach(_handlePointerEvent);
  }

  @override
  void stopTrackingPointer(int pointer) {
    super.stopTrackingPointer(pointer);
    forwardedPointers.remove(pointer);
  }

  void reset() {
    forwardedPointers.forEach(super.stopTrackingPointer);
    forwardedPointers.clear();
    cachedEvents.keys.forEach(super.stopTrackingPointer);
    cachedEvents.clear();
    resolve(GestureDisposition.rejected);
  }
}
