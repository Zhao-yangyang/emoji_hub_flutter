import 'package:flutter/material.dart' show Offset;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/emoji.dart';

final floatingToolbarVisibleProvider = StateProvider<bool>((ref) => false);

final selectedEmojiProvider = StateProvider<Emoji?>((ref) => null);

final toolbarPositionProvider = StateProvider<Offset>((ref) {
  // 默认位置在右下角
  return const Offset(300, 500);
});
