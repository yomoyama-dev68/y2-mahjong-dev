import 'dart:async';
import 'package:flutter/material.dart';

class VoicedIcon extends StatefulWidget {
  const VoicedIcon({
    required this.peerId,
    required this.streamController,
    this.muted = false,
    this.color = Colors.black,
    Key? key,
  }) : super(key: key);

  final String peerId;
  final StreamController<String> streamController;
  final Color color;
  final bool muted;

  @override
  State<VoicedIcon> createState() => VoicedIconState();
}

class VoicedIconState extends State<VoicedIcon>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late AnimationController controller;
  late Animation<double> animation;
  late StreamSubscription subscription;

  @override
  initState() {
    super.initState();
    controller = AnimationController(
        duration: const Duration(milliseconds: 750), vsync: this);
    animation = controller.drive(CurveTween(
        curve: const Interval(
      0.0,
      1.0,
      curve: Curves.easeOutExpo,
    )));

    subscription = widget.streamController.stream.listen((voicedPeerId) {
      if (voicedPeerId == widget.peerId) {
        controller.reverse(from: 1.0);
      }
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.muted) {
      return Icon(Icons.volume_off, color: widget.color);
    }

    return FadeTransition(
      opacity: animation,
      child: Icon(Icons.volume_up, color: widget.color),
    );
  }
}
