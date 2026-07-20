import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:flutter/material.dart';
import 'package:on_chain_bridge/models/files/picked_file_data.dart';
import 'package:on_chain_wallet/future/state_managment/state_managment.dart';
import 'package:on_chain_wallet/future/widgets/widgets/conditional_widget.dart';
import 'package:on_chain_wallet/future/widgets/widgets/constraints_box_view.dart';
import 'package:on_chain_wallet/future/widgets/widgets/container_with_border.dart';
import 'package:on_chain_wallet/future/widgets/widgets/paste_icon_widget.dart';
import 'package:on_chain_wallet/future/widgets/widgets/widget_constant.dart';
import 'animated/animation.dart';
import 'text_widget.dart';

enum SelectBackupOptions {
  file,
  paste;

  const SelectBackupOptions();
  IconData get icon {
    switch (this) {
      case SelectBackupOptions.paste:
        return Icons.paste;
      case SelectBackupOptions.file:
        return Icons.file_copy;
    }
  }
}

class BackupDataPickerView extends StatefulWidget {
  final PickFileContentEncoding encoding;
  final BackupDataPickerContent? content;
  const BackupDataPickerView(
      {this.encoding = PickFileContentEncoding.utf8, this.content, super.key});

  @override
  State<BackupDataPickerView> createState() => BackupDataPickerViewState();
}

class BackupDataPickerViewState extends State<BackupDataPickerView>
    with SafeState<BackupDataPickerView> {
  BackupDataPickerContent content = BackupDataPickerContent();
  String? get pasteBackup => content.pasteBackup;
  PickedFileContent? get pickedFile => content.pickedFile;
  SelectBackupOptions get tab => content.tab;

  List<int>? getData() {
    switch (tab) {
      case SelectBackupOptions.file:
        return pickedFile?.data;
      default:
        switch (widget.encoding) {
          case PickFileContentEncoding.hex:
            return BytesUtils.tryFromHexString(pasteBackup);
          default:
            return StringUtils.tryEncode(pasteBackup);
        }
    }
  }

  String? getDataString() {
    switch (tab) {
      case SelectBackupOptions.file:
        return StringUtils.tryDecode(pickedFile?.data);
      default:
        return pasteBackup;
    }
  }

  String? validate(Object? _) {
    switch (tab) {
      case SelectBackupOptions.file:
        if (pickedFile == null) return "";
        return null;
      case SelectBackupOptions.paste:
        if (pasteBackup == null) return "";
        return null;
    }
  }

  void onChangeTab(int index) {
    content.tab = SelectBackupOptions.values.elementAt(index);
    updateState();
  }

  void onPasteBackup(String data) {
    if (data.isEmpty) {
      context.showAlert("clipboard_empty".tr);
      return;
    }
    switch (widget.encoding) {
      case PickFileContentEncoding.hex:
        if (!StringUtils.isHexBytes(data.trim())) {
          context.showAlert("bcakup_validator".tr);
          return;
        }
        break;
      default:
    }

    content.pasteBackup = data;
    updateState();
  }

  Future<void> onPasteData() async {
    final data = await context.appContext.platformUtls.readClipboard();
    data.map((txt) {
      if (txt == null || txt.isEmpty) {
        context.showAlert("clipboard_empty".tr);
        return;
      }
      if (!StringUtils.isHexBytes(txt.trim())) {
        context.showAlert("bcakup_validator".tr);
        return;
      }
      content.pasteBackup = txt;
      updateState();
    });
  }

  Future<void> onSelectFile() async {
    final result =
        await context.appContext.platformUtls.pickFile(encoding: widget.encoding);
    result.watch(
      onErr: (error) => context.showAlert(error.localizationError),
      onOk: (data) {
        content.pickedFile = data;
        updateState();
      },
    );
  }

  @override
  void onInitOnce() {
    super.onInitOnce();
    final content = widget.content;
    if (content != null) {
      this.content = content;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField(
        validator: validate,
        enabled: true,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        builder: (s) {
          return Column(children: [
            DefaultTabController(
                length: SelectBackupOptions.values.length,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  FullWidthWrapper(
                    child: TabBar(
                        onTap: onChangeTab,
                        isScrollable: true,
                        indicatorColor: context.colors.transparent,
                        // dividerHeight: 0,
                        tabAlignment: TabAlignment.start,
                        tabs: SelectBackupOptions.values
                            .map((e) => Tab(icon: Icon(e.icon)))
                            .toList()),
                  )
                ])),
            WidgetConstant.height8,
            APPAnimatedSwitcher<SelectBackupOptions>(enable: tab, widgets: {
              SelectBackupOptions.file: (context) => ContainerWithBorder(
                    onRemove: onSelectFile,
                    validate: pickedFile != null,
                    onRemoveIcon: AddOrEditIconWidget(pickedFile != null),
                    child: ConditionalWidget(
                      enable: pickedFile != null,
                      onActive: (context) => Text(pickedFile!.name,
                          style: context.onPrimaryTextTheme.bodyMedium),
                      onDeactive: (context) => Text("tab_to_choose_backup_file".tr,
                          style: context.onPrimaryTextTheme.bodyMedium),
                    ),
                  ),
              SelectBackupOptions.paste: (context) => ContainerWithBorder(
                    onRemove: onPasteData,
                    validate: pasteBackup != null,
                    onRemoveWidget: PasteTextIcon(
                        onPaste: onPasteBackup,
                        isSensitive: false,
                        color: context.onPrimaryContainer),
                    child: ConditionalWidget(
                      enable: pasteBackup != null,
                      onActive: (context) => OneLineTextWidget(pasteBackup!,
                          style: context.onPrimaryTextTheme.bodyMedium, maxLine: 4),
                      onDeactive: (context) => Text("paste_your_backup_here".tr,
                          style: context.onPrimaryTextTheme.bodyMedium),
                    ),
                  ),
            }),
          ]);
        });
  }
}

class BackupDataPickerContent {
  String? pasteBackup;
  PickedFileContent? pickedFile;
  SelectBackupOptions tab = SelectBackupOptions.file;
}
