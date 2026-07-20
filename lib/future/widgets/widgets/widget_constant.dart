import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/theme/theme.dart';

class WidgetConstant {
  const WidgetConstant._();
  static const Widget height8 = SizedBox(height: 8);
  static const Widget height5 = SizedBox(height: 5);
  static const Widget width8 = SizedBox(width: 8);
  static const Widget width20 = SizedBox(width: 20);
  static const Widget height20 = SizedBox(height: 20);
  static const Widget height40 = SizedBox(height: 40);
  static const Widget height15 = SizedBox(height: 15);
  static const ScrollPhysics noScrollPhysics = NeverScrollableScrollPhysics();
  static const EdgeInsets padding5 = EdgeInsets.all(5);
  static const EdgeInsets padding2 = EdgeInsets.all(2);
  static const EdgeInsets padding10 = EdgeInsets.all(10);
  static const BoxConstraints constraintsMinHeight60 = BoxConstraints(minHeight: 60);
  static const BoxConstraints constraintsMinWidth200 = BoxConstraints(minWidth: 200);
  static const EdgeInsets paddingHorizontal10 = EdgeInsets.symmetric(horizontal: 10);
  static const EdgeInsets paddingH10V5 =
      EdgeInsets.symmetric(horizontal: 10, vertical: 5);
  static const EdgeInsets paddingHorizontal20 = EdgeInsets.symmetric(horizontal: 20);
  static const EdgeInsets padding20 = EdgeInsets.all(20);
  static const EdgeInsets paddingOnlyTop20 = EdgeInsets.only(top: 20);
  static const EdgeInsets paddingVertical20 = EdgeInsets.symmetric(vertical: 20);
  static const EdgeInsets paddingVertical40 = EdgeInsets.symmetric(vertical: 40);
  static const EdgeInsets paddingVertical10 = EdgeInsets.symmetric(vertical: 10);
  static const SliverPadding sliverPaddingVertial20 =
      SliverPadding(padding: paddingVertical20);
  static const SliverPadding sliverPaddingVertial10 =
      SliverPadding(padding: paddingVertical10);
  static const SliverPadding sliverPaddingVertial40 =
      SliverPadding(padding: paddingVertical40);
  static const SliverPadding sliverSizedBox = SliverPadding(padding: EdgeInsets.zero);
  static const EdgeInsets paddingVertical8 = EdgeInsets.symmetric(vertical: 8);
  static final BorderRadius border8 = BorderRadius.circular(8);
  static final BorderRadius border25 = BorderRadius.circular(25);
  static final BorderRadius border4 = BorderRadius.circular(4);
  static const BorderRadius borderBottom8 =
      BorderRadius.only(bottomRight: Radius.circular(8), bottomLeft: Radius.circular(8));
  static const SizedBox sizedBox = SizedBox();
  static const BoxShadow circleShadow = BoxShadow(blurRadius: 0.3, spreadRadius: 0.1);
  static const Divider divider = Divider();
  static const Icon checkCircle = Icon(Icons.check_circle, color: Colors.green, size: 40);
  static const Icon check = Icon(Icons.check, color: Colors.green, size: 40);
  static const Icon checkCircleLarge =
      Icon(Icons.check_circle, color: Colors.green, size: 80);
  static final Icon errorIcon =
      Icon(Icons.error, color: ThemeController.appTheme.colorScheme.error, size: 40);
  static final Icon errorIconLarge =
      Icon(Icons.error, color: ThemeController.appTheme.colorScheme.error, size: 80);
  static const Size circularProgressIndicatorSize = Size(24, 24);
  static const Size circularProgressIndicatorSize40 = Size(40, 40);
}
