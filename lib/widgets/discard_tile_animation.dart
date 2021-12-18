import 'dart:async';
import 'package:flutter/material.dart';

class DiscardTileAnimation extends StatefulWidget {
  const DiscardTileAnimation({
    Key? key,
    required this.image,
    required this.listener
  }) : super(key: key);

  final Image image;
  final Function(AnimationStatus) listener;

  @override
  State<DiscardTileAnimation> createState() => DiscardTileAnimationState();
}

class DiscardTileAnimationState extends State<DiscardTileAnimation> with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;

  @override
  initState() {
    print("DiscardTileAnimationState:initState");
    super.initState();
    controller = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);
    animation = controller.drive(CurveTween(
        curve: const Interval(
          0.0,
          1.0,
          curve: Curves.easeOutExpo,
        )));
    controller.addStatusListener(widget.listener);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("DiscardTileAnimationState:build");
    controller.reverse(from: 1.0);
    return FadeTransition(
      opacity: animation,
      child: widget.image,
    );
  }
}