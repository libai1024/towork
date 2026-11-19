import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:towork/domain/attachments/local_image.dart';

Future<Uint8List> syntheticImage({int width = 320, int height = 160}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawPaint(ui.Paint()..color = const ui.Color(0xffffffff));
  canvas.drawRect(
    const ui.Rect.fromLTWH(10, 10, 100, 40),
    ui.Paint()..color = const ui.Color(0xffb72a30),
  );
  final paragraph =
      (ui.ParagraphBuilder(
          ui.ParagraphStyle(fontSize: 22),
        )..addText('Synthetic invoice 88.50')).build()
        ..layout(ui.ParagraphConstraints(width: width.toDouble()));
  canvas.drawParagraph(paragraph, const ui.Offset(10, 70));
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  try {
    final data = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  } finally {
    image.dispose();
    picture.dispose();
    paragraph.dispose();
  }
}

class FixtureImageSelector implements ImageSelector {
  FixtureImageSelector(this.bytes);
  final Uint8List bytes;
  int calls = 0;
  @override
  Future<SelectedImage?> select() async {
    calls++;
    return SelectedImage('验收发票.png', bytes);
  }
}
