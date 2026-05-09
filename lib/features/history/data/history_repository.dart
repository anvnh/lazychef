import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lazychef/core/api/api_client.dart';
import 'package:lazychef/features/history/models/history_scan.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository(ref.watch(dioProvider));
});

class HistoryRepository {
  const HistoryRepository(this._dio);

  final Dio _dio;

  Future<List<HistoryScan>> fetchScanHistory() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/scans/history');
      final history = response.data?['history'];

      if (history is! List) {
        return const [];
      }

      return history
          .whereType<Map>()
          .map((scan) => Map<String, dynamic>.from(scan))
          .map(HistoryScan.fromJson)
          .toList();
    } on DioException catch (error) {
      throw HistoryException(_parseDioError(error));
    } catch (_) {
      throw const HistoryException('Could not load scan history.');
    }
  }

  String _parseDioError(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['error'] is String) {
      if (data['error'] == 'Missing bearer token' ||
          data['error'] == 'Invalid bearer token') {
        return 'Please sign in to view your scan history.';
      }

      return data['error'] as String;
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Could not reach the backend. Check API_URL and make sure the server is running.';
    }

    return 'Could not load scan history.';
  }
}

class HistoryException implements Exception {
  const HistoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
