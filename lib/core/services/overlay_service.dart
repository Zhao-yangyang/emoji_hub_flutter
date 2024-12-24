import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final overlayServiceProvider = Provider((ref) => OverlayService());

class OverlayService {
  OverlayEntry? _overlayEntry;
  bool get isShowing => _overlayEntry != null;

  void show(BuildContext context, Widget child) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => child,
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void toggle(BuildContext context, Widget child) {
    if (isShowing) {
      hide();
    } else {
      show(context, child);
    }
  }
}
