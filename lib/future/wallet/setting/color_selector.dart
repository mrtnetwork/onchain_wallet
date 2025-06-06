import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/widgets/widgets/widget_constant.dart';
import 'package:on_chain_wallet/future/state_managment/extension/extension.dart';

typedef OnSelectColor = void Function(Color?);

class ColorSelectorIconView extends StatelessWidget {
  const ColorSelectorIconView(this.onSelectColor, {super.key});
  final OnSelectColor onSelectColor;

  @override
  Widget build(BuildContext context) {
    return IconButton(
        onPressed: () {
          context
              .openSliverDialog<Color>((ctx) => const ColorSelectorModal(),
                  "primary_color_palette".tr)
              .then(onSelectColor);
        },
        icon: const Icon(Icons.color_lens));
  }
}

class BrightnessToggleIcon extends StatelessWidget {
  const BrightnessToggleIcon(
      {required this.onToggleBrightness, required this.brightness, super.key});
  final DynamicVoid onToggleBrightness;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return IconButton(
        onPressed: onToggleBrightness,
        icon: brightness == Brightness.dark
            ? const Icon(Icons.light_mode)
            : const Icon(Icons.dark_mode));
  }
}

class ColorSelectorModal extends StatelessWidget {
  const ColorSelectorModal({super.key});
  static const List<Color> defaultColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
    Colors.black,
  ];
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("select_color_from_blow".tr),
        WidgetConstant.height20,
        Wrap(
          children: List.generate(defaultColors.length, (index) {
            return InkWell(
              onTap: () {
                context.pop(defaultColors[index]);
              },
              child: Padding(
                padding: WidgetConstant.padding10,
                child: Icon(
                  Icons.color_lens,
                  color: defaultColors[index],
                  size: APPConst.double40,
                ),
              ),
            );
          }),
        )
      ],
    );
  }
}
