import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lazychef/features/auth/data/auth_repository.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(() {
  return AuthController();
});

class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Initial state is nothing
  }

  String _parseError(DioException e, String defaultMessage) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      String errorMessage = data['error'] ?? defaultMessage;
      if (data['fields'] is Map<String, dynamic>) {
        final fields = data['fields'] as Map<String, dynamic>;
        final fieldMessages = fields.entries.map((entry) {
          final values = entry.value as List<dynamic>;
          return '${entry.key}: ${values.join(', ')}';
        }).join('\n');
        errorMessage = '$errorMessage\n$fieldMessages';
      }
      return errorMessage;
    }
    return defaultMessage;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.login(email, password);
      state = const AsyncData(null);
    } catch (e, st) {
      if (e is DioException) {
        state = AsyncError(_parseError(e, 'Login failed'), st);
      } else {
        state = AsyncError('Login failed', st);
      }
    }
  }

  Future<void> register(String email, String password) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.register(email, password);
      state = const AsyncData(null);
    } catch (e, st) {
      if (e is DioException) {
        state = AsyncError(_parseError(e, 'Registration failed'), st);
      } else {
        state = AsyncError('Registration failed', st);
      }
    }
  }
}
