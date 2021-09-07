import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class Images {
  final imageMap = <String, Image>{};
  final uiImageMap = <String, ui.Image>{};
}

/*
Future<Images> loadImages(double scaleForImage) {
  final completer = Completer<Images>();
  _loadImages(completer, scaleForImage);
  return completer.future;
}

void _loadImages(Completer<Images> completer, double scaleForImage) async {
  final data = await rootBundle.load("assets/images.zip");
  final archive = ZipDecoder().decodeBytes(data.buffer.asUint8List());

  final images = Images();
  var count = 0;
  for (final file in archive) {
    final name = file.name
        .split("/")
        .last
        .split(".")
        .first;
    final data = (file.content as Uint8List).sublist(0);
    ui.decodeImageFromList(data, (ui.Image uiImg) {
      count++;
      images.imageMap[name] = Image.memory(data, scale: scaleForImage);
      images.uiImageMap[name] = uiImg;
      if (count == archive.length) {
        completer.complete(images);
      }
    });
  }
}
 */

Future<Images> loadImages(double scaleForImage) async {
  final zipData = await rootBundle.load("assets/images.zip");
  final archive = ZipDecoder().decodeBytes(zipData.buffer.asUint8List());

  final images = Images();
  for (final file in archive) {
    print("${file.name} E");
    final name = file.name.split("/").last.split(".").first;

    // Note:　sublist(0)でデータをクローンしないと、getNextFrameで処理が帰ってこない。
    final data = (file.content as Uint8List).sublist(0);

    ui.Codec codec = await ui.instantiateImageCodec(data);
    ui.FrameInfo info = await codec.getNextFrame();
    images.imageMap[name] = Image.memory(data, scale: scaleForImage);
    images.uiImageMap[name] = info.image;
    print("${file.name} X");
  }
  return images;
}
