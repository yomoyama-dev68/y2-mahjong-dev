import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:html' as html;
import 'dart:convert' show json, utf8;

class Images {
  final imageMap = <String, Image>{};
  final uiImageMap = <String, ui.Image>{};
}

Future<Images> loadImages(double scaleForImage) {
  final completer = Completer<Images>();
  _loadImages(completer, scaleForImage);
  return completer.future;
}

/*
Future<Images> loadImages(double scaleForImage) async {
  final zipData = await rootBundle.load("images.zip");
  final archive = ZipDecoder().decodeBytes(zipData.buffer.asUint8List());

  final images = Images();
  final file = archive.first;
  print("${file.name} E");
  final name = file.name
      .split("/")
      .last
      .split(".")
      .first;
  final data = file.content as Uint8List;
  ui.Codec codec = await ui.instantiateImageCodec(data);
  ui.FrameInfo info = await codec.getNextFrame();
  images.imageMap[name] = Image.memory(data, scale: scaleForImage);
  images.uiImageMap[name] = info.image;
  print("${file.name} X");
  return images;
}*/

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

void _loadImages3(Completer<Images> completer, double scaleForImage) async {
  final fileList = [
    "0_0_0.gif",
    "0_0_1.gif",
    "0_0_2.gif",
    "0_0_3.gif",
    "0_0_4.gif",
    "0_1_0.gif",
    "0_1_1.gif",
    "0_1_2.gif",
    "0_1_3.gif",
    "0_1_4.gif",
    "0_2_0.gif",
    "0_2_1.gif",
    "0_2_2.gif",
    "0_2_3.gif",
    "0_2_4.gif",
    "0_3_0.gif",
    "0_3_1.gif",
    "0_3_2.gif",
    "0_3_3.gif",
    "0_3_4.gif",
    "0_4_0.gif",
    "0_4_1.gif",
    "0_4_2.gif",
    "0_4_3.gif",
    "0_4_4.gif",
    "0_5_0.gif",
    "0_5_1.gif",
    "0_5_2.gif",
    "0_5_3.gif",
    "0_5_4.gif",
    "0_6_0.gif",
    "0_6_1.gif",
    "0_6_2.gif",
    "0_6_3.gif",
    "0_6_4.gif",
    "0_7_0.gif",
    "0_7_1.gif",
    "0_7_2.gif",
    "0_7_3.gif",
    "0_7_4.gif",
    "0_8_0.gif",
    "0_8_1.gif",
    "0_8_2.gif",
    "0_8_3.gif",
    "0_8_4.gif",
    "1_0_0.gif",
    "1_0_1.gif",
    "1_0_2.gif",
    "1_0_3.gif",
    "1_0_4.gif",
    "1_1_0.gif",
    "1_1_1.gif",
    "1_1_2.gif",
    "1_1_3.gif",
    "1_1_4.gif",
    "1_2_0.gif",
    "1_2_1.gif",
    "1_2_2.gif",
    "1_2_3.gif",
    "1_2_4.gif",
    "1_3_0.gif",
    "1_3_1.gif",
    "1_3_2.gif",
    "1_3_3.gif",
    "1_3_4.gif",
    "1_4_0.gif",
    "1_4_1.gif",
    "1_4_2.gif",
    "1_4_3.gif",
    "1_4_4.gif",
    "1_5_0.gif",
    "1_5_1.gif",
    "1_5_2.gif",
    "1_5_3.gif",
    "1_5_4.gif",
    "1_6_0.gif",
    "1_6_1.gif",
    "1_6_2.gif",
    "1_6_3.gif",
    "1_6_4.gif",
    "1_7_0.gif",
    "1_7_1.gif",
    "1_7_2.gif",
    "1_7_3.gif",
    "1_7_4.gif",
    "1_8_0.gif",
    "1_8_1.gif",
    "1_8_2.gif",
    "1_8_3.gif",
    "1_8_4.gif",
    "2_0_0.gif",
    "2_0_1.gif",
    "2_0_2.gif",
    "2_0_3.gif",
    "2_0_4.gif",
    "2_1_0.gif",
    "2_1_1.gif",
    "2_1_2.gif",
    "2_1_3.gif",
    "2_1_4.gif",
    "2_2_0.gif",
    "2_2_1.gif",
    "2_2_2.gif",
    "2_2_3.gif",
    "2_2_4.gif",
    "2_3_0.gif",
    "2_3_1.gif",
    "2_3_2.gif",
    "2_3_3.gif",
    "2_3_4.gif",
    "2_4_0.gif",
    "2_4_1.gif",
    "2_4_2.gif",
    "2_4_3.gif",
    "2_4_4.gif",
    "2_5_0.gif",
    "2_5_1.gif",
    "2_5_2.gif",
    "2_5_3.gif",
    "2_5_4.gif",
    "2_6_0.gif",
    "2_6_1.gif",
    "2_6_2.gif",
    "2_6_3.gif",
    "2_6_4.gif",
    "2_7_0.gif",
    "2_7_1.gif",
    "2_7_2.gif",
    "2_7_3.gif",
    "2_7_4.gif",
    "2_8_0.gif",
    "2_8_1.gif",
    "2_8_2.gif",
    "2_8_3.gif",
    "2_8_4.gif",
    "3_0_0.gif",
    "3_0_1.gif",
    "3_0_2.gif",
    "3_0_3.gif",
    "3_0_4.gif",
    "3_1_0.gif",
    "3_1_1.gif",
    "3_1_2.gif",
    "3_1_3.gif",
    "3_1_4.gif",
    "3_2_0.gif",
    "3_2_1.gif",
    "3_2_2.gif",
    "3_2_3.gif",
    "3_2_4.gif",
    "3_3_0.gif",
    "3_3_1.gif",
    "3_3_2.gif",
    "3_3_3.gif",
    "3_3_4.gif",
    "3_4_0.gif",
    "3_4_1.gif",
    "3_4_2.gif",
    "3_4_3.gif",
    "3_4_4.gif",
    "3_5_0.gif",
    "3_5_1.gif",
    "3_5_2.gif",
    "3_5_3.gif",
    "3_5_4.gif",
    "3_6_0.gif",
    "3_6_1.gif",
    "3_6_2.gif",
    "3_6_3.gif",
    "3_6_4.gif",
    "4_0_0.gif",
    "4_0_1.gif",
    "4_0_2.gif",
    "4_0_3.gif",
    "4_0_4.gif",
    "bar_leader_continuous_count_mini.png",
    "bar_riichi_mini.png",
    "riichibar_0.gif",
    "riichibar_1.gif",
    "riichibar_2.gif",
    "riichibar_3.gif",
    "stage_0_0.gif",
    "stage_0_1.gif",
    "stage_0_2.gif",
    "stage_0_3.gif",
    "stage_1_0.gif",
    "stage_1_1.gif",
    "stage_1_2.gif",
    "stage_1_3.gif",
    "stage_2_0.gif",
    "stage_2_1.gif",
    "stage_2_2.gif",
    "stage_2_3.gif",
    "stage_3_0.gif",
    "stage_3_1.gif",
    "stage_3_2.gif",
    "stage_3_3.gif"
  ];

  final images = Images();
  var count = 0;
  for (final fileName in fileList) {
    rootBundle.load("assets/images/${fileName}").then((ByteData data) {
      ui.decodeImageFromList(data.buffer.asUint8List(), (ui.Image uiImg) {
        count++;
        final name = fileName
            .split(".")
            .first;
        images.imageMap[name] =
            Image.memory(data.buffer.asUint8List(), scale: scaleForImage);
        images.uiImageMap[name] = uiImg;
        if (count == fileList.length) {
          completer.complete(images);
        }
      });
    });
  }
}

/*
Future<void> _loadImages10(Completer<Images> completer, double scaleForImage) async {
  final data = await rootBundle.load("assets/images.bin");
  final infoStringByteEndIndex = data.getInt32(0, Endian.little) + 4;
  final infoString = String.fromCharCodes(
      data.buffer.asUint8List(), 4, infoStringByteEndIndex);
  final infoMap = json.decode(infoString) as Map<String, dynamic>;
  print(infoMap);

  var count = 0;
  final images = Images();
  for (final e in infoMap.entries) {
    final indexs = e.value as List;
    final start = (indexs[0] as int) + infoStringByteEndIndex;
    final end = (indexs[1] as int) + infoStringByteEndIndex;
//    final dataBuffer = data.buffer.asUint8List().sublist(start, end);
    final dataBuffer = data.buffer.asUint8List(start, end - start);
    ui.decodeImageFromList(dataBuffer, (ui.Image uiImg) {
      images.imageMap[e.key] = Image.memory(dataBuffer, scale: scaleForImage);
      images.uiImageMap[e.key] = uiImg;
      count++;
      if (count == infoMap.length) {
        completer.complete(images);
      }
    });
  }
}
*/