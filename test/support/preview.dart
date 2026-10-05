import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> loadPreviewFonts() async {
  if (!const bool.fromEnvironment('CAPTURE_PREVIEW')) return;
  for (final (family, asset) in [
    ('Inter', 'assets/fonts/Inter.ttf'),
    ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
  ]) {
    final loader = FontLoader(family)..addFont(rootBundle.load(asset));
    await loader.load();
  }
}

Future<void> capturePreview(
  WidgetTester tester,
  RenderRepaintBoundary boundary,
  String name,
) async {
  if (!const bool.fromEnvironment('CAPTURE_PREVIEW')) return;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/previews/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
