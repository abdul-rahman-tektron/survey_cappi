import 'package:flutter/widgets.dart';

class ScreenSize {
  static late double width;
  static late double height;

  /// Call this once (e.g. in your app's root or builder)
  static void init(BuildContext context) {
    final size = MediaQuery.of(context).size;
    width = size.width;
    height = size.height;
  }
}
