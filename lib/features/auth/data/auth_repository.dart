import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lazychef/core/api/api_client.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});

class AuthRepository {
  final Dio _dio;
  final _storage = const FlutterSecureStorage();

  AuthRepository(this._dio);

  Future<void> login(String email, String password) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    final token = response.data['token'] as String;
    final userEmail = response.data['user']['email'] as String;
    await _storage.write(key: 'jwt_token', value: token);
    await _storage.write(key: 'user_email', value: userEmail);
  }

  Future<void> register(String email, String password) async {
    final response = await _dio.post(
      '/auth/register',
      data: {'email': email, 'password': password},
    );

    final token = response.data['token'] as String;
    final userEmail = response.data['user']['email'] as String;
    await _storage.write(key: 'jwt_token', value: token);
    await _storage.write(key: 'user_email', value: userEmail);
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_email');
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'jwt_token');
    return token != null && token.isNotEmpty;
  }

  Future<String?> getUserEmail() async {
    return await _storage.read(key: 'user_email');
  }
}
