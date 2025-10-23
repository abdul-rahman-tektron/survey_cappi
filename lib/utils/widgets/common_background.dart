import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:srpf/res/images.dart';

class CommonBackground extends StatelessWidget {
  final Widget? child;

  const CommonBackground({
    super.key,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                AppImages.backgroundImagePng,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
        if (child != null) child!,
      ],
    );
  }
}