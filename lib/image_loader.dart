import 'dart:io';
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
    final name = file.name.split("/").last.split(".").first;
    final data = file.content as Uint8List;
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
