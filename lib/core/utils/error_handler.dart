import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/error_manager.dart';
import '../../ui/widgets/error_dialog.dart';

class ErrorHandler {
  static void showError(BuildContext context, String message,
      [StackTrace? stackTrace]) {
    showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        message: message,
        stackTrace: stackTrace,
      ),
    );
  }

  static void handleError(WidgetRef ref, dynamic error,
      [StackTrace? stackTrace]) {
    ref.read(errorProvider.notifier).setError(
          error.toString(),
          stackTrace,
        );
  }
}
