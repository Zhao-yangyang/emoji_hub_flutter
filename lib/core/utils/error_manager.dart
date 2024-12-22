import 'package:flutter_riverpod/flutter_riverpod.dart';

class ErrorState {
  final String? message;
  final bool hasError;
  final StackTrace? stackTrace;

  const ErrorState({
    this.message,
    this.hasError = false,
    this.stackTrace,
  });

  ErrorState copyWith({
    String? message,
    bool? hasError,
    StackTrace? stackTrace,
  }) {
    return ErrorState(
      message: message ?? this.message,
      hasError: hasError ?? this.hasError,
      stackTrace: stackTrace ?? this.stackTrace,
    );
  }
}

final errorProvider = StateNotifierProvider<ErrorNotifier, ErrorState>((ref) {
  return ErrorNotifier();
});

class ErrorNotifier extends StateNotifier<ErrorState> {
  ErrorNotifier() : super(const ErrorState());

  void setError(String message, [StackTrace? stackTrace]) {
    state = ErrorState(
      message: message,
      hasError: true,
      stackTrace: stackTrace,
    );
  }

  void clearError() {
    state = const ErrorState();
  }
}
