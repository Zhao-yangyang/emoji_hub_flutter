import 'package:flutter/material.dart';
import 'package:emoji_hub_flutter/ui/floating_window/floating_window_view.dart';

class Routes {
  static const String floatingWindow = '/floating_window';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      floatingWindow: (context) => const FloatingWindowView(),
    };
  }
}
