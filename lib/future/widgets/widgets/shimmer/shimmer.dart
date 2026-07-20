import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/widgets/widgets/animated/animation.dart';
import 'package:on_chain_wallet/future/widgets/widgets/container_with_border.dart';
import 'package:on_chain_wallet/future/widgets/widgets/widget_constant.dart';

typedef SHIMMERBUILDER = Widget Function(bool enable, BuildContext context);

class ShimmerActionView extends StatelessWidget {
  final bool sliver;
  final SHIMMERBUILDER onActive;
  final ShimmerAction action;
  final bool ignoring;
  const ShimmerActionView({
    required this.action,
    required this.onActive,
    this.ignoring = true,
    this.sliver = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      onActive: onActive,
      enable: !action.action,
      sliver: sliver,
      ignoring: ignoring,
    );
  }
}

class Shimmer extends StatelessWidget {
  final bool sliver;
  final bool enable;
  final bool ignoring;
  final SHIMMERBUILDER onActive;
  const Shimmer(
      {required this.onActive,
      this.sliver = false,
      required this.enable,
      this.ignoring = true,
      super.key});
  @override
  Widget build(BuildContext context) {
    if (sliver) {
      return APPSliverAnimatedSwitcher<bool>(enable: enable, widgets: {
        false: (context) => SliverIgnorePointer(
            ignoring: ignoring,
            sliver: SliverToBoxAdapter(
                child: ShimmerWidget(child: onActive(enable, context)))),
        true: (context) => onActive(enable, context)
      });
    }
    return APPAnimated(
        isActive: enable,
        onDeactive: (context) => IgnorePointer(
            ignoring: ignoring, child: ShimmerWidget(child: onActive(enable, context))),
        onActive: (context) => onActive(enable, context));
  }
}

// typedef ONFUTUREWAITING = Widget Function(BuildContext context);
typedef ONFUTUREDATA<T> = Widget Function(
    BuildContext context, AsyncSnapshot<T> snapshot);

class FutureShimmerBuilder<T extends Object> extends StatelessWidget {
  final ONFUTUREDATA<T> onData;
  final Future<T> future;
  final bool sliver;
  final bool ignoring;
  const FutureShimmerBuilder(
      {this.sliver = false,
      this.ignoring = true,
      required this.onData,
      required this.future,
      super.key});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        return Shimmer(
            onActive: (enable, context) => onData(context, snapshot),
            enable: snapshot.connectionState != ConnectionState.waiting);
      },
    );
  }
}

class ShimmerWidget extends StatefulWidget {
  final Widget child;
  final double opacity;
  final Duration duration;

  const ShimmerWidget({
    super.key,
    this.child = const ShimmerBox(),
    this.opacity = 1,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment(-1.5 + (_controller.value * 2), 0),
                end: Alignment(-0.5 + (_controller.value * 2), 0),
                colors: [
                  context.colors.transparent,
                  context.colors.onPrimaryContainer.wOpacity(0.30),
                  context.colors.onPrimaryContainer.wOpacity(0.50),
                  context.colors.onPrimaryContainer.wOpacity(0.70),
                  context.colors.transparent,
                ],
                stops: const [0.0, 0.1, 0.5, 0.8, 1.0],
                tileMode: TileMode.decal),
          ),
          child: Opacity(opacity: 0.8, child: child),
        );
      },
    );
  }
}
// class ShimmerWidget extends StatefulWidget {
//   final Widget child;
//   final Duration duration;
//   final bool enabled;

//   const ShimmerWidget({
//     super.key,
//     this.child = const ShimmerBox(),
//     this.duration = const Duration(milliseconds: 1200),
//     this.enabled = true,
//   });

//   @override
//   State<ShimmerWidget> createState() => _ShimmerWidgetState();
// }

// class _ShimmerWidgetState extends State<ShimmerWidget>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _controller;

//   @override
//   void initState() {
//     super.initState();

//     _controller = AnimationController(
//       vsync: this,
//       duration: widget.duration,
//     )..repeat();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!widget.enabled) return widget.child;

//     return IgnorePointer(
//       ignoring: true,
//       child: AnimatedBuilder(
//         animation: _controller,
//         child: widget.child,
//         builder: (context, child) {
//           return ShaderMask(
//             blendMode: BlendMode.srcIn,
//             shaderCallback: (bounds) {
//               final width = bounds.width;

