import 'package:flutter/material.dart';
import 'package:on_chain_wallet/future/future.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:zcash_dart/zcash.dart';

class SaplingDownloadParametersView extends StatefulWidget {
  final ZcashSaplingParameter type;
  final double lengthInMb;
  final List<String> downloadLinks;
  const SaplingDownloadParametersView(
      {required this.type,
      required this.lengthInMb,
      required this.downloadLinks,
      super.key});

  @override
  State<SaplingDownloadParametersView> createState() =>
      _SaplingDownloadParametersViewState();
}

class _SaplingDownloadParametersViewState extends State<SaplingDownloadParametersView> {
  Future<void> onSelectFile() async {
    final result = await context.appContext.platformUtls.pickPlatformFile();
    result.map((e) {
      if (e == null) return;
      context.pop(SaplingPickParamsFile(e));
    }).mapErr((e) {
      context.showAlert(e.localizationError);
      return e.exception;
    });
  }

  void onDownload() {
    context.pop(SaplingPickParamsDownload());
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: WidgetConstant.padding20,
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("download_sapling_parameters_desc"
                .tr
                .replaceOne(switch (widget.type) {
                  ZcashSaplingParameter.spend => "spend".tr,
                  ZcashSaplingParameter.output => "output".tr,
                })
                .replaceTwo(widget.lengthInMb.toStringAsFixed(2))),
            WidgetConstant.height20,
            Text("links".tr, style: context.textTheme.titleMedium),
            WidgetConstant.height8,
            ...List.generate(
              widget.downloadLinks.length,
              (index) {
                final link = widget.downloadLinks[index];
                return ContainerWithBorder(
                  onRemove: () {},
                  enableTap: false,
                  onRemoveWidget: IconButton(
                      onPressed: () {
                        context.appContext.platformUtls.lunchUri(link);
                      },
                      icon: Icon(
                        Icons.open_in_new,
                        color: context.onPrimaryContainer,
                      )),
                  child: CopyableTextWidget(
                    text: link,
                    color: context.onPrimaryContainer,
                  ),
                );
              },
            ),
            WidgetConstant.height20,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                    onPressed: onSelectFile,
                    icon: Icon(Icons.file_copy),
                    label: Text("pick_file".tr)),
                WidgetConstant.width8,
                ElevatedButton.icon(
                    onPressed: onDownload,
                    icon: Icon(Icons.download),
                    label: Text("download".tr)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
