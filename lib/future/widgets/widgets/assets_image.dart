import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/image/memory_image.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/wallet/models/token/token/token.dart' show APPToken;

class CircleAssetsImageView extends StatelessWidget {
  const CircleAssetsImageView(this.assetPath,
      {this.radius = 120,
      this.backgroundColor = Colors.transparent,
      this.foregroundColor,
      super.key});
  final APPImage assetPath;
  final double radius;
  final Color backgroundColor;
  final Color? foregroundColor;
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundImage:
          CacheMemoryImageProvider(image: assetPath, netApi: context.appContext.netApi),
      radius: radius,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      onBackgroundImageError: (e, d) {},
    );
  }
}

class CircleAPPImageView extends StatelessWidget {
  const CircleAPPImageView(this.image,
      {this.onProgress,
      this.onError,
      this.radius = 120,
      super.key,
      this.onNull = "U",
      this.backgroundColor,
      this.reverseColor
      // this.imageColor,
      });
  final APPImageInfo? image;
  final double radius;
  final String? onNull;
  final FuncWidgetContext? onProgress;
  final FuncWidgetContext? onError;
  final Color? backgroundColor;
  final Color? reverseColor;

  @override
  Widget build(BuildContext context) {
    final name = onNull ?? "U";
    return ConditionalWidget(
      enable: image != null,
      onActive: (context) {
        return ClipOval(
          child: Image(
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress != null && onProgress != null) {
                  return onProgress!.call(context);
                }
                if (loadingProgress == null) {
                  return _CircleAPPImageView(
                    radius: radius,
                    onNull: name,
                    backgroundColor: backgroundColor,
                    reverseColor: reverseColor,
                    child: child,
                  );
                }
                return _CircleAPPImageView(
                  radius: radius,
                  onNull: name,
                  child: null,
                  backgroundColor: backgroundColor,
                  reverseColor: reverseColor,
                );
              },
              image: CacheMemoryImageProvider(
                  image: image!, netApi: context.appContext.netApi),
              errorBuilder: (context, error, stackTrace) {
                return _CircleAPPImageView(
                  radius: radius,
                  onNull: name,
                  backgroundColor: backgroundColor,
                  reverseColor: reverseColor,
                  child: onError?.call(context),
                );
              }),
        );
      },
      onDeactive: (context) => _CircleAPPImageView(
          radius: radius,
          onNull: name,
          backgroundColor: backgroundColor,
          reverseColor: reverseColor,
          child: onError?.call(context)),
    );
  }
}

class _CircleAPPImageView extends StatelessWidget {
  const _CircleAPPImageView(
      {this.child,
      required this.radius,
      this.reverseColor,
      this.backgroundColor,
      required this.onNull});
  final double radius;
  final String onNull;
  final Widget? child;
  final Color? backgroundColor;
  final Color? reverseColor;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    return ClipOval(
      child: Container(
        decoration: BoxDecoration(
            color: child != null
                ? context.colors.transparent
                : (backgroundColor ?? context.colors.primaryContainer),
            shape: BoxShape.circle),
        width: size,
        height: size,
        child: Center(
          child: ConditionalWidget(
            enable: child != null,
            onActive: (context) => child!,
            onDeactive: (context) => Text(
              onNull,
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: radius,
                  color: reverseColor ?? context.colors.onPrimaryContainer),
            ),
          ),
        ),
      ),
    );
  }
}

class CircleTokenImageView extends StatelessWidget {
  const CircleTokenImageView(this.token,
      {this.backgroundColor, this.reverseColor, this.radius = 120, super.key});
  final APPToken token;
  final double radius;
  final Color? backgroundColor;
  final Color? reverseColor;

  @override
  Widget build(BuildContext context) {
    String symbol = (token.symbol.nullOnEmpty?[0] ?? 'U').toUpperCase();
    return CircleAPPImageView(
      token.assetLogo,
      onNull: symbol,
      radius: radius,
      backgroundColor: backgroundColor,
      reverseColor: reverseColor,
    );
  }
}

enum APPImageLoaderStatus { loading, failed, nullImage }

class APPImageView extends StatelessWidget {
  const APPImageView(this.image,
      {this.radius = 120,
      super.key,
      this.onNull = "U",
      this.imageColor,
      this.onLoading = const {}});
  final APPImageInfo? image;
  final double radius;
  final String? onNull;
  final Map<APPImageLoaderStatus, WidgetContext> onLoading;
  final Color? imageColor;

  @override
  Widget build(BuildContext context) {
    final name = onNull ?? "U";
    return ConditionalWidget(
      enable: image != null,
      onActive: (context) => ClipOval(
        child: Image(
            color: imageColor,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              return ConditionalWidget(
                enable: loadingProgress == null,
                onDeactive: (context) => _CircleAPPImageView(
                    radius: radius,
                    onNull: name,
                    child: onLoading[APPImageLoaderStatus.loading]?.call(context)),
                onActive: (context) =>
                    _CircleAPPImageView(radius: radius, onNull: name, child: child),
              );
            },
            image: CacheMemoryImageProvider(
                image: image!, netApi: context.appContext.netApi),
            errorBuilder: (context, error, stackTrace) {
              return _CircleAPPImageView(
                  radius: radius,
                  onNull: name,
                  child: onLoading[APPImageLoaderStatus.failed]?.call(context));
            }),
      ),
      onDeactive: (context) => _CircleAPPImageView(
          radius: radius,
          onNull: name,
          child: onLoading[APPImageLoaderStatus.nullImage]?.call(context)),
    );
  }
}
