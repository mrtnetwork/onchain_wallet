import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart' as material;
import 'package:on_chain_bridge/models/models.dart';
import 'package:on_chain_wallet/app/core.dart';
import 'package:on_chain_wallet/context/core/context.dart';
import 'package:on_chain_wallet/future/widgets/widgets/barcode/qr_code/qr_view.dart';

class QrUtils {
  static Future<List<int>?> qrCodeTobytes(
      {required String data,
      required String uderImage,
      required material.ColorScheme color}) async {
    try {
      final ui.Image image = await QrPainter(
        data: data,
        version: QrVersions.auto,
        eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: color.onSurface),
        dataModuleStyle: QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square, color: color.onSurface),
      ).toImage(500);
      final ByteData? bufferBytes = await _QrCodeMarkerPainter(
              qrImage: image,
              margin: 10,
              imageSize: 500,
              data: uderImage,
              textColor: color.onSurface,
              backgroundColor: color.surface)
          .toImageData();
      if (bufferBytes == null) return null;

      return bufferBytes.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  static Future<IResult<IBuffer?>> qrCodeToBytes(
      {required String data,
      required String uderImage,
      required AppContext context,
      required material.ColorScheme color}) async {
    final List<int>? bufferData =
        await qrCodeTobytes(data: data, uderImage: uderImage, color: color);
    if (bufferData == null) return ResultOk(null);
    return ResultOk(IBuffer.binary(bufferData));
  }
}

class _QrCodeMarkerPainter extends material.CustomPainter {
  final material.Color textColor;
  final double margin;
  final ui.Image qrImage;
  final material.Color backgroundColor;
  late final material.Paint _paint = material.Paint()
    ..color = backgroundColor
    ..style = ui.PaintingStyle.fill;
  final double imageSize;
  final String data;

  _QrCodeMarkerPainter(
      {required this.qrImage,
      this.margin = 10,
      required this.imageSize,
      required this.data,
      required this.textColor,
      required this.backgroundColor});

  @override
  void paint(material.Canvas canvas, material.Size size) {
    const borderRadius = material.Radius.circular(12);
    final rect = material.RRect.fromRectAndRadius(
        material.Rect.fromPoints(
            material.Offset.zero, material.Offset(size.width, size.height)),
        borderRadius);
    canvas.drawRRect(rect, _paint);
    canvas.drawImage(qrImage, material.Offset(margin * 2, margin), _paint);
    final ui.ParagraphBuilder paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: material.TextAlign.justify,
      fontSize: 14,
    ))
      ..pushStyle(ui.TextStyle(color: textColor, fontSize: 14))
      ..addText(LinkConst.appGithub);
    final ui.Paragraph paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: size.width - 12.0 - 12.0));
    canvas.drawParagraph(paragraph, material.Offset(25, (imageSize + 10)));
  }

  @override
  bool shouldRepaint(covariant material.CustomPainter oldDelegate) => false;

  ui.Picture toPicture(double size) {
    final recorder = ui.PictureRecorder();
    final canvas = material.Canvas(recorder);
    paint(canvas, material.Size(size, size));
    return recorder.endRecording();
  }

  Future<ui.Image> toImage(double size,
      {ui.ImageByteFormat format = ui.ImageByteFormat.png}) async {
    return await toPicture(size).toImage(size.toInt(), size.toInt());
  }

  Future<ByteData?> toImageData() async {
    final image = await toImage(imageSize + margin * 4, format: ui.ImageByteFormat.png);
    return image.toByteData(format: ui.ImageByteFormat.png);
  }
}
