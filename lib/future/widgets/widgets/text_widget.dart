import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';

class OneLineTextWidget extends StatelessWidget {
  const OneLineTextWidget(this.text,
      {this.style, super.key, this.maxLine = 1, this.align});

  final String text;
  final TextStyle? style;
  final int maxLine;
  final TextAlign? align;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLine,
      overflow: TextOverflow.ellipsis,
      style: style,
      textAlign: align,
    );
  }
}

class ObscureTextView extends StatefulWidget {
  const ObscureTextView(this.text, {this.style, super.key, this.maxLine = 1});
  final String text;
  final TextStyle? style;
  final int maxLine;

  @override
  State<ObscureTextView> createState() => _ObscureTextViewState();
}

class _ObscureTextViewState extends State<ObscureTextView> {
  late final String abstructText = List.generate(widget.text.length, (index) {
    return "*";
  }).join();
  bool _show = false;
  void show() {
    _show = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: APPConst.animationDuraion,
      child: _show
          ? Text(
              widget.text,
              maxLines: widget.maxLine,
              overflow: TextOverflow.ellipsis,
              style: widget.style,
            )
          : Row(
              children: [
                Flexible(
                    child: Text(
                  abstructText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: widget.style,
                )),
                IconButton(onPressed: show, icon: const Icon(Icons.remove_red_eye))
              ],
            ),
    );
  }
}
