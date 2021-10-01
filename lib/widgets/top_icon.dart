import 'dart:async';
import 'package:flutter/material.dart';

class TopIcon extends StatefulWidget {
  const TopIcon({
    Key? key,
  }) : super(key: key);

  @override
  State<TopIcon> createState() => TopIconState();
}

class TopIconState extends State<TopIcon> with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;

  @override
  initState() {
    super.initState();
    controller = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    controller.repeat(
        reverse: true,
        min: 0.5,
        max: 0.8,
        period: const Duration(milliseconds: 2000));

    animation = controller.drive(CurveTween(
        curve: const Interval(
      0.0,
      0.8,
      curve: Curves.elasticInOut,
    )));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
        scale: animation, // あとはいい感じにやってくれる
        child: Image.asset('assets/top_icon.png'));
  }
}