//               return LinearGradient(
//                 begin: Alignment.centerLeft,
//                 end: Alignment.centerRight,
//                 colors: [
//                   Colors.grey.shade300,
//                   Colors.grey.shade100,
//                   Colors.grey.shade300,
//                 ],
//                 stops: const [0.1, 0.3, 0.4],
//                 transform: _SlidingGradientTransform(
//                   slidePercent: _controller.value,
//                 ),
//               ).createShader(
//                 Rect.fromLTWH(0, 0, width, bounds.height),
//               );
//             },
//             child: child,
//           );
//         },
//       ),
//     );
//   }
// }

// class _SlidingGradientTransform extends GradientTransform {
//   final double slidePercent;

//   const _SlidingGradientTransform({
//     required this.slidePercent,
//   });

//   @override
//   Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
//     return Matrix4.translationValues(
//       bounds.width * (slidePercent * 2 - 1),
//       0,
//       0,
//     );
//   }
// }

// class ShimmerWidget extends StatefulWidget {
//   final Widget child;

//   const ShimmerWidget({super.key, this.child = const ShimmerBox()});

//   @override
//   State<ShimmerWidget> createState() => _ShimmerWidgetState();
// }

// class _ShimmerWidgetState extends State<ShimmerWidget>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _controller;

//   @override
//   void initState() {
//     super.initState();

//     _controller = AnimationController(
//       vsync: this,
//       duration: APPConst.oneSecoundDuration,
//     )..repeat();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         widget.child,
//         Positioned.fill(
//           child: AnimatedBuilder(
//             animation: _controller,
//             builder: (context, _) {
//               return FractionallySizedBox(
//                 widthFactor: 1.4,
//                 alignment: Alignment(-1 + _controller.value * 2, 0),
//                 child: Container(
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [
//                         Colors.transparent,
//                         context.colors.onSurface.wOpacity(0.3),
//                         context.colors.onSurface.wOpacity(0.5),
//                         context.colors.onSurface.wOpacity(0.7),
//                         Colors.transparent,
//                       ],
//                       stops: const [0.0, 0.3, 0.5, 0.7, 0.9],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }

// class _SlidingGradientTransform extends GradientTransform {
//   final double slidePercent;

//   const _SlidingGradientTransform(this.slidePercent);

//   @override
//   Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
//     return Matrix4.translationValues(
//       bounds.width * (slidePercent * 2 - 1),
//       0,
//       0,
//     );
//   }
// }
// class ShimmerWidget extends StatefulWidget {
//   final Widget child;

//   const ShimmerWidget({super.key, this.child = const ShimmerBox()});

//   @override
//   State<ShimmerWidget> createState() => _ShimmerWidgetState();
// }

// class _ShimmerWidgetState extends State<ShimmerWidget>
//     with SafeState<ShimmerWidget>, SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _animation;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 2),
//     )..repeat();
//     _animation = Tween<double>(begin: -1.0, end: 2.0).animate(_controller);
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _controller,
//       builder: (context, child) {
//         return ShaderMask(
//             shaderCallback: (bounds) {
//               return LinearGradient(
//                 colors: [
//                   context.colors.inverseSurface.wOpacity(0.1),
//                   context.colors.inverseSurface.wOpacity(0.3),
//                   context.colors.inverseSurface.wOpacity(1),
//                 ],
//                 stops: [0.1, 0.2, 1],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 transform: _GradientTransform(_animation.value),
//               ).createShader(bounds);
//             },
//             blendMode: BlendMode.srcIn,
//             child: child);
//       },
//       child: widget.child,
//     );
//   }
// }

// class _GradientTransform extends GradientTransform {
//   final double slideValue;
//   const _GradientTransform(this.slideValue);

//   @override
//   Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
//     return Matrix4.translationValues(bounds.width * slideValue, 0.0, 0.0);
//   }
// }

class ShimmerBox extends StatelessWidget {
  final BoxConstraints? constraints;
  const ShimmerBox({super.key, this.constraints = WidgetConstant.constraintsMinHeight60});

  @override
  Widget build(BuildContext context) {
    return ContainerWithBorder(
      constraints: constraints,
      child: Row(children: []),
    );
  }
}

class ShimmerAction<T> {
  final T object;
  bool _action = false;
  bool get action => _action;
  ShimmerAction({required this.object});
  void toggleAction() {
    _action = !action;
  }

  void setAction(bool action) {
    _action = action;
  }
}
