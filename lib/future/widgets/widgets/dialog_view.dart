import 'package:flutter/material.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';

class DialogView extends StatelessWidget {
  const DialogView(
      {this.widget,
      this.sliver,
      this.maxWidth,
      this.title,
      this.titleWidget,
      this.content = const [],
      this.child,
      this.dismissible = true,
      super.key});
  final Widget? widget;
  final Widget? sliver;
  final Widget? child;
  final String? title;
  final Widget? titleWidget;
  final List<Widget> content;
  final double? maxWidth;
  final bool dismissible;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: dismissible
                ? () {
                    context.pop();
                  }
                : null,
            child: Container(
              color: context.colors.transparent,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          Center(
            child: ConstraintsBoxView(
              alignment: Alignment.center,
              maxWidth: maxWidth ?? APPConst.dialogWidth,
              padding: WidgetConstant.padding20,
              child: ClipRRect(
                borderRadius: WidgetConstant.border25,
                child: Material(
                  color: context.colors.surface,
                  child: child ??
                      CustomScrollView(
                        shrinkWrap: true,
                        slivers: [
                          SliverAppBar(
                            title: titleWidget ?? Text(title ?? ""),
                            leading: WidgetConstant.sizedBox,
                            leadingWidth: 0,
                            pinned: true,
                            actions: [...content, const CloseButton()],
                          ),
                          ConditionalWidget(
                            enable: widget != null,
                            onDeactive: (context) {
                              return sliver ?? WidgetConstant.sliverSizedBox;
                            },
                            onActive: (context) => SliverToBoxAdapter(
                              child: ConstraintsBoxView(
                                  padding: WidgetConstant.padding20,
                                  child: widget ?? WidgetConstant.sizedBox),
                            ),
                          ),
                        ],
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DialogDoubleButtonView extends StatelessWidget {
  const DialogDoubleButtonView({
    super.key,
    this.firstButtonLabel,
    this.secoundButtonLabel,
    this.firstButtonPressed,
    this.secountButtonPressed,
  });
  final String? firstButtonLabel;
  final String? secoundButtonLabel;
  final DynamicVoid? firstButtonPressed;
  final DynamicVoid? secountButtonPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: WidgetConstant.paddingOnlyTop20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
              onPressed: () {
                if (firstButtonPressed != null) {
                  firstButtonPressed?.call();
                } else {
                  context.pop(true);
                }
              },
              child: Text(firstButtonLabel ?? "yes".tr)),
          WidgetConstant.width8,
          TextButton(
              onPressed: () {
                if (secountButtonPressed != null) {
                  secountButtonPressed?.call();
                } else {
                  context.pop(false);
                }
              },
              child: Text(secoundButtonLabel ?? "no".tr)),
        ],
      ),
    );
  }
}

class DialogSingleButtonView extends StatelessWidget {
  const DialogSingleButtonView({
    super.key,
    this.buttonLabel,
    this.onTap,
  });
  final String? buttonLabel;
  final DynamicVoid? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: WidgetConstant.paddingOnlyTop20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
              onPressed: () {
                if (onTap != null) {
                  onTap?.call();
                } else {
                  context.pop(true);
                }
              },
              child: Text(buttonLabel ?? "yes".tr)),
        ],
      ),
    );
  }
}

class DialogTextView extends StatelessWidget {
  const DialogTextView({super.key, this.text, this.widget, this.buttonWidget});
  final String? text;
  final Widget? widget;
  final Widget? buttonWidget;
  @override
  Widget build(BuildContext context) {
    final Widget subtitle = widget ?? Text(text ?? "");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [subtitle, buttonWidget ?? WidgetConstant.sizedBox],
    );
  }
}

class DialogTitleAndMultiTextView extends StatelessWidget {
  const DialogTitleAndMultiTextView(
      {super.key, required this.title, required this.content, this.buttonWidget});
  final String title;
  final List<String> content;
  final Widget? buttonWidget;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageTitleSubtitle(
            title: title,
            titleStyle: context.textTheme.titleMedium,
            body: RichText(
              text: TextSpan(
                  style: context.textTheme.bodyMedium,
                  children: content
                      .map(
                          (e) => TextSpan(text: "- $e", children: [TextSpan(text: "\n")]))
                      .toList()),
            )),
        ConditionalWidgetWithValue(
          value: buttonWidget,
          onValue: (context, value) => value,
        )
      ],
    );
  }
}

class AsyncDialogDoubleButtonView extends StatefulWidget {
  const AsyncDialogDoubleButtonView({
    super.key,
    this.firstButtonLabel,
    this.secoundButtonLabel,
    this.firstButtonPressed,
    this.secountButtonPressed,
  });
  final String? firstButtonLabel;
  final String? secoundButtonLabel;
  final FutureT? firstButtonPressed;
  final FutureT? secountButtonPressed;

  @override
  State<AsyncDialogDoubleButtonView> createState() => _AsyncDialogDoubleButtonViewState();
}

class _AsyncDialogDoubleButtonViewState extends State<AsyncDialogDoubleButtonView>
    with SafeState<AsyncDialogDoubleButtonView> {
  final GlobalKey<StreamWidgetState> progressKeyFirst =
      GlobalKey(debugLabel: "_AsyncDialogDoubleButtonViewState_1");
  final GlobalKey<StreamWidgetState> progressKeySecound =
      GlobalKey(debugLabel: "_AsyncDialogDoubleButtonViewState_2");
  // String? _error;
  void onTap(bool first) async {
    if (first && widget.firstButtonPressed == null) {
      context.pop(true);
      return;
    } else if (!first && widget.secountButtonPressed == null) {
      context.pop(false);
      return;
    }
    // if (_error != null) {
    //   setState(() {
    //     _error = null;
    //   });
    // }
    final pKey = first ? progressKeyFirst : progressKeySecound;
    if (pKey.inProgress) return;
    pKey.process();
    final result = await IResult.call(() async {
      if (first) {
        return await widget.firstButtonPressed!();
      }
      return await widget.secountButtonPressed!();
    });
    result.watch(
      onErr: (error) {
        pKey.error();
        context.showAlert(error.localizationError);
      },
      onOk: (value) {
        pKey.success();
        context.pop(value);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: WidgetConstant.paddingOnlyTop20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ButtonProgress(
              child: (context) => FilledButton(
                  onPressed: () {
                    onTap(true);
                  },
                  child: Text(widget.firstButtonLabel ?? "yes".tr)),
              key: progressKeyFirst),
          WidgetConstant.width8,
          ButtonProgress(
              child: (context) => FilledButton(
                  style: ButtonStyle(
                      backgroundColor:
                          WidgetStatePropertyAll(context.colors.tertiaryContainer),
                      foregroundColor:
                          WidgetStatePropertyAll(context.colors.onTertiaryContainer)),
                  onPressed: () {
                    onTap(false);
                  },
                  child: Text(widget.secoundButtonLabel ?? "no".tr)),
              key: progressKeySecound),
        ],
      ),
    );
  }
}
