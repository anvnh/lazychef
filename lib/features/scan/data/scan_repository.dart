import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lazychef/core/api/api_client.dart';
import 'package:lazychef/features/scan/models/scan_upload_result.dart';

final scanRepositoryProvider = Provider<ScanRepository>((ref) {
  return ScanRepository(ref.watch(dioProvider));
});

class ScanRepository {
  ScanRepository(this._dio);

  final Dio _dio;
  final _storage = const FlutterSecureStorage();

  Future<ScanUploadResult> uploadScanImage(XFile image) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        throw const ScanUploadException('Please sign in before scanning.');
      }

      final bytes = await image.readAsBytes();
      final fileName = image.name.isNotEmpty ? image.name : 'scan-image.jpg';
      final contentType = _resolveContentType(image, fileName);
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: DioMediaType.parse(contentType),
        ),
      });

      final response = await _dio.post<Map<String, dynamic>>(
        '/scans/upload',
        data: formData,
        options: Options(
          contentType: Headers.multipartFormDataContentType,
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return ScanUploadResult.fromJson(response.data ?? const {});
    } on ScanUploadException {
      rethrow;
    } on DioException catch (error) {
      throw ScanUploadException(_parseDioError(error));
    } catch (_) {
      throw const ScanUploadException('Could not upload scan image.');
    }
  }

  String _resolveContentType(XFile image, String fileName) {
    if (image.mimeType != null && image.mimeType!.isNotEmpty) {
      return image.mimeType!;
    }

    final lowerName = fileName.toLowerCase();
    if (lowerName.endsWith('.png')) {
      return 'image/png';
    }
    if (lowerName.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lowerName.endsWith('.heic')) {
      return 'image/heic';
    }
    if (lowerName.endsWith('.heif')) {
      return 'image/heif';
    }

    return 'image/jpeg';
  }

  String _parseDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['error'] is String) {
      if (data['error'] == 'Missing bearer token' ||
          data['error'] == 'Invalid bearer token') {
        return 'Please sign in before scanning.';
      }

      return data['error'] as String;
    }

    final statusCode = error.response?.statusCode;
    if (statusCode != null) {
      return 'Could not upload scan image. Server returned $statusCode.';
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Could not reach the backend. Check API_URL and make sure the server is running.';
    }

    return 'Could not upload scan image. ${error.message ?? ''}'.trim();
  }
}

class ScanUploadException implements Exception {
  const ScanUploadException(this.message);

  final String message;

  @override
  String toString() => message;
}
